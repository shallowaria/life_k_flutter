import 'dart:math';

import '../models/k_line_point.dart';

/// Interpolation service that generates daily K-line data from yearly anchor points
/// using natural cubic spline interpolation with deterministic pseudo-random OHLC.
class KLineInterpolationService {
  KLineInterpolationService._();

  /// Generate daily [KLinePoint]s for the date range [start] to [end] (inclusive),
  /// interpolated from yearly [anchorPoints].
  ///
  /// Each anchor point is placed at July 1st of its year for spline fitting.
  static List<KLinePoint> interpolate({
    required List<KLinePoint> anchorPoints,
    required DateTime start,
    required DateTime end,
    double volatility = 0.3,
  }) {
    if (anchorPoints.isEmpty) return [];

    // Build spline from anchor scores (one per year, anchored at July 1)
    final xs = <double>[];
    final ys = <double>[];
    for (final p in anchorPoints) {
      xs.add(_dateToDouble(DateTime(p.year, 7, 1)));
      ys.add(p.score);
    }

    final spline = _NaturalCubicSpline(xs, ys);

    // First/last anchor year boundaries for extrapolation detection
    final firstAnchorDate = _dateToDouble(
      DateTime(anchorPoints.first.year, 1, 1),
    );
    final lastAnchorDate = _dateToDouble(
      DateTime(anchorPoints.last.year, 12, 31),
    );

    // Build year-keyed lookup for fast anchor access
    final anchorByYear = {for (final a in anchorPoints) a.year: a};

    final results = <KLinePoint>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDay)) {
      final t = _dateToDouble(current);

      // Base score from spline (or linear extrapolation at boundaries)
      double baseScore;
      if (t < xs.first) {
        // Linear extrapolation before first anchor
        final slope = xs.length > 1 ? (ys[1] - ys[0]) / (xs[1] - xs[0]) : 0.0;
        baseScore = ys.first + slope * (t - xs.first);
      } else if (t > xs.last) {
        // Linear extrapolation after last anchor
        final n = xs.length;
        final slope = n > 1
            ? (ys[n - 1] - ys[n - 2]) / (xs[n - 1] - xs[n - 2])
            : 0.0;
        baseScore = ys.last + slope * (t - xs.last);
      } else {
        baseScore = spline.evaluate(t);
      }
      baseScore = baseScore.clamp(0.0, 10.0);

      // Deterministic hash-based pseudo-random values
      final hash = current.year * 10000 + current.month * 100 + current.day;
      final r1 = _knuthHash(hash, 1);
      final r2 = _knuthHash(hash, 2);
      final r3 = _knuthHash(hash, 3);
      final r4 = _knuthHash(hash, 4);

      final open = (baseScore + (r1 - 0.5) * volatility).clamp(0.0, 10.0);
      final close = (baseScore + (r2 - 0.5) * volatility).clamp(0.0, 10.0);
      final high = (max(open, close) + r3 * volatility * 0.5).clamp(0.0, 10.0);
      final low = (min(open, close) - r4 * volatility * 0.5).clamp(0.0, 10.0);

      // Find the enclosing anchor to derive age
      final anchorAge = _interpolateAge(anchorPoints, current);

      // Date label
      final dateLabel = '${current.month}/${current.day}';

      // Determine if this date is outside the anchor range
      final isExtrapolated = t < firstAnchorDate || t > lastAnchorDate;

      // Inherit metadata from the nearest annual anchor
      final anchor =
          anchorByYear[current.year] ??
          anchorPoints.reduce(
            (a, b) =>
                (current.year - a.year).abs() <= (current.year - b.year).abs()
                ? a
                : b,
          );

      results.add(
        KLinePoint(
          age: anchorAge,
          year: current.year,
          ganZhi: dateLabel,
          daYun: anchor.daYun,
          open: double.parse(open.toStringAsFixed(2)),
          close: double.parse(close.toStringAsFixed(2)),
          high: double.parse(high.toStringAsFixed(2)),
          low: double.parse(low.toStringAsFixed(2)),
          score: double.parse(baseScore.toStringAsFixed(2)),
          reason: isExtrapolated ? '线性外推插值' : anchor.reason,
          tenGod: anchor.tenGod,
          energyScore: null,
          actionAdvice: anchor.actionAdvice,
        ),
      );

      current = current.add(const Duration(days: 1));
    }

    return results;
  }

  /// Convert a [DateTime] to a double (days since epoch) for spline input.
  static double _dateToDouble(DateTime d) {
    return d.millisecondsSinceEpoch / (1000.0 * 60 * 60 * 24);
  }

  /// Deterministic pseudo-random value in [0, 1) using Knuth multiplicative hash.
  static double _knuthHash(int dateHash, int salt) {
    final combined = dateHash * 2654435761 + salt * 1013904223;
    // Mask to 32 bits to avoid overflow issues
    final masked = combined & 0x7FFFFFFF;
    return (masked % 10000) / 10000.0;
  }

  /// Interpolate age for a given date from anchor points.
  static int _interpolateAge(List<KLinePoint> anchors, DateTime date) {
    // Find the anchor whose year matches or is closest
    for (final a in anchors) {
      if (a.year == date.year) return a.age;
    }
    // Estimate from first anchor
    final first = anchors.first;
    return first.age + (date.year - first.year);
  }
}

