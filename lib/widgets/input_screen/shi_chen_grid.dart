import 'package:flutter/material.dart';
import 'package:life_k/constants/shi_chen.dart';

class ShiChenGrid extends StatelessWidget {
  const ShiChenGrid({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: shiChenList.length,
      itemBuilder: (context, index) {
        final sc = shiChenList[index];
        final isSelected = selected == sc.name;
        return InkWell(
          onTap: () => onChanged(sc.name),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF8B3A3A) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF5E2626)
                    : const Color(0xFFC2BBA8),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sc.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sc.range,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
