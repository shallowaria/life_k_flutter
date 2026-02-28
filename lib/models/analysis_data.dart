import 'package:equatable/equatable.dart';
import 'k_line_point.dart';

/// Support/Pressure level for K-line chart reference lines
class SupportPressureLevel extends Equatable {
  final int age;
  final String? date;
  final String type; // 'support' or 'pressure'
  final double value; // Y-axis position (0-10)
  final String strength; // 'weak', 'medium', 'strong'
  final String reason;
  final TenGod? tenGod;

  const SupportPressureLevel({
    required this.age,
    this.date,
    required this.type,
    required this.value,
    required this.strength,
    required this.reason,
    this.tenGod,
  });

  bool get isSupport => type == 'support';
  bool get isPressure => type == 'pressure';

  factory SupportPressureLevel.fromJson(Map<String, dynamic> json) {
    return SupportPressureLevel(
      age: json['age'] as int,
      date: json['date'] as String?,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      strength: json['strength'] as String,
      reason: json['reason'] as String,
      tenGod: TenGod.fromLabel(json['tenGod'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'age': age,
    if (date != null) 'date': date,
    'type': type,
    'value': value,
    'strength': strength,
    'reason': reason,
    if (tenGod != null) 'tenGod': tenGod!.label,
  };

  @override
  List<Object?> get props => [age, date, type, value, strength, reason, tenGod];
}

/// Nine-dimensional analysis data from AI
class AnalysisData extends Equatable {
  final List<String> bazi; // [Year, Month, Day, Hour] pillars
  final String summary;
  final double summaryScore;
  final String personality;
  final double personalityScore;
  final String industry;
  final double industryScore;
  final String fengShui;
  final double fengShuiScore;
  final String wealth;
  final double wealthScore;
  final String marriage;
  final double marriageScore;
  final String health;
  final double healthScore;
  final String family;
  final double familyScore;
  final String crypto;
  final double cryptoScore;
  final String cryptoYear;
  final String cryptoStyle;
  final List<SupportPressureLevel>? supportPressureLevels;

  const AnalysisData({
    required this.bazi,
    required this.summary,
    required this.summaryScore,
    required this.personality,
    required this.personalityScore,
    required this.industry,
    required this.industryScore,
    required this.fengShui,
    required this.fengShuiScore,
    required this.wealth,
    required this.wealthScore,
    required this.marriage,
    required this.marriageScore,
    required this.health,
    required this.healthScore,
    required this.family,
    required this.familyScore,
    required this.crypto,
    required this.cryptoScore,
    required this.cryptoYear,
    required this.cryptoStyle,
    this.supportPressureLevels,
  });

  factory AnalysisData.fromJson(Map<String, dynamic> json) {
    return AnalysisData(
      bazi: (json['bazi'] as List).cast<String>(),
      summary: json['summary'] as String? ?? '',
      summaryScore: (json['summaryScore'] as num?)?.toDouble() ?? 0,
      personality: json['personality'] as String? ?? '',
      personalityScore: (json['personalityScore'] as num?)?.toDouble() ?? 0,
      industry: json['industry'] as String? ?? '',
      industryScore: (json['industryScore'] as num?)?.toDouble() ?? 0,
      fengShui: json['fengShui'] as String? ?? '',
      fengShuiScore: (json['fengShuiScore'] as num?)?.toDouble() ?? 0,
      wealth: json['wealth'] as String? ?? '',
      wealthScore: (json['wealthScore'] as num?)?.toDouble() ?? 0,
      marriage: json['marriage'] as String? ?? '',
      marriageScore: (json['marriageScore'] as num?)?.toDouble() ?? 0,
      health: json['health'] as String? ?? '',
      healthScore: (json['healthScore'] as num?)?.toDouble() ?? 0,
      family: json['family'] as String? ?? '',
      familyScore: (json['familyScore'] as num?)?.toDouble() ?? 0,
      crypto: json['crypto'] as String? ?? '',
      cryptoScore: (json['cryptoScore'] as num?)?.toDouble() ?? 0,
      cryptoYear: json['cryptoYear'] as String? ?? '',
      cryptoStyle: json['cryptoStyle'] as String? ?? '',
      supportPressureLevels: json['supportPressureLevels'] != null
          ? (json['supportPressureLevels'] as List)
                .map(
                  (e) =>
                      SupportPressureLevel.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'bazi': bazi,
    'summary': summary,
    'summaryScore': summaryScore,
    'personality': personality,
    'personalityScore': personalityScore,
    'industry': industry,
    'industryScore': industryScore,
    'fengShui': fengShui,
    'fengShuiScore': fengShuiScore,
    'wealth': wealth,
    'wealthScore': wealthScore,
    'marriage': marriage,
    'marriageScore': marriageScore,
    'health': health,
    'healthScore': healthScore,
    'family': family,
    'familyScore': familyScore,
    'crypto': crypto,
    'cryptoScore': cryptoScore,
    'cryptoYear': cryptoYear,
    'cryptoStyle': cryptoStyle,
    if (supportPressureLevels != null)
      'supportPressureLevels': supportPressureLevels!
          .map((e) => e.toJson())
          .toList(),
  };

  @override
  List<Object?> get props => [
    bazi,
    summary,
    summaryScore,
    personality,
    personalityScore,
    industry,
    industryScore,
    fengShui,
    fengShuiScore,
    wealth,
    wealthScore,
    marriage,
    marriageScore,
    health,
    healthScore,
    family,
    familyScore,
    crypto,
    cryptoScore,
    cryptoYear,
    cryptoStyle,
    supportPressureLevels,
  ];
}
