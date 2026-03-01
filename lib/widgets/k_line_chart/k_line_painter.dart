import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/k_line_point.dart';
import '../../models/analysis_data.dart';
import '../k_line_chart/chart_view_mode.dart';

/// CustomPainter that draws the life K-line candlestick chart
class KLinePainter extends CustomPainter {
  final List<KLinePoint> data;
  final List<SupportPressureLevel> supportPressureLevels;
  final int? selectedIndex;
  final double scrollOffset;
  final double candleWidth;
  final ChartViewMode viewMode;

  /// Indices (into [data]) of the originally AI-generated key years.
  /// When non-null, only these indices receive 启/变 stamps.
  final Set<int>? keyYearIndices;

  // Colors - Chinese painting aesthetic
  static const Color cinnabarRed = Color(0xFFB22D1B); // 朱砂红 - up/吉
  static const Color cinnabarStroke = Color(0xFF8B1810);
  static const Color indigo = Color(0xFF2F4F4F); // 靛青 - down/凶
  static const Color indigoStroke = Color(0xFF1F3A3A);
  static const Color ma10Color = Color(0xFF479977);
  static const Color supportLineColor = Color(0xFF2F4F4F);
  static const Color pressureLineColor = Color(0xFFB22D1B);
  static const Color goldColor = Color(0xFFC5A367);

  KLinePainter({
    required this.data,
    this.supportPressureLevels = const [],
    this.selectedIndex,
    this.scrollOffset = 0,
    this.candleWidth = 20,
    this.viewMode = ChartViewMode.year,
    this.keyYearIndices,
  });

  // Chart layout constants
  static const double paddingTop = 40;
  static const double paddingBottom = 30;
  static const double paddingLeft = 40;
  static const double paddingRight = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartRect = Rect.fromLTRB(
      paddingLeft,
      paddingTop,
      size.width - paddingRight,
      size.height - paddingBottom,
    );

    // Calculate Y-axis range
    final allValues = data.expand((d) => [d.low, d.high]).toList();
    final dataMin = allValues.reduce(min).toDouble();
    final dataMax = allValues.reduce(max).toDouble();

    double yMin;
    double yMax;
    if (viewMode == ChartViewMode.year) {
      final padding = max((dataMax - dataMin) * 0.15, 2.0);
      yMin = max(0.0, dataMin - padding);
      yMax = min(100.0, dataMax + padding);
    } else {
      // Dynamic Y-axis for month/day views
      final padding = (dataMax - dataMin) * 0.15;
      yMin = (dataMin - padding).clamp(0.0, 10.0);
      yMax = (dataMax + padding).clamp(0.0, 10.0);
      // Ensure minimum range
      if (yMax - yMin < 0.5) {
        yMin = (yMin - 0.25).clamp(0.0, 10.0);
        yMax = (yMax + 0.25).clamp(0.0, 10.0);
      }
    }

    double mapY(double value) {
      return chartRect.bottom -
          ((value - yMin) / (yMax - yMin)) * chartRect.height;
    }

    double mapX(int index) {
      return chartRect.left +
          (index + 0.5) * (chartRect.width / data.length) -
          scrollOffset;
    }

    final cWidth = (chartRect.width / data.length) * 0.6;

    // Draw axes
    _drawAxes(canvas, size, chartRect, yMin, yMax);

    // Draw support/pressure reference lines
    _drawSupportPressureLines(canvas, chartRect, mapY, dataMin, dataMax);

    // Draw Da Yun change lines (year view only)
    if (viewMode == ChartViewMode.year) {
      _drawDaYunLines(canvas, chartRect, mapX);
    }

    // Draw current year/today line
    _drawCurrentMarkerLine(canvas, chartRect, mapX, mapY);

    // Draw moving average line
    _drawMovingAverageLine(canvas, chartRect, mapX, mapY);

    // Draw candles
    _drawCandles(canvas, chartRect, mapX, mapY, cWidth);

    // Draw peak seal stamp
    _drawPeakSeal(canvas, chartRect, mapX, mapY, cWidth);

