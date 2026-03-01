import 'package:flutter/material.dart';
import 'package:life_k/models/life_event.dart';

class LifeEventsSection extends StatelessWidget {
  const LifeEventsSection({
    super.key,
    required this.events,
    required this.onAddTap,
    required this.onRemoveAt,
  });

  final List<LifeEvent> events;
  final VoidCallback onAddTap;
  final ValueChanged<int> onRemoveAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Center(
              child: Text(
                '— 过往人生大事(可选) —',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F4545),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                onAddTap();
              },
              icon: const Icon(Icons.add, size: 18, color: Color(0xFF8B3A3A)),
              label: const Text(
                '添加事件',
                style: TextStyle(color: Color(0xFF8B3A3A)),
              ),
            ),
          ],
        ),
        if (events.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...events.asMap().entries.map(
            (entry) => _eventCard(entry.key, entry.value),
          ),
        ] else ...[
          const SizedBox(height: 4),
          const Text(
            '添加您的重要人生节点，帮助 AI 校准运势预测',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _eventCard(int i, LifeEvent event) {
    final isSmooth = event.outcome == EventOutcome.smooth;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC2BBA8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF8B3A3A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.type.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8B3A3A)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${event.year}年${event.month != null ? '${event.month!.padLeft(2, '0')}月' : ''}  ${event.description}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSmooth ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.outcome.label,
              style: TextStyle(
                fontSize: 12,
                color: isSmooth
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => onRemoveAt(i),
          ),
        ],
      ),
    );
  }
}
