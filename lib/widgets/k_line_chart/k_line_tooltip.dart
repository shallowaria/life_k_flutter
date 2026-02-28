import 'package:flutter/material.dart';
import '../../models/k_line_point.dart';
import 'chart_view_mode.dart';

/// Tooltip overlay for K-line chart showing detailed info about a data point
class KLineTooltip extends StatelessWidget {
  final KLinePoint point;
  final ChartViewMode viewMode;
  final bool isLoadingAdvice;
  final VoidCallback? onReminderTap;

  const KLineTooltip({
    super.key,
    required this.point,
    this.viewMode = ChartViewMode.year,
    this.isLoadingAdvice = false,
    this.onReminderTap,
  });

  bool get _isInterpolated => viewMode != ChartViewMode.year;

  @override
  Widget build(BuildContext context) {
    final isUp = point.close >= point.open;
    // 1. 定义一个状态判断：是否已经准备好可以点击（加载中时强制为 false，避免旧数据残留）
    final bool isReady = point.actionAdvice != null && !isLoadingAdvice;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isInterpolated
                            ? '${point.year}/${point.ganZhi} (${point.age}岁)'
                            : '${point.year} ${point.ganZhi}年 (${point.age}岁)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (point.daYun != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '大运: ${point.daYun}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (point.tenGod != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '十神: ${point.tenGod!.label}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isUp ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isUp ? '吉 ▲' : '凶 ▼',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUp ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // OHLC grid
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOhlcItem('开盘', point.open),
                  _buildOhlcItem('收盘', point.close),
                  _buildOhlcItem('最高', point.high),
                  _buildOhlcItem('最低', point.low),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Energy score (year view only, when available)
            if (!_isInterpolated && point.energyScore != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '能量分数',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                        Text(
                          point.energyScore!.total.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: point.energyScore!.isBelowSupport
                                ? Colors.red.shade600
                                : point.energyScore!.total >= 7
                                ? Colors.green.shade600
                                : const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildEnergyRow(
                      '月令系数',
                      point.energyScore!.monthCoefficient,
                    ),
                    _buildEnergyRow('日支关系', point.energyScore!.dayRelation),
                    _buildEnergyRow('时辰波动', point.energyScore!.hourFluctuation),
                    if (point.energyScore!.isBelowSupport) ...[
                      const SizedBox(height: 4),
                      const Text(
                        '⚠ 已跌破支撑位',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Reason / interpolation note
            Text(
              point.reason,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),

            // Base score (interpolated views)
            if (_isInterpolated) ...[
              const SizedBox(height: 4),
              Text(
                '基准分: ${point.score.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],

            // Action advice (when available, or loading in interpolated views)
            if (_isInterpolated && isLoadingAdvice) ...[
              const Divider(height: 20),
              const Row(
                children: [
                  SizedBox(width: 2),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF312E81),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '行动建议生成中...',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ] else if (point.actionAdvice != null) ...[
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.gps_fixed,
                    size: 14,
                    color: Color(0xFF312E81),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '行动指南',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF312E81),
                        ),
                      ),
                      if (_isInterpolated)
                        const Text(
                          '行动建议',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (point.actionAdvice!.scenario != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        point.actionAdvice!.scenario!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Suggestions
              ...point.actionAdvice!.suggestions.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${e.key + 1}. ${e.value}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Warnings
              ...point.actionAdvice!.warnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• $w',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ),
              ),
              // Basis
              if (point.actionAdvice!.basis != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '玄学依据: ${point.actionAdvice!.basis}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6D28D9),
                    ),
                  ),
                ),
              ],
            ],

            // One-tap reminder button (day view only)
            if (viewMode == ChartViewMode.day) ...[
              // 删除了 point.actionAdvice != null 的判断
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  // 2. 当未准备好时，将 onPressed 设为 null，按钮会自动变为禁用状态
                  onPressed: isReady ? onReminderTap : null,
                  icon: Text(
                    '🤔',
                    style: TextStyle(
                      fontSize: 14,
                      // 3. 禁用时图标也变灰色
                      color: isReady ? Colors.blue : Colors.grey,
                    ),
                  ),
                  label: Text(
                    isReady ? '添加到滴答清单 ✔️' : '建议加载中... ❌', // 可选：动态修改文案
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    // 4. 动态调整前景色和边框颜色
                    foregroundColor: isReady
                        ? const Color(0xFF312E81)
                        : Colors.grey,
                    side: BorderSide(
                      color: isReady
                          ? const Color(0xFF312E81)
                          : Colors.grey.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOhlcItem(String label, double value) {
    final valueText = _isInterpolated
        ? value.toStringAsFixed(2)
        : value.toInt().toString();
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 2),
        Text(
          valueText,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _buildEnergyRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
          ),
          Text(
            value.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}
