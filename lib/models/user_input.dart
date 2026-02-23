import 'life_event.dart';

/// Gender type
enum Gender {
  male('Male'),
  female('Female');

  final String value;
  const Gender(this.value);

  String get displayName => this == Gender.male ? '乾造（男）' : '坤造（女）';
}

/// User input data for BaZi calculation
class UserInput {
  final String? name;
  final Gender gender;
  final String birthYear;
  final String? birthDate; // YYYY-MM-DD
  final String yearPillar;
  final String monthPillar;
  final String dayPillar;
  final String hourPillar;
  final String startAge;
  final List<LifeEvent>? lifeEvents;

  const UserInput({
    this.name,
    required this.gender,
    required this.birthYear,
    this.birthDate,
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.hourPillar,
    required this.startAge,
    this.lifeEvents,
  });

  factory UserInput.fromJson(Map<String, dynamic> json) {
    return UserInput(
      name: json['name'] as String?,
      gender: json['gender'] == 'Female' ? Gender.female : Gender.male,
      birthYear: json['birthYear'] as String,
      birthDate: json['birthDate'] as String?,
      yearPillar: json['yearPillar'] as String,
      monthPillar: json['monthPillar'] as String,
      dayPillar: json['dayPillar'] as String,
      hourPillar: json['hourPillar'] as String,
      startAge: json['startAge'] as String,
      lifeEvents: (json['lifeEvents'] as List<dynamic>?)
          ?.map((e) => LifeEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        'gender': gender.value,
        'birthYear': birthYear,
        if (birthDate != null) 'birthDate': birthDate,
        'yearPillar': yearPillar,
        'monthPillar': monthPillar,
        'dayPillar': dayPillar,
        'hourPillar': hourPillar,
        'startAge': startAge,
        if (lifeEvents != null && lifeEvents!.isNotEmpty)
          'lifeEvents': lifeEvents!.map((e) => e.toJson()).toList(),
      };

  UserInput copyWith({
    String? name,
    Gender? gender,
    String? birthYear,
    String? birthDate,
    String? yearPillar,
    String? monthPillar,
    String? dayPillar,
    String? hourPillar,
    String? startAge,
    List<LifeEvent>? lifeEvents,
  }) {
    return UserInput(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      birthDate: birthDate ?? this.birthDate,
      yearPillar: yearPillar ?? this.yearPillar,
      monthPillar: monthPillar ?? this.monthPillar,
      dayPillar: dayPillar ?? this.dayPillar,
      hourPillar: hourPillar ?? this.hourPillar,
      startAge: startAge ?? this.startAge,
      lifeEvents: lifeEvents ?? this.lifeEvents,
    );
  }
}
