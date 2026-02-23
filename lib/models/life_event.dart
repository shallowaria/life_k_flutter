enum EventType { career, wealth, romance, health }

enum EventOutcome { smooth, difficult }

extension EventTypeLabel on EventType {
  String get label {
    switch (this) {
      case EventType.career:
        return '事业';
      case EventType.wealth:
        return '财富';
      case EventType.romance:
        return '感情';
      case EventType.health:
        return '健康';
    }
  }

  String get value => name;
}

extension EventOutcomeLabel on EventOutcome {
  String get label {
    switch (this) {
      case EventOutcome.smooth:
        return '顺利';
      case EventOutcome.difficult:
        return '不顺';
    }
  }

  String get value => name;
}

class LifeEvent {
  final String year;
  final String? month;
  final String? day;
  final String description;
  final EventType type;
  final EventOutcome outcome;

  const LifeEvent({
    required this.year,
    this.month,
    this.day,
    required this.description,
    required this.type,
    required this.outcome,
  });

  factory LifeEvent.fromJson(Map<String, dynamic> json) {
    return LifeEvent(
      year: json['year'] as String,
      month: json['month'] as String?,
      day: json['day'] as String?,
      description: json['description'] as String,
      type: EventType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => EventType.career,
      ),
      outcome: EventOutcome.values.firstWhere(
        (e) => e.value == json['outcome'],
        orElse: () => EventOutcome.smooth,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'year': year,
    if (month != null) 'month': month,
    if (day != null) 'day': day,
    'description': description,
    'type': type.value,
    'outcome': outcome.value,
  };

  LifeEvent copyWith({
    String? year,
    String? month,
    String? day,
    String? description,
    EventType? type,
    EventOutcome? outcome,
  }) {
    return LifeEvent(
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      description: description ?? this.description,
      type: type ?? this.type,
      outcome: outcome ?? this.outcome,
    );
  }

  /// Format like "2026年03月 | 事业 | 跳槽 | 结果：顺利"
  String toPromptString() {
    final datePart = month != null
        ? (day != null
              ? '$year年${month!.padLeft(2, '0')}月${day!.padLeft(2, '0')}日'
              : '$year年${month!.padLeft(2, '0')}月')
        : '$year年';
    return '$datePart | ${type.label} | $description | 结果：${outcome.label}';
  }
}
