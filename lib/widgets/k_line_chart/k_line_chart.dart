import 'package:flutter/material.dart';
import '../../models/k_line_point.dart';
import '../../models/analysis_data.dart';
import 'k_line_painter.dart';
import 'k_line_tooltip.dart';

class KLineChart extends StatefulWidget {
  final List<KLinePoint> data;
  final String? title;
  final List<SupportPressureLevel> supportPressureLevels;

  const KLineChart({
    super.key,
    required this.data,
    this.title,
    this.supportPressureLevels = const [],
  });

  @override
  State<KLineChart> createState() => _KLineChartState();
}

class _KLineChartState extends State<KLineChart> {
  int? _selectedIndex;
  OverlayEntry? _tooltipOverlay;

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  void _showTooltip(int index, Offset globalPosition) {
    _removeTooltip();
    if (index < 0 || index >= widget.data.length) return;

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    final point = widget.data[index];

    _tooltipOverlay = OverlayEntry(
      builder: (context) {
        // Position tooltip to the left or right of the tap
        const tooltipWidth = 280.0;
        const tooltipMaxHeight = 480.0;
        double left = globalPosition.dx + 16;
        if (left + tooltipWidth > screenSize.width - 16) {
          left = globalPosition.dx - tooltipWidth - 16;
        }
        left = left.clamp(8.0, screenSize.width - tooltipWidth - 8);
        double top = globalPosition.dy - 100;
        top = top.clamp(8.0, screenSize.height - tooltipMaxHeight - 8);

        return Stack(
          children: [
            // Dismiss on tap outside
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _removeTooltip();
                  setState(() => _selectedIndex = null);
                },
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: KLineTooltip(point: point),
            ),
          ],
        );
      },
    );

    overlay.insert(_tooltipOverlay!);
  }

  int? _hitTestCandle(Offset localPosition, Size size) {
    if (widget.data.isEmpty) return null;

    const chartLeft = KLinePainter.paddingLeft;
    const chartRight = -KLinePainter.paddingRight; // will add to size.width
    final chartWidth = size.width + chartRight - chartLeft;
    final candleSpacing = chartWidth / widget.data.length;

    final x = localPosition.dx - chartLeft;
    if (x < 0) return null;

    final index = (x / candleSpacing).floor();
    if (index < 0 || index >= widget.data.length) return null;

    return index;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Container(
        height: 350,
        alignment: Alignment.center,
        child: const Text('无数据', style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              widget.title ?? '人生流年大运K线图',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          // Chart
          SizedBox(
            height: 300,
            child: GestureDetector(
              onTapUp: (details) {
                final box = context.findRenderObject() as RenderBox;
                // Adjust for container padding and title
                final localPos = box.globalToLocal(details.globalPosition);
                final chartLocalPos = Offset(
                  localPos.dx - 8, // container padding
                  localPos.dy - 36, // approx title height + padding
                );
                final size = Size(box.size.width - 16, 300);
                final idx = _hitTestCandle(chartLocalPos, size);
                setState(() => _selectedIndex = idx);
                if (idx != null) {
                  _showTooltip(idx, details.globalPosition);
                } else {
                  _removeTooltip();
                }
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: KLinePainter(
                  data: widget.data,
                  supportPressureLevels: widget.supportPressureLevels,
                  selectedIndex: _selectedIndex,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
