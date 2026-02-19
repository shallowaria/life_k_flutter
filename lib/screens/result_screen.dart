import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/destiny_result/destiny_result_bloc.dart';
import '../blocs/destiny_result/destiny_result_state.dart';
import '../models/life_destiny_result.dart';
import '../models/k_line_point.dart';
import '../models/analysis_data.dart';
import '../widgets/k_line_chart/k_line_chart.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DestinyResultBloc, DestinyResultState>(
      builder: (context, state) {
        if (state is! DestinyResultSuccess) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('暂无数据，请先生成K线图'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/input'),
                    child: const Text('返回输入'),
                  ),
                ],
              ),
            ),
          );
        }

        final result = state.result;
        final userName = state.userName;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFEF2F2), Color(0xFFF5F0E8)],
              ),
            ),
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  // App bar
                  SliverAppBar(
                    floating: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF2C1810)),
                      onPressed: () => context.go('/input'),
                    ),
                    title: Text(
                      '$userName 的人生K线图',
                      style: const TextStyle(
                        color: Color(0xFF2C1810),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    centerTitle: true,
                  ),

                  // Risk warning
                  SliverToBoxAdapter(
                    child: _buildRiskWarning(),
                  ),

                  // K-Line chart
                  SliverToBoxAdapter(
                    child: _buildKLineSection(result),
                  ),

                  // Analysis cards
                  SliverToBoxAdapter(
                    child: _buildAnalysisSection(result.analysis),
                  ),

                  // Action advice for key years
                  SliverToBoxAdapter(
                    child: _buildActionAdviceSection(result.chartData),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRiskWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '本工具仅供娱乐参考，命理分析由 AI 生成，不构成任何投资建议。',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKLineSection(LifeDestinyResult result) {
    return KLineChart(
      data: result.chartData,
      supportPressureLevels: result.analysis.supportPressureLevels ?? [],
    );
  }

  Widget _buildAnalysisSection(AnalysisData analysis) {
    final dimensions = [
      _AnalysisDimension('命理总评', analysis.summary, analysis.summaryScore, Icons.auto_awesome),
      _AnalysisDimension('性格分析', analysis.personality, analysis.personalityScore, Icons.psychology),
      _AnalysisDimension('事业分析', analysis.industry, analysis.industryScore, Icons.work),
      _AnalysisDimension('风水建议', analysis.fengShui, analysis.fengShuiScore, Icons.home),
      _AnalysisDimension('财富分析', analysis.wealth, analysis.wealthScore, Icons.attach_money),
      _AnalysisDimension('婚姻分析', analysis.marriage, analysis.marriageScore, Icons.favorite),
      _AnalysisDimension('健康分析', analysis.health, analysis.healthScore, Icons.health_and_safety),
      _AnalysisDimension('六亲分析', analysis.family, analysis.familyScore, Icons.family_restroom),
      _AnalysisDimension('币圈分析', analysis.crypto, analysis.cryptoScore, Icons.currency_bitcoin),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '九维命理分析',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C1810),
            ),
          ),
          const SizedBox(height: 12),
          ...dimensions.map(_buildAnalysisCard),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(_AnalysisDimension dim) {
    final scoreColor = dim.score >= 7
        ? const Color(0xFF16A34A)
        : dim.score >= 4
            ? const Color(0xFFCA8A04)
            : const Color(0xFFDC2626);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Icon(dim.icon, size: 20, color: const Color(0xFF8B3A3A)),
              const SizedBox(width: 8),
              Text(
                dim.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C1810),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${dim.score.toStringAsFixed(1)} 分',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: dim.score / 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(scoreColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dim.content,
            style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActionAdviceSection(List<KLinePoint> chartData) {
    final keyPoints = chartData.where((p) => p.actionAdvice != null).toList();
    if (keyPoints.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '关键年份行动指南',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C1810),
            ),
          ),
          const SizedBox(height: 12),
          ...keyPoints.map(_buildActionAdviceCard),
        ],
      ),
    );
  }

  Widget _buildActionAdviceCard(KLinePoint point) {
    final advice = point.actionAdvice!;
    final isUp = point.close >= point.open;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUp ? const Color(0xFFB22D1B).withValues(alpha: 0.3) : const Color(0xFF2F4F4F).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUp ? const Color(0xFFB22D1B) : const Color(0xFF2F4F4F),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${point.year} (${point.age}岁)',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              if (point.tenGod != null)
                Text(
                  point.tenGod!.label,
                  style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                ),
              const Spacer(),
              if (advice.scenario != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(advice.scenario!, style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Suggestions
          const Text('建议行动', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
          const SizedBox(height: 4),
          ...advice.suggestions.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key + 1}. ', style: const TextStyle(fontSize: 13, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                    Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          // Warnings
          const Text('规避提醒', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
          const SizedBox(height: 4),
          ...advice.warnings.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('  ', style: TextStyle(fontSize: 13, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                    Expanded(child: Text(w, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
          // Basis
          if (advice.basis != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Text(
                '玄学依据: ${advice.basis}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6D28D9)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalysisDimension {
  final String title;
  final String content;
  final double score;
  final IconData icon;

  _AnalysisDimension(this.title, this.content, this.score, this.icon);
}
