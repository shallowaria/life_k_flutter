import 'package:flutter/material.dart';
import '../../models/k_line_point.dart';

/// Tooltip overlay for K-line chart showing detailed info about a data point
class KLineTooltip extends StatelessWidget {
  final KLinePoint point;

  const KLineTooltip({super.key, required this.point});

  @override
  Widget build(BuildContext context) {
    final isUp = point.close >= point.open;

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
                        '${point.year} ${point.ganZhi}年 (${point.age}岁)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '大运: ${point.daYun ?? "未知"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUp
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isUp ? '吉 ▲' : '凶 ▼',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUp
                          ? Colors.green.shade700
                          : Colors.red.shade700,
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

            // Energy score
            if (point.energyScore != null) ...[
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
                        const Text('能量分数',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A5F))),
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
                    _buildEnergyRow('月令系数', point.energyScore!.monthCoefficient),
                    _buildEnergyRow('日支关系', point.energyScore!.dayRelation),
                    _buildEnergyRow('时辰波动', point.energyScore!.hourFluctuation),
                    if (point.energyScore!.isBelowSupport) ...[
                      const SizedBox(height: 4),
                      const Text(
                        '⚠ 已跌破支撑位',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB91C1C),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Reason
            Text(
              point.reason,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4),
            ),

            // Action advice
            if (point.actionAdvice != null) ...[
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 14, color: Color(0xFF312E81)),
                  const SizedBox(width: 4),
                  const Text('行动指南',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF312E81))),
                  const Spacer(),
                  if (point.actionAdvice!.scenario != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        point.actionAdvice!.scenario!,
                        style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Suggestions
              ...point.actionAdvice!.suggestions.asMap().entries.map((e) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${e.key + 1}. ${e.value}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                    ),
                  )),
              const SizedBox(height: 4),
              // Warnings
              ...point.actionAdvice!.warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• $w',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                    ),
                  )),
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
                    style: const TextStyle(fontSize: 10, color: Color(0xFF6D28D9)),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOhlcItem(String label, double value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
        const SizedBox(height: 2),
        Text(
          value.toInt().toString(),
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151)),
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
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
          Text(value.toStringAsFixed(0),
              style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF4B5563))),
        ],
      ),
    );
  }
}
