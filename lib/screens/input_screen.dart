import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:life_k/widgets/input_screen/add_event_sheet.dart';
import 'package:life_k/widgets/input_screen/bazi_preview_section.dart';
import 'package:life_k/widgets/input_screen/gender_selector.dart';
import 'package:life_k/widgets/input_screen/life_events_section.dart';
import 'package:life_k/widgets/input_screen/shi_chen_grid.dart';
import '../models/user_input.dart';
import '../models/life_event.dart';
import '../services/bazi_calculator.dart';
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
      builder: (ctx) => AddEventSheet(
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
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFEF2F2),
                  Color(0xFFFED7AA),
                  Color(0xFFFEF9C3),
                ],
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
                GenderSelector(
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
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    _onDatePicked();
                  },
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
                ShiChenGrid(
                  selected: _shiChen,
                  onChanged: (s) {
                    setState(() => _shiChen = s);
                    _calculateBazi();
                  },
                ),
                if (_calculatedData != null) ...[
                  BaziPreviewSection(data: _calculatedData!),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  LifeEventsSection(
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
