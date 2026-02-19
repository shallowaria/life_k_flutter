import 'k_line_point.dart';
import 'analysis_data.dart';

/// Complete destiny result containing chart data and analysis
class LifeDestinyResult {
  final List<KLinePoint> chartData;
  final AnalysisData analysis;

  const LifeDestinyResult({
    required this.chartData,
    required this.analysis,
  });

  factory LifeDestinyResult.fromJson(Map<String, dynamic> json) {
    return LifeDestinyResult(
      chartData: (json['chartData'] as List)
          .map((e) => KLinePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      analysis:
          AnalysisData.fromJson(json['analysis'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'chartData': chartData.map((e) => e.toJson()).toList(),
        'analysis': analysis.toJson(),
      };
}