/// Natural cubic spline implementation.
///
/// Given n data points (x0,y0)...(xn-1,yn-1), computes and evaluates
/// the natural cubic spline with S''(x0) = S''(xn-1) = 0.
class _NaturalCubicSpline {
  final List<double> _xs;
  final List<double> _ys;
  late final List<double> _a;
  late final List<double> _b;
  late final List<double> _c;
  late final List<double> _d;

  _NaturalCubicSpline(this._xs, this._ys) {
    _compute();
  }

  void _compute() {
    final n = _xs.length;
    if (n < 2) {
      _a = List.from(_ys);
      _b = [0.0];
      _c = [0.0];
      _d = [0.0];
      return;
    }

    _a = List.from(_ys);
    final h = List<double>.generate(n - 1, (i) => _xs[i + 1] - _xs[i]);

    // Solve for c using tridiagonal system (natural boundary: c[0]=c[n-1]=0)
    final alpha = List<double>.filled(n, 0.0);
    for (var i = 1; i < n - 1; i++) {
      alpha[i] =
          3.0 / h[i] * (_a[i + 1] - _a[i]) -
          3.0 / h[i - 1] * (_a[i] - _a[i - 1]);
    }

    final l = List<double>.filled(n, 1.0);
    final mu = List<double>.filled(n, 0.0);
    final z = List<double>.filled(n, 0.0);

    for (var i = 1; i < n - 1; i++) {
      l[i] = 2.0 * (_xs[i + 1] - _xs[i - 1]) - h[i - 1] * mu[i - 1];
      mu[i] = h[i] / l[i];
      z[i] = (alpha[i] - h[i - 1] * z[i - 1]) / l[i];
    }

    _c = List<double>.filled(n, 0.0);
    _b = List<double>.filled(n - 1, 0.0);
    _d = List<double>.filled(n - 1, 0.0);

    for (var j = n - 2; j >= 0; j--) {
      _c[j] = z[j] - mu[j] * _c[j + 1];
      _b[j] =
          (_a[j + 1] - _a[j]) / h[j] - h[j] * (_c[j + 1] + 2.0 * _c[j]) / 3.0;
      _d[j] = (_c[j + 1] - _c[j]) / (3.0 * h[j]);
    }
  }

  /// Evaluate spline at [x]. Clamps to the data range.
  double evaluate(double x) {
    final n = _xs.length;
    if (n == 1) return _ys[0];

    // Clamp to range
    if (x <= _xs[0]) return _ys[0];
    if (x >= _xs[n - 1]) return _ys[n - 1];

    // Find the interval
    var i = 0;
    for (var j = 0; j < n - 1; j++) {
      if (x >= _xs[j] && x <= _xs[j + 1]) {
        i = j;
        break;
      }
    }

    final dx = x - _xs[i];
    return _a[i] + _b[i] * dx + _c[i] * dx * dx + _d[i] * dx * dx * dx;
  }
}
