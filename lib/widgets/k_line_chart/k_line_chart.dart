import 'package:flutter/material.dart';
import '../../models/k_line_point.dart';
import '../../models/analysis_data.dart';
import '../../services/kline_interpolation_service.dart';
import '../../services/tick_tick_service.dart';
import 'chart_view_mode.dart';
import 'k_line_painter.dart';
import 'k_line_tooltip.dart';

class KLineChart extends StatefulWidget {
  final List<KLinePoint> data;
  final String? title;
  final List<SupportPressureLevel> supportPressureLevels;
  final int currentAge;
  final Map<String, ActionAdvice>? dailyAdvice;
  final bool isLoadingDailyAdvice;
  final Map<int, ActionAdvice>? yearAdvice;
  final bool isLoadingYearAdvice;
  final VoidCallback? onYearAdviceRequested;
  final void Function(ChartViewMode mode, List<KLinePoint> interpolatedPoints)?
  onViewModeChanged;

  const KLineChart({
    super.key,
    required this.data,
    this.title,
    this.supportPressureLevels = const [],
    required this.currentAge,
    this.dailyAdvice,
    this.isLoadingDailyAdvice = false,
    this.yearAdvice,
    this.isLoadingYearAdvice = false,
    this.onYearAdviceRequested,
    this.onViewModeChanged,
  });

  @override
  State<KLineChart> createState() => _KLineChartState();
}

class _KLineChartState extends State<KLineChart> {
  int? _selectedIndex;
  OverlayEntry? _tooltipOverlay;
  ChartViewMode _viewMode = ChartViewMode.year;

  // Cached interpolated data for month/day views
  List<KLinePoint>? _cachedMonthData;
  List<KLinePoint>? _cachedDayData;

  List<KLinePoint> get _baseDisplayData {
    switch (_viewMode) {
      case ChartViewMode.year:
        return widget.data;
      case ChartViewMode.month:
        _cachedMonthData ??= _generateInterpolatedData(ChartViewMode.month);
        return _cachedMonthData!;
      case ChartViewMode.day:
        _cachedDayData ??= _generateInterpolatedData(ChartViewMode.day);
        return _cachedDayData!;
    }
  }

  List<KLinePoint> get _displayData {
    final base = _baseDisplayData;
    if (_viewMode == ChartViewMode.year) {
      if (widget.yearAdvice == null) return base;
      return base.map((p) {
        if (p.actionAdvice != null) return p;
        final advice = widget.yearAdvice![p.year];
        if (advice == null) return p;
        return KLinePoint(
          age: p.age,
          year: p.year,
          ganZhi: p.ganZhi,
          daYun: p.daYun,
          open: p.open,
          close: p.close,
          high: p.high,
          low: p.low,
          score: p.score,
          reason: p.reason,
          tenGod: p.tenGod,
          energyScore: p.energyScore,
          actionAdvice: advice,
        );
      }).toList();
    }
    if (widget.dailyAdvice == null) return base;
    return base.map((p) {
      final parts = p.ganZhi.split('/');
      final key = '${p.year}-${parts[0]}-${parts[1]}';
      final advice = widget.dailyAdvice![key];
      if (advice == null) return p;
      return KLinePoint(
        age: p.age,
        year: p.year,
        ganZhi: p.ganZhi,
        daYun: p.daYun,
        open: p.open,
        close: p.close,
        high: p.high,
        low: p.low,
        score: p.score,
        reason: p.reason,
        tenGod: p.tenGod,
        energyScore: p.energyScore,
        actionAdvice: advice,
      );
    }).toList();
  }

  List<KLinePoint> _generateInterpolatedData(ChartViewMode mode) {
    final today = DateTime.now();
    final range = mode.dateRange(today);
    return KLineInterpolationService.interpolate(
      anchorPoints: widget.data,
      start: range.start,
      end: range.end,
    );
  }

  void _switchViewMode(ChartViewMode mode) {
    if (mode == _viewMode) return;
    _removeTooltip();
    setState(() {
      _viewMode = mode;
      _selectedIndex = null;
    });
    if (mode != ChartViewMode.year) {
      final points = _baseDisplayData;
      widget.onViewModeChanged?.call(mode, points);
    }
  }

  @override
  void didUpdateWidget(KLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data != widget.data) {
      _cachedMonthData = null;
      _cachedDayData = null;
    }

