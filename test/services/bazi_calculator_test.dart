import 'package:flutter_test/flutter_test.dart';
import 'package:life_k/models/user_input.dart';
import 'package:life_k/services/bazi_calculator.dart';
import 'package:life_k/constants/shi_chen.dart';

void main() {
  group('BaziCalculator.validateInput', () {
    final validDate = DateTime(1990, 5, 15);
    final validShiChen = shiChenList.first.name;

    test('returns null for valid input', () {
      expect(
        BaziCalculator.validateInput(
          birthDate: validDate,
          shiChenName: validShiChen,
          gender: Gender.male,
        ),
        isNull,
      );
    });

    test('detects null birthDate', () {
      expect(
        BaziCalculator.validateInput(
          birthDate: null,
          shiChenName: validShiChen,
          gender: Gender.male,
        ),
        contains('出生日期'),
      );
    });

    test('detects year before 1900', () {
      expect(
        BaziCalculator.validateInput(
          birthDate: DateTime(1899, 1, 1),
          shiChenName: validShiChen,
          gender: Gender.male,
        ),
        contains('1900'),
      );
    });

    test('detects year after 2100', () {
      expect(
        BaziCalculator.validateInput(
          birthDate: DateTime(2101, 1, 1),
          shiChenName: validShiChen,
          gender: Gender.male,
        ),
        contains('2100'),
      );
    });

    test('detects invalid shiChen name', () {
      expect(
        BaziCalculator.validateInput(
          birthDate: validDate,
          shiChenName: 'invalid_shiChen',
          gender: Gender.male,
        ),
        contains('时辰'),
      );
    });

    test('all valid shiChen names pass validation', () {
      for (final sc in shiChenList) {
        final result = BaziCalculator.validateInput(
          birthDate: validDate,
          shiChenName: sc.name,
          gender: Gender.male,
        );
        expect(result, isNull, reason: '${sc.name} should be valid');
      }
    });
  });

  group('getDaYunDirection', () {
    test('yang year + male → forward (顺行)', () {
      final dir = getDaYunDirection('甲子', Gender.male); // 甲 is yang
      expect(dir.isForward, isTrue);
      expect(dir.text, equals('顺行'));
    });

    test('yang year + female → reverse (逆行)', () {
      final dir = getDaYunDirection('甲子', Gender.female);
      expect(dir.isForward, isFalse);
      expect(dir.text, equals('逆行'));
    });

    test('yin year + male → reverse (逆行)', () {
      final dir = getDaYunDirection('乙丑', Gender.male); // 乙 is yin
      expect(dir.isForward, isFalse);
      expect(dir.text, equals('逆行'));
    });

    test('yin year + female → forward (顺行)', () {
      final dir = getDaYunDirection('乙丑', Gender.female);
      expect(dir.isForward, isTrue);
      expect(dir.text, equals('顺行'));
    });

    test('all yang stems are recognized', () {
      for (final stem in ['甲', '丙', '戊', '庚', '壬']) {
        final dir = getDaYunDirection('$stem子', Gender.male);
        expect(
          dir.isForward,
          isTrue,
          reason: '$stem should be yang → forward for male',
        );
      }
    });

    test('all yin stems are recognized', () {
      for (final stem in ['乙', '丁', '己', '辛', '癸']) {
        final dir = getDaYunDirection('$stem子', Gender.male);
        expect(
          dir.isForward,
          isFalse,
          reason: '$stem should be yin → reverse for male',
        );
      }
    });

    test('empty year pillar does not throw', () {
      expect(() => getDaYunDirection('', Gender.male), returnsNormally);
    });
  });

  group('BaziCalculator.calculate', () {
    test('returns BaziCalculationResult with non-empty pillar strings', () {
      final result = BaziCalculator.calculate(
        birthDate: DateTime(1990, 6, 15),
        shiChenName: '午时',
        gender: Gender.male,
      );

      expect(result.yearPillar, isNotEmpty);
      expect(result.monthPillar, isNotEmpty);
      expect(result.dayPillar, isNotEmpty);
      expect(result.hourPillar, isNotEmpty);
    });

    test('each pillar is exactly 2 CJK characters', () {
      final result = BaziCalculator.calculate(
        birthDate: DateTime(1990, 6, 15),
        shiChenName: '午时',
        gender: Gender.male,
      );

      for (final pillar in [
        result.yearPillar,
        result.monthPillar,
        result.dayPillar,
        result.hourPillar,
      ]) {
        expect(pillar.length, equals(2), reason: '$pillar should be 2 chars');
        for (final rune in pillar.runes) {
          // CJK Unified Ideographs: U+4E00–U+9FFF
          expect(rune, inInclusiveRange(0x4E00, 0x9FFF));
        }
      }
    });

    // 1984-04-15 is clearly in 甲子年 (Chinese New Year was 1984-02-02,
    // 立春 was ~1984-02-04, both well before April).
    test('1984-04-15 午时 produces 甲子 yearPillar', () {
      final result = BaziCalculator.calculate(
        birthDate: DateTime(1984, 4, 15),
        shiChenName: '午时',
        gender: Gender.male,
      );

      expect(result.yearPillar, equals('甲子'));
    });

    test('startAge is in valid string range "0"–"10"', () {
      for (final date in [
        DateTime(1980, 3, 1),
        DateTime(1990, 8, 15),
        DateTime(2000, 12, 25),
      ]) {
        final result = BaziCalculator.calculate(
          birthDate: date,
          shiChenName: '子时',
          gender: Gender.female,
        );
        final age = int.parse(result.startAge);
        expect(age, inInclusiveRange(0, 10), reason: 'date=$date');
      }
    });

    test('birthYear field matches the input year', () {
      final result = BaziCalculator.calculate(
        birthDate: DateTime(1995, 7, 20),
        shiChenName: '申时',
        gender: Gender.female,
      );

      expect(result.birthYear, equals('1995'));
    });

    test('different years produce different yearPillars', () {
      final r1984 = BaziCalculator.calculate(
        birthDate: DateTime(1984, 6, 1),
        shiChenName: '午时',
        gender: Gender.male,
      );
      final r1990 = BaziCalculator.calculate(
        birthDate: DateTime(1990, 6, 1),
        shiChenName: '午时',
        gender: Gender.male,
      );

      expect(r1984.yearPillar, isNot(equals(r1990.yearPillar)));
    });
  });
}
