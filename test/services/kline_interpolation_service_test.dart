import 'package:flutter_test/flutter_test.dart';
import 'package:life_k/models/k_line_point.dart';
import 'package:life_k/services/kline_interpolation_service.dart';

KLinePoint _anchor({required int year, required double score, int age = 1}) {
  return KLinePoint(
    age: age,
    year: year,
    ganZhi: '甲子',
    open: score,
    close: score,
    high: score,
    low: score,
    score: score,
    reason: 'test',
  );
}

void main() {
  group('KLineInterpolationService.interpolate', () {
    test('returns empty list for empty anchor points', () {
      final result = KLineInterpolationService.interpolate(
        anchorPoints: [],
        start: DateTime(2020, 1, 1),
        end: DateTime(2020, 12, 31),
      );
      expect(result, isEmpty);
    });

    test('output count matches date range (inclusive)', () {
      final anchors = [
        _anchor(year: 2020, score: 5.0, age: 1),
        _anchor(year: 2021, score: 7.0, age: 2),
      ];
      final start = DateTime(2020, 6, 1);
      final end = DateTime(2020, 6, 10);
      final result = KLineInterpolationService.interpolate(
        anchorPoints: anchors,
        start: start,
        end: end,
      );
      expect(result.length, equals(10));
    });

    test('OHLC constraint: high >= max(open, close)', () {
      final anchors = [
        _anchor(year: 2020, score: 3.0, age: 1),
        _anchor(year: 2021, score: 8.0, age: 2),
        _anchor(year: 2022, score: 5.0, age: 3),
      ];
      final result = KLineInterpolationService.interpolate(
        anchorPoints: anchors,
        start: DateTime(2020, 1, 1),
        end: DateTime(2021, 12, 31),
      );
      for (final p in result) {
        final maxOC = p.open > p.close ? p.open : p.close;
        expect(
          p.high,
          greaterThanOrEqualTo(maxOC - 0.01),
          reason:
              'high=${p.high} must >= max(open=${p.open}, close=${p.close})',
        );
      }
    });

    test('OHLC constraint: low <= min(open, close)', () {
      final anchors = [
        _anchor(year: 2020, score: 3.0, age: 1),
        _anchor(year: 2021, score: 8.0, age: 2),
        _anchor(year: 2022, score: 5.0, age: 3),
      ];
      final result = KLineInterpolationService.interpolate(
        anchorPoints: anchors,
        start: DateTime(2020, 1, 1),
        end: DateTime(2021, 12, 31),
      );
      for (final p in result) {
        final minOC = p.open < p.close ? p.open : p.close;
        expect(
          p.low,
          lessThanOrEqualTo(minOC + 0.01),
          reason: 'low=${p.low} must <= min(open=${p.open}, close=${p.close})',
        );
      }
    });

    test('all score values are within [0, 10]', () {
      final anchors = [
        _anchor(year: 2020, score: 1.0, age: 1),
        _anchor(year: 2025, score: 9.0, age: 6),
      ];
      final result = KLineInterpolationService.interpolate(
        anchorPoints: anchors,
        start: DateTime(2020, 1, 1),
        end: DateTime(2025, 12, 31),
      );
      for (final p in result) {
        expect(p.score, greaterThanOrEqualTo(0.0));
        expect(p.score, lessThanOrEqualTo(10.0));
        expect(p.open, greaterThanOrEqualTo(0.0));
        expect(p.open, lessThanOrEqualTo(10.0));
        expect(p.close, greaterThanOrEqualTo(0.0));
        expect(p.close, lessThanOrEqualTo(10.0));
      }
    });

    test('is deterministic: same inputs produce identical outputs', () {
      final anchors = [
        _anchor(year: 2020, score: 4.0, age: 1),
        _anchor(year: 2021, score: 7.0, age: 2),
      ];
      final start = DateTime(2020, 3, 1);
      final end = DateTime(2020, 3, 31);

      final result1 = KLineInterpolationService.interpolate(
        anchorPoints: anchors,
        start: start,
        end: end,
      );
      final result2 = KLineInterpolationService.interpolate(
        anchorPoints: anchors,
        start: start,
        end: end,
      );

      expect(result1.length, equals(result2.length));
      for (var i = 0; i < result1.length; i++) {
        expect(result1[i].open, equals(result2[i].open));
        expect(result1[i].close, equals(result2[i].close));
        expect(result1[i].high, equals(result2[i].high));
        expect(result1[i].low, equals(result2[i].low));
        expect(result1[i].score, equals(result2[i].score));
      }
    });

    test('single anchor point returns points for the range', () {
      final anchors = [_anchor(year: 2020, score: 5.0, age: 1)];
      final result = KLineInterpolationService.interpolate(
        anchorPoints: anchors,
        start: DateTime(2020, 1, 1),
        end: DateTime(2020, 1, 7),
      );
      expect(result.length, equals(7));
    });

    test('inherits daYun from anchor', () {
      final anchor = KLinePoint(
        age: 5,
        year: 2020,
        ganZhi: '甲子',
        daYun: '甲戌大运',
        open: 6.0,
        close: 6.0,
        high: 7.0,
        low: 5.0,
        score: 6.0,
        reason: 'test',
      );
      final result = KLineInterpolationService.interpolate(
        anchorPoints: [anchor],
        start: DateTime(2020, 6, 1),
        end: DateTime(2020, 6, 3),
      );
      for (final p in result) {
        expect(p.daYun, equals('甲戌大运'));
      }
    });
  });
}
