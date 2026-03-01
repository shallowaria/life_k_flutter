import 'package:flutter/material.dart';
import 'package:life_k/models/user_input.dart';

class GenderSelector extends StatelessWidget {
  const GenderSelector({
    super.key,
    required this.gender,
    required this.onChanged,
  });

  final Gender gender;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _button('乾造 男', Gender.male, const Color(0xFF8B3A3A))),
        const SizedBox(width: 12),
        Expanded(
          child: _button('坤造 女', Gender.female, const Color(0xFF4A6A6A)),
        ),
      ],
    );
  }

  Widget _button(String label, Gender value, Color activeColor) {
    final isSelected = gender == value;
    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFF8B7E66),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF5D4037),
            ),
          ),
        ),
      ),
    );
  }
}
