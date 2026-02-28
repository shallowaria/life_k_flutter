import 'package:flutter_test/flutter_test.dart';
import 'package:life_k/utils/validators.dart';

/// Builds a minimal valid chart data map with [count] points.
Map<String, dynamic> _validData({int count = 30}) {
  final chartData = List.generate(count, (i) {
    final age = i + 1;
    return {
      'age': age,
      'ganZhi': '甲子',
      'open': 5.0,
      'close': 6.0,
      'high': 7.0,
      'low': 4.0,
      'score': 5.5,
      'reason': 'test',
    };
  });
  return {
    'chartData': chartData,
    'analysis': {
      'bazi': ['甲子', '丙午', '戊申', '庚戌'],
      'summary': '',
      'summaryScore': 5.0,
      'personality': '',
      'personalityScore': 5.0,
      'industry': '',
      'industryScore': 5.0,
      'fengShui': '',
      'fengShuiScore': 5.0,
      'wealth': '',
      'wealthScore': 5.0,
      'marriage': '',
      'marriageScore': 5.0,
      'health': '',
      'healthScore': 5.0,
      'family': '',
      'familyScore': 5.0,
      'crypto': '',
      'cryptoScore': 5.0,
      'cryptoYear': '',
      'cryptoStyle': '',
    },
  };
}

void main() {
  group('validateChartData', () {
    test('returns null for valid data', () {
      expect(validateChartData(_validData()), isNull);
    });

    test('detects missing analysis field', () {
      final data = _validData()..remove('analysis');
      expect(validateChartData(data), contains('analysis'));
    });

    test('detects missing chartData field', () {
      final data = _validData()..remove('chartData');
      expect(validateChartData(data), contains('chartData'));
    });

    test('detects wrong chartData length', () {
      final error = validateChartData(_validData(count: 10));
      expect(error, contains('30'));
    });

    test('detects bazi with wrong element count', () {
      final data = _validData();
      (data['analysis'] as Map<String, dynamic>)['bazi'] = ['甲子', '丙午'];
      expect(validateChartData(data), contains('bazi'));
    });

    test('detects open out of range (> 10)', () {
      final data = _validData();
      (data['chartData'] as List)[0]['open'] = 11.0;
      expect(validateChartData(data), contains('open'));
    });

    test('detects close out of range (< 0)', () {
      final data = _validData();
      (data['chartData'] as List)[0]['close'] = -1.0;
      expect(validateChartData(data), contains('close'));
    });

    test('detects high < max(open, close)', () {
      final data = _validData();
      (data['chartData'] as List)[0]
        ..['open'] = 5.0
        ..['close'] = 6.0
        ..['high'] = 5.5; // below close
      expect(validateChartData(data), contains('high'));
    });

    test('detects low > min(open, close)', () {
      final data = _validData();
      (data['chartData'] as List)[0]
        ..['open'] = 5.0
        ..['close'] = 6.0
        ..['low'] = 5.5; // above open
      expect(validateChartData(data), contains('low'));
    });

    test('detects score out of range (> 10)', () {
      final data = _validData();
      (data['chartData'] as List)[0]['score'] = 11.0;
      expect(validateChartData(data), contains('score'));
    });

    test('detects age out of range (0)', () {
      final data = _validData();
      (data['chartData'] as List)[0]['age'] = 0;
      expect(validateChartData(data), contains('age'));
    });
  });

  group('validateBaziInput', () {
    String? validate({
      String yearPillar = '甲子',
      String monthPillar = '丙午',
      String dayPillar = '戊申',
      String hourPillar = '庚戌',
      String startAge = '5',
    }) {
      return validateBaziInput(
        yearPillar: yearPillar,
        monthPillar: monthPillar,
        dayPillar: dayPillar,
        hourPillar: hourPillar,
        startAge: startAge,
      );
    }

    test('returns null for valid input', () {
      expect(validate(), isNull);
    });

    test('detects invalid year pillar (Latin letters)', () {
      expect(validate(yearPillar: 'AB'), contains('年柱'));
    });

    test('detects year pillar with only one character', () {
      expect(validate(yearPillar: '甲'), contains('年柱'));
    });

    test('detects invalid month pillar', () {
      expect(validate(monthPillar: '12'), contains('月柱'));
    });

    test('detects invalid day pillar', () {
      expect(validate(dayPillar: ''), contains('日柱'));
    });

    test('detects invalid hour pillar', () {
      expect(validate(hourPillar: '庚戌壬'), contains('时柱'));
    });

    test('detects non-numeric startAge', () {
      expect(validate(startAge: 'abc'), contains('起运'));
    });

    test('detects startAge > 10', () {
      expect(validate(startAge: '11'), contains('起运'));
    });

    test('detects negative startAge', () {
      expect(validate(startAge: '-1'), contains('起运'));
    });

    test('accepts startAge = 0', () {
      expect(validate(startAge: '0'), isNull);
    });

    test('accepts startAge = 10', () {
      expect(validate(startAge: '10'), isNull);
    });
  });
}
