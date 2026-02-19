import 'package:lunar/lunar.dart';
import '../models/user_input.dart';
import '../constants/shi_chen.dart';

class BaziCalculationResult {
  final String yearPillar;
  final String monthPillar;
  final String dayPillar;
  final String hourPillar;
  final String startAge;
  final String birthYear;

  const BaziCalculationResult({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.hourPillar,
    required this.startAge,
    required this.birthYear,
  });
}

class BaziCalculator {
  /// Calculate BaZi (Eight Characters) from birth info
  static BaziCalculationResult calculate({
    required DateTime birthDate,
    required String shiChenName,
    required Gender gender,
  }) {
    final hour = getHourFromShiChen(shiChenName);

    // Create Solar object
    final solar = Solar.fromYmdHms(
      birthDate.year,
      birthDate.month,
      birthDate.day,
      hour,
      0,
      0,
    );

    // Get Lunar and Eight Characters
    final lunar = solar.getLunar();
    final eightChar = lunar.getEightChar();

    final yearPillar = eightChar.getYear();
    final monthPillar = eightChar.getMonth();
    final dayPillar = eightChar.getDay();
    final hourPillar = eightChar.getTime();

    final startAge = _calculateStartAge(eightChar, gender);

    return BaziCalculationResult(
      yearPillar: yearPillar,
      monthPillar: monthPillar,
      dayPillar: dayPillar,
      hourPillar: hourPillar,
      startAge: startAge.toString(),
      birthYear: birthDate.year.toString(),
    );
  }

  /// Calculate start age for Da Yun (大运起运年龄)
  static int _calculateStartAge(EightChar eightChar, Gender gender) {
    try {
      // lunar package uses 1 for male, 0 for female
      final genderCode = gender == Gender.male ? 1 : 0;
      final yun = eightChar.getYun(genderCode);

      final startYear = yun.getStartYear();
      final startMonth = yun.getStartMonth();

      // Convert to virtual age: years + 1 (virtual age starts at 1)
      var startAge = startYear + 1;
      if (startMonth >= 6) {
        startAge += 1;
      }

      return startAge.clamp(0, 10);
    } catch (_) {
      return 3; // Default
    }
  }

  /// Validate BaZi calculation input
  static String? validateInput({
    required DateTime? birthDate,
    required String shiChenName,
    required Gender gender,
  }) {
    if (birthDate == null) return '出生日期无效';

    final year = birthDate.year;
    if (year < 1900 || year > 2100) return '出生年份必须在 1900-2100 年之间';

    final validShiChens = shiChenList.map((s) => s.name).toList();
    if (!validShiChens.contains(shiChenName)) return '时辰选择无效';

    return null; // Valid
  }
}

/// Get Da Yun direction (顺行/逆行)
/// 阳男/阴女顺行, 阴男/阳女逆行
({bool isForward, String text}) getDaYunDirection(
    String yearPillar, Gender gender) {
  final firstChar = yearPillar.trim().isNotEmpty ? yearPillar.trim()[0] : '';
  const yangStems = ['甲', '丙', '戊', '庚', '壬'];
  final isYangYear = yangStems.contains(firstChar);

  final isForward = gender == Gender.male ? isYangYear : !isYangYear;
  return (isForward: isForward, text: isForward ? '顺行' : '逆行');
}