    // Draw action advice stamps (year view only)
    if (viewMode == ChartViewMode.year) {
      _drawActionAdviceStamps(canvas, mapX, mapY, cWidth);
    }

    // Draw legend
    _drawLegend(canvas, size);
  }

  void _drawAxes(
    Canvas canvas,
    Size size,
    Rect chartRect,
    double yMin,
    double yMax,
  ) {
    final axisPaint = Paint()
      ..color = const Color(0xFFD1CDC2)
      ..strokeWidth = 1;

    // X-axis
    canvas.drawLine(
      Offset(chartRect.left, chartRect.bottom),
      Offset(chartRect.right, chartRect.bottom),
      axisPaint,
    );

    // Y-axis ticks
    final yTickPaint = Paint()
      ..color = const Color(0xFFE5E1D8)
      ..strokeWidth = 0.5;

    for (var i = 0; i <= 5; i++) {
      final value = yMin + (yMax - yMin) * i / 5;
      final y = chartRect.bottom - (i / 5) * chartRect.height;

      // Dashed grid line
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        yTickPaint,
      );

      // Label — use 1 decimal place for month/day views
      final labelText = viewMode == ChartViewMode.year
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
      final textSpan = TextSpan(
        text: labelText,
        style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(
        canvas,
        Offset(chartRect.left - tp.width - 4, y - tp.height / 2),
      );
    }

    // X-axis labels
    if (viewMode == ChartViewMode.year) {
      _drawYearXLabels(canvas, chartRect);
    } else {
      _drawDateXLabels(canvas, chartRect);
    }

    // Y-axis label
    final yLabel = TextPainter(
      text: const TextSpan(
        text: '运势分',
        style: TextStyle(fontSize: 9, color: Color(0xFF9CA3AF)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(
      8,
      chartRect.top + chartRect.height / 2 + yLabel.width / 2,
    );
    canvas.rotate(-pi / 2);
    yLabel.paint(canvas, Offset.zero);
    canvas.restore();

    // X-axis label
    final xLabelText = viewMode == ChartViewMode.year ? '年龄' : '日期';
    final xLabel = TextPainter(
      text: TextSpan(
        text: xLabelText,
        style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    xLabel.paint(
      canvas,
      Offset(chartRect.right - xLabel.width, chartRect.bottom + 20),
    );
  }

  void _drawYearXLabels(Canvas canvas, Rect chartRect) {
    for (var i = 0; i < data.length; i++) {
      if (i % 5 == 0 || i == data.length - 1) {
        final x =
            chartRect.left +
            (i + 0.5) * (chartRect.width / data.length) -
            scrollOffset;
        if (x < chartRect.left || x > chartRect.right) continue;

        final textSpan = TextSpan(
          text: '${data[i].age}',
          style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
        );
        final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
          ..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, chartRect.bottom + 4));
      }
    }
  }

  void _drawDateXLabels(Canvas canvas, Rect chartRect) {
    // Determine label frequency based on view mode
    final labelInterval = viewMode == ChartViewMode.day ? 1 : 7;
    for (var i = 0; i < data.length; i++) {
      if (i % labelInterval == 0 || i == data.length - 1) {
        final x =
            chartRect.left +
            (i + 0.5) * (chartRect.width / data.length) -
            scrollOffset;
        if (x < chartRect.left || x > chartRect.right) continue;

        // ganZhi stores the date string (M/D) for interpolated points
        final textSpan = TextSpan(
          text: data[i].ganZhi,
          style: const TextStyle(fontSize: 8, color: Color(0xFF6B7280)),
        );
        final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
          ..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, chartRect.bottom + 4));
      }
    }
  }

  void _drawSupportPressureLines(
    Canvas canvas,
    Rect chartRect,
    double Function(double) mapY,
    double dataMin,
    double dataMax,
  ) {
    final range = dataMax - dataMin;
    if (range <= 0) return;

    // Global support line S
    final supportValue = max(0.0, dataMin + range * 0.08);
    final supportY = mapY(supportValue);
    if (supportY >= chartRect.top && supportY <= chartRect.bottom) {
      _drawDashedLine(
        canvas,
        Offset(chartRect.left, supportY),
        Offset(chartRect.right, supportY),
        Paint()
          ..color = supportLineColor.withValues(alpha: 0.6)
          ..strokeWidth = 2,
        5,
        5,
      );
      // S label
      final sLabel = TextPainter(
        text: const TextSpan(
          text: 'S',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: supportLineColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      sLabel.paint(
        canvas,
        Offset(chartRect.left + 4, supportY - sLabel.height - 2),
      );
    }

    // Global pressure line R
    final pressureValue = dataMax - range * 0.1;
    final pressureY = mapY(pressureValue);
    if (pressureY >= chartRect.top && pressureY <= chartRect.bottom) {
      _drawDashedLine(
        canvas,
        Offset(chartRect.left, pressureY),
        Offset(chartRect.right, pressureY),
        Paint()
          ..color = pressureLineColor.withValues(alpha: 0.6)
          ..strokeWidth = 2,
        5,
        5,
      );
      // R label
      final rLabel = TextPainter(
        text: const TextSpan(
          text: 'R',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: pressureLineColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      rLabel.paint(
        canvas,
        Offset(
          chartRect.right - rLabel.width - 4,
          pressureY - rLabel.height - 2,
        ),
      );
    }
  }

  void _drawDaYunLines(
    Canvas canvas,
    Rect chartRect,
    double Function(int) mapX,
  ) {
    String? lastDaYun;
    for (var i = 0; i < data.length; i++) {
      if (data[i].daYun != lastDaYun) {
        lastDaYun = data[i].daYun;
        final x = mapX(i);
        if (x < chartRect.left || x > chartRect.right) continue;

        _drawDashedLine(
          canvas,
          Offset(x, chartRect.top),
          Offset(x, chartRect.bottom),
          Paint()
            ..color = const Color(0xFFCBD5E1)
            ..strokeWidth = 1,
          3,
          3,
        );

        // Da Yun label
        if (data[i].daYun != null) {
          final tp = TextPainter(
            text: TextSpan(
              text: data[i].daYun!,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(
            canvas,
            Offset(x - tp.width / 2, chartRect.top - tp.height - 2),
          );
        }
      }
    }
  }

  void _drawCurrentMarkerLine(
    Canvas canvas,
    Rect chartRect,
    double Function(int) mapX,
    double Function(double) mapY,
  ) {
    if (viewMode == ChartViewMode.year) {
      _drawCurrentYearLine(canvas, chartRect, mapX, mapY);
    } else {
      _drawTodayLine(canvas, chartRect, mapX, mapY);
    }
  }

  void _drawCurrentYearLine(
    Canvas canvas,
    Rect chartRect,
    double Function(int) mapX,
    double Function(double) mapY,
  ) {
    final currentYear = DateTime.now().year;
    final idx = data.indexWhere((d) => d.year == currentYear);
    if (idx < 0) return;

    final x = mapX(idx);
    if (x < chartRect.left || x > chartRect.right) return;

    _drawDashedLine(
      canvas,
      Offset(x, chartRect.top),
      Offset(x, chartRect.bottom),
      Paint()
        ..color = const Color(0xFFFFA500).withValues(alpha: 0.7)
        ..strokeWidth = 2,
      5,
      5,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '今年 $currentYear',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFA500),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelY = chartRect.bottom - tp.height - 4;
    final bgRect = RRect.fromLTRBR(
      x - tp.width / 2 - 3,
      labelY - 2,
      x + tp.width / 2 + 3,
      labelY + tp.height + 2,
      const Radius.circular(2),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = const Color(0xFFFFA500).withValues(alpha: 0.20),
    );
    tp.paint(canvas, Offset(x - tp.width / 2, labelY));
  }

  void _drawTodayLine(
    Canvas canvas,
    Rect chartRect,
    double Function(int) mapX,
    double Function(double) mapY,
  ) {
    final now = DateTime.now();
    final todayLabel = '${now.month}/${now.day}';
    // Find index of today's date in the interpolated data
    final idx = data.indexWhere(
      (d) => d.ganZhi == todayLabel && d.year == now.year,
    );
    if (idx < 0) return;

    final x = mapX(idx);
    if (x < chartRect.left || x > chartRect.right) return;

    _drawDashedLine(
      canvas,
      Offset(x, chartRect.top),
      Offset(x, chartRect.bottom),
      Paint()
        ..color = const Color(0xFFFFA500).withValues(alpha: 0.7)
        ..strokeWidth = 2,
      5,
      5,
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: '今日',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFA500),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelY = chartRect.bottom - tp.height - 4;
    final bgRect = RRect.fromLTRBR(
      x - tp.width / 2 - 3,
      labelY - 2,
      x + tp.width / 2 + 3,
      labelY + tp.height + 2,
      const Radius.circular(2),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = const Color(0xFFFFA500).withValues(alpha: 0.20),
    );
    tp.paint(canvas, Offset(x - tp.width / 2, labelY));
  }

  void _drawMovingAverageLine(
    Canvas canvas,
    Rect chartRect,
    double Function(int) mapX,
    double Function(double) mapY,
  ) {
    if (data.length < 2) return;

    // Use MA5 for day view (fewer data points), MA10 for others
    final window = viewMode == ChartViewMode.day ? 5 : 10;

    final maValues = List<double>.generate(data.length, (i) {
      final start = max(0, i - (window - 1));
      final slice = data.sublist(start, i + 1);
      return slice.map((d) => d.close).reduce((a, b) => a + b) / slice.length;
    });

    final path = Path();
    for (var i = 0; i < maValues.length; i++) {
      final x = mapX(i);
      final y = mapY(maValues[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Smooth curve
        final prevX = mapX(i - 1);
        final prevY = mapY(maValues[i - 1]);
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = ma10Color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawCandles(
    Canvas canvas,
    Rect chartRect,
    double Function(int) mapX,
    double Function(double) mapY,
    double cWidth,
  ) {
    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final x = mapX(i);

      // 超出绘图区就跳过
      if (x - cWidth / 2 > chartRect.right || x + cWidth / 2 < chartRect.left) {
        continue;
      }

      final isUp = d.close >= d.open;
      final bodyColor = isUp ? cinnabarRed : indigo;
      final strokeColor = isUp ? cinnabarStroke : indigoStroke;

      final openY = mapY(d.open);
      final closeY = mapY(d.close);
      final bodyTop = min(openY, closeY);
      final bodyBottom = max(
        openY,
        closeY,
      ).clamp(bodyTop + 2.0, double.infinity);

      // 绘制上下影线（所有视图）
      final highY = mapY(d.high);
      final lowY = mapY(d.low);
      canvas.drawLine(
        Offset(x, highY),
        Offset(x, lowY),
        Paint()
          ..color = strokeColor.withValues(alpha: 0.8)
          ..strokeWidth = 1.5,
      );

      // 绘制矩形蜡烛柱体
      final bodyRect = Rect.fromLTRB(
        x - cWidth / 2,
        bodyTop,
        x + cWidth / 2,
        bodyBottom,
      );
      canvas.drawRect(
        bodyRect,
        Paint()
          ..color = bodyColor.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        bodyRect,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      // 高亮选中的蜡烛
      if (selectedIndex == i) {
        canvas.drawRect(
          bodyRect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  void _drawPeakSeal(
    Canvas canvas,
    Rect chartRect,
    double Function(int) mapX,
    double Function(double) mapY,
    double cWidth,
  ) {
    if (data.isEmpty) return;

    final maxHigh = data.map((d) => d.high).reduce(max);
    final peakIdx = data.indexWhere((d) => d.high == maxHigh);
    if (peakIdx < 0) return;

    final x = mapX(peakIdx);
    final y = mapY(maxHigh);
    const size = 22.0;
    const fontSize = 10.0;

    // 印章中心 Y：优先放在影线上方，但不能超出图表顶部（与大运标签重合）
    final sealCenterY = max(y - size - 4, chartRect.top + size / 2 + 2);

    // Seal background
    final sealRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, sealCenterY),
        width: size,
        height: size,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      sealRect,
      Paint()..color = cinnabarRed.withValues(alpha: 0.9),
    );
    // Inner border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, sealCenterY),
          width: size - 4,
          height: size - 4,
        ),
        const Radius.circular(2),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // Score text
    final scoreText = viewMode == ChartViewMode.year
        ? maxHigh.toInt().toString()
        : maxHigh.toStringAsFixed(1);
    final tp = TextPainter(
      text: TextSpan(
        text: scoreText,
        style: const TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, sealCenterY - tp.height / 2));
  }

  void _drawActionAdviceStamps(
    Canvas canvas,
    double Function(int) mapX,
    double Function(double) mapY,
    double cWidth,
  ) {
    if (data.isEmpty) return;
    final maxHigh = data.map((p) => p.high).reduce(max);
    for (var i = 0; i < data.length; i++) {
      if (data[i].actionAdvice == null) continue;
      // Only stamp originally-generated key years (when set is provided)
      if (keyYearIndices != null && !keyYearIndices!.contains(i)) continue;
      final d = data[i];
      final x = mapX(i);
      final y = mapY(d.high);
      final isUp = d.close >= d.open;
      final character = isUp ? '启' : '变';
      const size = 14.0;
      const fontSize = 9.0;

      // Skip if this is the peak (already has seal)
      if (d.high == maxHigh) continue;

      final sealRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, y - size / 2 - 4),
          width: size,
          height: size,
        ),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(
        sealRect,
        Paint()..color = cinnabarRed.withValues(alpha: 0.95),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y - size / 2 - 4),
            width: size - 2,
            height: size - 2,
          ),
          const Radius.circular(1),
        ),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: character,
          style: const TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, y - size / 2 - 4 - tp.height / 2),
      );
    }
  }

  void _drawLegend(Canvas canvas, Size size) {
    const startX = 44.0;
    const y = 12.0;
    var x = startX;

    // 吉运 legend
    canvas.drawCircle(Offset(x, y), 4, Paint()..color = cinnabarRed);
    x += 8;
    final upLabel = TextPainter(
      text: const TextSpan(
        text: '吉运',
        style: TextStyle(fontSize: 10, color: Color(0xFF7F1D1D)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    upLabel.paint(canvas, Offset(x, y - upLabel.height / 2));
    x += upLabel.width + 16;

    // 凶运 legend
    canvas.drawCircle(Offset(x, y), 4, Paint()..color = indigo);
    x += 8;
    final downLabel = TextPainter(
      text: const TextSpan(
        text: '凶运',
        style: TextStyle(fontSize: 10, color: Color(0xFF312E81)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    downLabel.paint(canvas, Offset(x, y - downLabel.height / 2));
    x += downLabel.width + 16;

    // S/R legend
    _drawDashedLine(
      canvas,
      Offset(x, y),
      Offset(x + 20, y),
      Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 2,
      3,
      3,
    );
    x += 24;
    final srLabel = TextPainter(
      text: const TextSpan(
        text: '支撑/压力',
        style: TextStyle(fontSize: 10, color: Color(0xFF4338CA)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    srLabel.paint(canvas, Offset(x, y - srLabel.height / 2));
    x += srLabel.width + 16;

    // Moving average legend
    final maLabelText = viewMode == ChartViewMode.day ? 'MA5' : 'MA10';
    canvas.drawLine(
      Offset(x, y),
      Offset(x + 20, y),
      Paint()
        ..color = ma10Color
        ..strokeWidth = 2,
    );
    x += 24;
    final maLabel = TextPainter(
      text: TextSpan(
        text: maLabelText,
        style: const TextStyle(fontSize: 10, color: Color(0xFF4338CA)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    maLabel.paint(canvas, Offset(x, y - maLabel.height / 2));
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt(dx * dx + dy * dy);
    final unitX = dx / length;
    final unitY = dy / length;

    var d = 0.0;
    while (d < length) {
      final segEnd = min(d + dashWidth, length);
      canvas.drawLine(
        Offset(start.dx + unitX * d, start.dy + unitY * d),
        Offset(start.dx + unitX * segEnd, start.dy + unitY * segEnd),
        paint,
      );
      d += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant KLinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.viewMode != viewMode ||
        oldDelegate.keyYearIndices != keyYearIndices;
  }
}
