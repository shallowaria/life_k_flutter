import 'package:flutter/material.dart';
import 'package:life_k/services/bazi_calculator.dart';

class BaziPreviewSection extends StatelessWidget {
  const BaziPreviewSection({super.key, required this.data});

  final BaziCalculationResult data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            '— 八字排盘结果 —',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F4545),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _pillar('年柱', data.yearPillar),
            _pillar('月柱', data.monthPillar),
            _pillar('日柱', data.dayPillar),
            _pillar('时柱', data.hourPillar),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Color(0xFF5C7A6B)),
              children: [
                const TextSpan(text: '起运年龄  '),
                TextSpan(
                  text: '${data.startAge} 岁',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB22222),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pillar(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8B7E66)),
        ),
        const SizedBox(height: 4),
        Column(
          children: value.split('').map((char) {
            return Text(
              char,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
