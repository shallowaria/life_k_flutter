/// Ten Gods (十神) type used for identifying auspicious/inauspicious influences
enum TenGod {
  biJian('比肩'),
  jieCai('劫财'),
  shiShen('食神'),
  shangGuan('伤官'),
  pianCai('偏财'),
  zhengCai('正财'),
  qiSha('七杀'),
  zhengGuan('正官'),
  pianYin('偏印'),
  zhengYin('正印');

  final String label;
  const TenGod(this.label);

  static TenGod? fromLabel(String? label) {
    if (label == null) return null;
    for (final v in values) {
      if (v.label == label) return v;
    }
    return null;
  }
}

/// Energy score breakdown
class EnergyScore {
  final double total; // 0-10
  final double monthCoefficient;
  final double dayRelation;
  final double hourFluctuation;
  final bool isBelowSupport;

  const EnergyScore({
    required this.total,
    required this.monthCoefficient,
    required this.dayRelation,
    required this.hourFluctuation,
    required this.isBelowSupport,
  });

  factory EnergyScore.fromJson(Map<String, dynamic> json) {
    return EnergyScore(
      total: (json['total'] as num).toDouble(),
      monthCoefficient: (json['monthCoefficient'] as num).toDouble(),
      dayRelation: (json['dayRelation'] as num).toDouble(),
      hourFluctuation: (json['hourFluctuation'] as num).toDouble(),
      isBelowSupport: json['isBelowSupport'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'monthCoefficient': monthCoefficient,
        'dayRelation': dayRelation,
        'hourFluctuation': hourFluctuation,
        'isBelowSupport': isBelowSupport,
      };
}

/// Action advice for key years
class ActionAdvice {
  final List<String> suggestions; // 3 suggestions
  final List<String> warnings; // 2 warnings
  final String? basis;
  final String? scenario;

  const ActionAdvice({
    required this.suggestions,
    required this.warnings,
    this.basis,
    this.scenario,
  });

  factory ActionAdvice.fromJson(Map<String, dynamic> json) {
    return ActionAdvice(
      suggestions: (json['suggestions'] as List).cast<String>(),
      warnings: (json['warnings'] as List).cast<String>(),
      basis: json['basis'] as String?,
      scenario: json['scenario'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'suggestions': suggestions,
        'warnings': warnings,
        if (basis != null) 'basis': basis,
        if (scenario != null) 'scenario': scenario,
      };
}

/// Single K-line data point representing one year of life fortune
class KLinePoint {
  final int age;
  final int year;
  final String ganZhi; // 流年干支
  final String? daYun; // 当前大运
  final double open;
  final double close;
  final double high;
  final double low;
  final double score; // 0-10
  final String reason;
  final TenGod? tenGod;
  final EnergyScore? energyScore;
  final ActionAdvice? actionAdvice;

  const KLinePoint({
    required this.age,
    required this.year,
    required this.ganZhi,
    this.daYun,
    required this.open,
    required this.close,
    required this.high,
    required this.low,
    required this.score,
    required this.reason,
    this.tenGod,
    this.energyScore,
    this.actionAdvice,
  });

  bool get isUp => close >= open;

  factory KLinePoint.fromJson(Map<String, dynamic> json) {
    return KLinePoint(
      age: json['age'] as int,
      year: json['year'] as int,
      ganZhi: json['ganZhi'] as String,
      daYun: json['daYun'] as String?,
      open: (json['open'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      score: (json['score'] as num).toDouble(),
      reason: json['reason'] as String,
      tenGod: TenGod.fromLabel(json['tenGod'] as String?),
      energyScore: json['energyScore'] != null
          ? EnergyScore.fromJson(json['energyScore'] as Map<String, dynamic>)
          : null,
      actionAdvice: json['actionAdvice'] != null
          ? ActionAdvice.fromJson(
              json['actionAdvice'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'age': age,
        'year': year,
        'ganZhi': ganZhi,
        if (daYun != null) 'daYun': daYun,
        'open': open,
        'close': close,
        'high': high,
        'low': low,
        'score': score,
        'reason': reason,
        if (tenGod != null) 'tenGod': tenGod!.label,
        if (energyScore != null) 'energyScore': energyScore!.toJson(),
        if (actionAdvice != null) 'actionAdvice': actionAdvice!.toJson(),
      };
}
