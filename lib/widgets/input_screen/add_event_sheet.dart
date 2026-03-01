import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_k/models/life_event.dart';

class AddEventSheet extends StatefulWidget {
  const AddEventSheet({super.key, required this.onConfirm});

  final ValueChanged<LifeEvent> onConfirm;

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _yearCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _granularity = 0; // 0=年, 1=年月, 2=年月日
  int _selectedMonth = 1;
  int _selectedDay = 1;
  EventType _selectedType = EventType.career;
  EventOutcome _selectedOutcome = EventOutcome.smooth;
  String? _yearError;

  @override
  void dispose() {
    _yearCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final year = _yearCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (year.isEmpty || desc.isEmpty) return;

    final yearInt = int.tryParse(year);
    if (yearInt == null || yearInt < 1900 || yearInt > 2100) {
      setState(() => _yearError = '请输入 1900–2100 之间的有效年份');
      return;
    }

    widget.onConfirm(
      LifeEvent(
        year: year,
        month: _granularity >= 1
            ? _selectedMonth.toString().padLeft(2, '0')
            : null,
        day: _granularity >= 2 ? _selectedDay.toString().padLeft(2, '0') : null,
        description: desc,
        type: _selectedType,
        outcome: _selectedOutcome,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                '添加人生大事',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A3B32),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '时间粒度',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A3B32),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _toggle(
                  '年',
                  _granularity == 0,
                  () => setState(() => _granularity = 0),
                ),
                const SizedBox(width: 8),
                _toggle(
                  '年月',
                  _granularity == 1,
                  () => setState(() => _granularity = 1),
                ),
                const SizedBox(width: 8),
                _toggle(
                  '年月日',
                  _granularity == 2,
                  () => setState(() => _granularity = 2),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '年份 *',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A3B32),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _yearCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) {
                if (_yearError != null) setState(() => _yearError = null);
              },
              decoration: InputDecoration(
                hintText: '如 2026',
                counterText: '',
                errorText: _yearError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_granularity >= 1) ...[
              const Text(
                '月份',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A3B32),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedMonth,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: List.generate(
                  12,
                  (i) =>
                      DropdownMenuItem(value: i + 1, child: Text('${i + 1} 月')),
                ),
                onChanged: (v) => setState(() => _selectedMonth = v!),
              ),
              const SizedBox(height: 16),
            ],
            if (_granularity >= 2) ...[
              const Text(
                '日期',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A3B32),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedDay,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: List.generate(
                  31,
                  (i) =>
                      DropdownMenuItem(value: i + 1, child: Text('${i + 1} 日')),
                ),
                onChanged: (v) => setState(() => _selectedDay = v!),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              '事件描述 *',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A3B32),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                hintText: '如：跳槽、结婚、创业',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '事件类型',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A3B32),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: EventType.values
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _toggle(
                        t.label,
                        _selectedType == t,
                        () => setState(() => _selectedType = t),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              '结果',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A3B32),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _toggle(
                  '顺利',
                  _selectedOutcome == EventOutcome.smooth,
                  () => setState(() => _selectedOutcome = EventOutcome.smooth),
                ),
                const SizedBox(width: 8),
                _toggle(
                  '不顺',
                  _selectedOutcome == EventOutcome.difficult,
                  () =>
                      setState(() => _selectedOutcome = EventOutcome.difficult),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B3A3A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '确认添加',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8B3A3A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF5E2626) : const Color(0xFFC2BBA8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : const Color(0xFF5D4037),
          ),
        ),
      ),
    );
  }
}
