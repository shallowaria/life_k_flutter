import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_k/models/analysis_data.dart';
import 'package:life_k/models/k_line_point.dart';
import 'package:life_k/models/life_destiny_result.dart';
import 'package:life_k/models/user_input.dart';
import 'package:life_k/services/storage_service.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _testUserInput = UserInput(
  name: '张三',
  gender: Gender.male,
  birthYear: '1990',
  yearPillar: '庚午',
  monthPillar: '甲子',
  dayPillar: '丙午',
  hourPillar: '戊申',
  startAge: '3',
);

KLinePoint _makePoint(int i) => KLinePoint(
  age: i + 1,
  year: 2000 + i,
  ganZhi: '甲子',
  open: 5.0,
  close: 6.0,
  high: 7.0,
  low: 4.0,
  score: 5.5,
  reason: '平稳',
);

final _testResult = LifeDestinyResult(
  chartData: List.generate(30, _makePoint),
  analysis: const AnalysisData(
    bazi: ['甲子', '乙丑', '丙寅', '丁卯'],
    summary: '总体平稳',
    summaryScore: 7.0,
    personality: '坚韧',
    personalityScore: 6.5,
    industry: '技术行业',
    industryScore: 7.5,
    fengShui: '宜北方',
    fengShuiScore: 5.0,
    wealth: '财运中等',
    wealthScore: 6.0,
    marriage: '婚姻稳定',
    marriageScore: 7.0,
    health: '注意肠胃',
    healthScore: 6.5,
    family: '家庭和睦',
    familyScore: 7.5,
    crypto: '谨慎参与',
    cryptoScore: 4.0,
    cryptoYear: '2028',
    cryptoStyle: '稳健',
  ),
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late StorageService svc;

  setUp(() {
    // Reset SharedPreferences to empty in-memory store before each test.
    SharedPreferences.setMockInitialValues({});
    svc = StorageService();
  });

  group('StorageService — UserInput', () {
    test(
      'saveUserInput + loadUserInput roundtrip preserves all fields',
      () async {
        await svc.saveUserInput(_testUserInput);
        final loaded = await svc.loadUserInput();

        expect(loaded, equals(_testUserInput));
      },
    );

    test('loadUserInput returns null when nothing saved', () async {
      final loaded = await svc.loadUserInput();
      expect(loaded, isNull);
    });
  });

  group('StorageService — DestinyResult', () {
    test(
      'saveDestinyResult + loadDestinyResult roundtrip preserves chart and analysis',
      () async {
        await svc.saveDestinyResult(_testResult);
        final loaded = await svc.loadDestinyResult();

        expect(loaded, equals(_testResult));
        expect(loaded!.chartData.length, equals(30));
        expect(loaded.analysis.summary, equals('总体平稳'));
      },
    );

    test('loadDestinyResult returns null when nothing saved', () async {
      final loaded = await svc.loadDestinyResult();
      expect(loaded, isNull);
    });
  });

  group('StorageService — UserName', () {
    test('saveUserName + loadUserName roundtrip', () async {
      await svc.saveUserName('李四');
      final loaded = await svc.loadUserName();
      expect(loaded, equals('李四'));
    });

    test('loadUserName returns "未命名" fallback when nothing saved', () async {
      final loaded = await svc.loadUserName();
      expect(loaded, equals('未命名'));
    });
  });

  group('StorageService — clearAll', () {
    test('removes UserInput, DestinyResult and UserName', () async {
      await svc.saveUserInput(_testUserInput);
      await svc.saveDestinyResult(_testResult);
      await svc.saveUserName('张三');

      await svc.clearAll();

      expect(await svc.loadUserInput(), isNull);
      expect(await svc.loadDestinyResult(), isNull);
      expect(await svc.loadUserName(), equals('未命名'));
    });
  });
}