    if (oldWidget.dailyAdvice != widget.dailyAdvice ||
        oldWidget.isLoadingDailyAdvice != widget.isLoadingDailyAdvice ||
        oldWidget.yearAdvice != widget.yearAdvice ||
        oldWidget.isLoadingYearAdvice != widget.isLoadingYearAdvice) {
      if (_selectedIndex != null && _tooltipOverlay != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _tooltipOverlay != null) {
            _tooltipOverlay!.markNeedsBuild();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  Future<void> _handleReminderTap(KLinePoint point) async {
    _removeTooltip();
    setState(() => _selectedIndex = null);

    final rootContext = context;
    final messenger = ScaffoldMessenger.of(rootContext);

    final pickedTime = await showTimePicker(
      context: rootContext,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      helpText: '选择提醒时间',
    );
    if (pickedTime == null) return;

    final success = await TickTickService.createReminder(
      point: point,
      time: pickedTime,
      date: DateTime.now(),
    );

    if (!mounted) return;

    messenger.showSnackBar(
      success
          ? const SnackBar(
              content: Text('内容已复制到剪贴板，请在收集箱长按粘贴创建任务'),
              duration: Duration(seconds: 3),
            )
          : SnackBar(
              content: Text(
                '滴答清单未安装，提醒内容：${TickTickService.buildFallbackText(point, pickedTime)}',
              ),
              duration: const Duration(seconds: 5),
            ),
    );
  }

  void _showTooltip(int index, Offset globalPosition) {
    _removeTooltip();
    final data = _displayData;
    if (index < 0 || index >= data.length) return;

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;

    _tooltipOverlay = OverlayEntry(
      builder: (context) {
        // Position tooltip to the left or right of the tap
        final point = _displayData[index]; // 🔥 每次build都重新取最新数据
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
              child: KLineTooltip(
                point: point,
                viewMode: _viewMode,
                isLoadingAdvice: _viewMode == ChartViewMode.year
                    ? widget.isLoadingYearAdvice
                    : widget.isLoadingDailyAdvice,
                onReminderTap:
                    (_viewMode == ChartViewMode.day &&
                        point.actionAdvice != null)
                    ? () => _handleReminderTap(point)
                    : null,
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_tooltipOverlay!);
  }

  int? _hitTestCandle(Offset localPosition, Size size) {
    final data = _displayData;
    if (data.isEmpty) return null;

    const chartLeft = KLinePainter.paddingLeft;
    const chartRight = -KLinePainter.paddingRight; // will add to size.width
    final chartWidth = size.width + chartRight - chartLeft;
    final candleSpacing = chartWidth / data.length;

    final x = localPosition.dx - chartLeft;
    if (x < 0) return null;

    final index = (x / candleSpacing).floor();
    if (index < 0 || index >= data.length) return null;

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

    final today = DateTime.now();
    final displayData = _displayData;

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
          // Chart header with view mode switcher
          _buildChartHeader(today),
          // Dynamic title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              _viewMode.formatSubtitle(today, widget.currentAge),
              style: const TextStyle(
                fontSize: 14,
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
                // Adjust for container padding and header
                final localPos = box.globalToLocal(details.globalPosition);
                final chartLocalPos = Offset(
                  localPos.dx - 8, // container padding
                  localPos.dy - 80, // header + subtitle + padding
                );
                final size = Size(box.size.width - 16, 300);
                final idx = _hitTestCandle(chartLocalPos, size);
                setState(() => _selectedIndex = idx);
                if (idx != null) {
                  _showTooltip(idx, details.globalPosition);
                  // Trigger yearly advice fetch when tapping a year candle
                  // that has no advice and the batch hasn't been fetched yet.
                  if (_viewMode == ChartViewMode.year &&
                      !widget.isLoadingYearAdvice &&
                      widget.yearAdvice == null) {
                    final point = _displayData[idx];
                    if (point.actionAdvice == null) {
                      widget.onYearAdviceRequested?.call();
                    }
                  }
                } else {
                  _removeTooltip();
                }
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: KLinePainter(
                  data: displayData,
                  supportPressureLevels: widget.supportPressureLevels,
                  selectedIndex: _selectedIndex,
                  viewMode: _viewMode,
                  keyYearIndices: _viewMode == ChartViewMode.year
                      ? {
                          for (var i = 0; i < widget.data.length; i++)
                            if (widget.data[i].actionAdvice != null) i,
                        }
                      : null,
                ),
              ),
            ),
          ),
          // Chart footer (only for month/day views)
          if (_viewMode != ChartViewMode.year) _buildChartFooter(displayData),
        ],
      ),
    );
  }

  Widget _buildChartHeader(DateTime today) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '运势时间轴',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Row(
                children: ChartViewMode.values.map((mode) {
                  final isSelected = mode == _viewMode;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: () => _switchViewMode(mode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFB22D1B)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFB22D1B)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                        child: Text(
                          mode.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '当前虚岁: ${widget.currentAge}岁 | 今日: ${today.year}/${today.month}/${today.day}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildChartFooter(List<KLinePoint> displayData) {
    // Calculate Y-axis range for display
    final allValues = displayData.expand((d) => [d.low, d.high]).toList();
    final dataMin = allValues.reduce((a, b) => a < b ? a : b);
    final dataMax = allValues.reduce((a, b) => a > b ? a : b);
    final padding = (dataMax - dataMin) * 0.15;
    final yMin = (dataMin - padding).clamp(0.0, 10.0);
    final yMax = (dataMax + padding).clamp(0.0, 10.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '数据基于年度运势插值计算，仅供参考',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          Text(
            'Y轴已动态调整至 ${yMin.toStringAsFixed(1)}-${yMax.toStringAsFixed(1)} 范围以更好展示运势波动',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
