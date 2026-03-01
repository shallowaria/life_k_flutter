import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../models/user_input.dart';
import '../models/life_event.dart';
import '../services/bazi_calculator.dart';
import '../constants/shi_chen.dart';
import '../blocs/user_input/user_input_bloc.dart';
import '../blocs/user_input/user_input_event.dart';
import '../blocs/destiny_result/destiny_result_bloc.dart';
import '../blocs/destiny_result/destiny_result_event.dart';
import '../blocs/destiny_result/destiny_result_state.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _nameController = TextEditingController();
  Gender _gender = Gender.male;
  DateTime? _birthDate;
  String _shiChen = '子时';
  BaziCalculationResult? _calculatedData;
  String? _error;
  final List<LifeEvent> _lifeEvents = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onDatePicked() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _error = null;
      });
      _calculateBazi();
    }
  }

  void _calculateBazi() {
    if (_birthDate == null) return;

    final validationError = BaziCalculator.validateInput(
      birthDate: _birthDate,
      shiChenName: _shiChen,
      gender: _gender,
    );
    if (validationError != null) {
      setState(() {
        _error = validationError;
        _calculatedData = null;
      });
      return;
    }

    try {
      final result = BaziCalculator.calculate(
        birthDate: _birthDate!,
        shiChenName: _shiChen,
        gender: _gender,
      );
      setState(() {
        _calculatedData = result;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = '计算失败: $e';
        _calculatedData = null;
      });
    }
  }

  void _onSubmit() {
    if (_calculatedData == null || _birthDate == null) {
      setState(() => _error = '请先填写出生日期和时辰');
      return;
    }

    final birthDateStr =
        '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';

    final userInput = UserInput(
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      gender: _gender,
      birthYear: _calculatedData!.birthYear,
      birthDate: birthDateStr,
      yearPillar: _calculatedData!.yearPillar,
      monthPillar: _calculatedData!.monthPillar,
      dayPillar: _calculatedData!.dayPillar,
      hourPillar: _calculatedData!.hourPillar,
      startAge: _calculatedData!.startAge,
      lifeEvents: _lifeEvents.isNotEmpty
          ? List.unmodifiable(_lifeEvents)
          : null,
    );

    context.read<UserInputBloc>().add(UserInputUpdated(userInput));
    context.read<DestinyResultBloc>().add(DestinyResultGenerate(userInput));
  }

  void _showAddEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F0E8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddEventSheet(
        onConfirm: (event) => setState(() => _lifeEvents.add(event)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DestinyResultBloc, DestinyResultState>(
      listener: (context, state) {
        if (state is DestinyResultSuccess) context.push('/result');
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFEF2F2), Color(0xFFFED7AA), Color(0xFFFEF9C3)],
            ),
          ),
          child: SafeArea(
            child: BlocBuilder<DestinyResultBloc, DestinyResultState>(
              builder: (context, destinyState) {
                if (destinyState is DestinyResultLoading) {
                  return _buildLoadingView();
                }
                if (destinyState is DestinyResultFailure) {
                  return _buildErrorView(destinyState);
                }
                return _buildFormView();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '正在生成您的人生 K 线图...',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI 正在分析您的八字命理，预计需要 30-60 秒',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                '生成中包含：30年运势数据、支撑/压力位分析、个性化行动建议',
                style: TextStyle(fontSize: 14, color: Color(0xFF1E40AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(DestinyResultFailure state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    '生成失败',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  if (state.suggestion != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.suggestion!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<DestinyResultBloc>().add(
                const DestinyResultCleared(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B3A3A),
                foregroundColor: Colors.white,
              ),
              child: const Text('返回重新填写'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            '人生K线图',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '用 AI 和八字命理绘制您的人生运势曲线',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B7E66), width: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    '请输入您的出生信息',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A3B32),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionLabel('姓名（可选）'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: '请输入姓名',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel('性别 *'),
                const SizedBox(height: 8),
                _GenderSelector(
                  gender: _gender,
                  onChanged: (g) {
                    setState(() => _gender = g);
                    _calculateBazi();
                  },
                ),
                const SizedBox(height: 20),
                _sectionLabel('出生日期 (公历) *'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _onDatePicked,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _birthDate != null
                                ? '${_birthDate!.year} 年 ${_birthDate!.month} 月 ${_birthDate!.day} 日'
                                : '请选择出生日期',
                            style: TextStyle(
                              fontSize: 16,
                              color: _birthDate != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel('出生时辰 *'),
                const SizedBox(height: 8),
                _ShiChenGrid(
                  selected: _shiChen,
                  onChanged: (s) {
                    setState(() => _shiChen = s);
                    _calculateBazi();
                  },
                ),
                if (_calculatedData != null) ...[
                  _BaziPreviewSection(data: _calculatedData!),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _LifeEventsSection(
                    events: _lifeEvents,
                    onAddTap: _showAddEventSheet,
                    onRemoveAt: (i) => setState(() => _lifeEvents.removeAt(i)),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calculatedData != null ? _onSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _calculatedData != null
                          ? const Color(0xFF8B3A3A)
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      _calculatedData != null ? '点击以生成K线图' : '请先完善信息',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '本工具仅供娱乐参考，命理分析由 AI 生成，不构成任何投资建议。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: const Color(0xFFB22222)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A3B32),
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.gender, required this.onChanged});

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

class _ShiChenGrid extends StatelessWidget {
  const _ShiChenGrid({required this.selected, required this.onChanged});

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

class _BaziPreviewSection extends StatelessWidget {
  const _BaziPreviewSection({required this.data});

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

class _LifeEventsSection extends StatelessWidget {
  const _LifeEventsSection({
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
              onPressed: onAddTap,
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

class _AddEventSheet extends StatefulWidget {
  const _AddEventSheet({required this.onConfirm});

  final ValueChanged<LifeEvent> onConfirm;

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
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
