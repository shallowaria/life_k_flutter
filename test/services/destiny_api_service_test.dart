import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:life_k/models/k_line_point.dart';
import 'package:life_k/models/life_destiny_result.dart';
import 'package:life_k/models/user_input.dart';
import 'package:life_k/services/destiny_api_service.dart';

class _MockDio extends Mock implements Dio {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _testInput = UserInput(
  gender: Gender.male,
  birthYear: '1990',
  yearPillar: '庚午',
  monthPillar: '甲子',
  dayPillar: '丙午',
  hourPillar: '戊申',
  startAge: '3',
);

/// Wraps [text] in a minimal Anthropic API response envelope.
Map<String, dynamic> _anthropicWrap(String text) => {
  'content': [
    {'type': 'text', 'text': text},
  ],
};

/// Builds a valid 30-point LifeDestinyResult JSON string.
/// Pass [score] to test score normalisation (e.g. 75.0 should map to 7.5).
String _validDestinyJson({double score = 5.5}) {
  final points = List.generate(
    30,
    (i) => {
      'age': i + 1,
      'year': 2000 + i,
      'ganZhi': '甲子',
      'open': 5.0,
      'close': 6.0,
      'high': 7.0,
      'low': 4.0,
      'score': score,
      'reason': '平稳',
    },
  );
  return jsonEncode({
    'chartData': points,
    'analysis': {
      'bazi': ['甲子', '乙丑', '丙寅', '丁卯'],
      'summary': '总体平稳',
      'summaryScore': 7.0,
      'personality': '坚韧',
      'personalityScore': 6.5,
      'industry': '技术行业',
      'industryScore': 7.5,
      'fengShui': '宜北方',
      'fengShuiScore': 5.0,
      'wealth': '财运中等',
      'wealthScore': 6.0,
      'marriage': '婚姻稳定',
      'marriageScore': 7.0,
      'health': '注意肠胃',
      'healthScore': 6.5,
      'family': '家庭和睦',
      'familyScore': 7.5,
      'crypto': '谨慎参与',
      'cryptoScore': 4.0,
      'cryptoYear': '2028',
      'cryptoStyle': '稳健',
    },
  });
}

Response<dynamic> _mockResponse(dynamic data, int status) => Response(
  data: data,
  statusCode: status,
  requestOptions: RequestOptions(path: ''),
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _MockDio mockDio;
  late DestinyApiService service;

  setUpAll(() {
    registerFallbackValue(Options());
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockDio = _MockDio();
    service = DestinyApiService(
      baseUrl: 'https://api.anthropic.com',
      authToken: 'test-key',
      model: 'claude-test',
      dio: mockDio,
    );
  });

  /// Stubs [Dio.post] so that the n-th call (1-based) returns [handler(n)].
  void stubPost(Response<dynamic> Function(int call) handler) {
    var n = 0;
    when(
      () => mockDio.post<dynamic>(
        any(),
        options: any(named: 'options'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => handler(++n));
  }

  group('DestinyApiService.generateDestiny', () {
    test(
      'returns LifeDestinyResult with 30 points on valid 200 response',
      () async {
        stubPost(
          (_) => _mockResponse(_anthropicWrap(_validDestinyJson()), 200),
        );

        final result = await service.generateDestiny(_testInput);

        expect(result, isA<LifeDestinyResult>());
        expect(result.chartData.length, equals(30));
        expect(result.chartData.first.age, equals(1));
        expect(result.analysis.summary, equals('总体平稳'));
      },
    );

    test('normalizes score > 10 into [0, 10] range', () async {
      // score=75.0 → normalizeScore divides by 10 → 7.5
      stubPost(
        (_) =>
            _mockResponse(_anthropicWrap(_validDestinyJson(score: 75.0)), 200),
      );

      final result = await service.generateDestiny(_testInput);

      for (final point in result.chartData) {
        expect(point.score, inInclusiveRange(0.0, 10.0));
      }
      expect(result.chartData.first.score, closeTo(7.5, 0.001));
    });

    test('throws immediately on 4xx — Dio.post called exactly once', () async {
      stubPost((_) => _mockResponse({'error': 'Unauthorized'}, 401));

      await expectLater(
        service.generateDestiny(_testInput),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API 错误 (401)'),
          ),
        ),
      );

      verify(
        () => mockDio.post<dynamic>(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test(
      'retries on AI refusal keyword and succeeds on second call',
      () async {
        stubPost(
          (call) => call == 1
              ? _mockResponse(
                  _anthropicWrap(
                    'I apologize, I cannot assist with fortune-telling content.',
                  ),
                  200,
                )
              : _mockResponse(_anthropicWrap(_validDestinyJson()), 200),
        );

        final result = await service.generateDestiny(_testInput);

        expect(result, isA<LifeDestinyResult>());
        verify(
          () => mockDio.post<dynamic>(
            any(),
            options: any(named: 'options'),
            data: any(named: 'data'),
          ),
        ).called(2);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });

  group('DestinyApiService.generateYearlyAdvice', () {
    test('returns year-keyed ActionAdvice map on valid response', () async {
      final adviceJson = jsonEncode({
        'yearAdvice': [
          {
            'year': 2025,
            'suggestions': ['积极进取', '把握机遇', '稳步前行'],
            'warnings': ['谨防小人', '注意财务'],
            'basis': '甲子流年',
            'scenario': '事业上升期',
          },
          {
            'year': 2026,
            'suggestions': ['调整方向', '蓄势待发', '夯实基础'],
            'warnings': ['避免冲动', '健康注意'],
          },
        ],
      });
      stubPost((_) => _mockResponse(_anthropicWrap(adviceJson), 200));

      final points = [
        KLinePoint(
          age: 1,
          year: 2025,
          ganZhi: '甲子',
          open: 5.0,
          close: 6.0,
          high: 7.0,
          low: 4.0,
          score: 5.5,
          reason: '平稳',
        ),
        KLinePoint(
          age: 2,
          year: 2026,
          ganZhi: '乙丑',
          open: 4.5,
          close: 5.5,
          high: 6.5,
          low: 3.5,
          score: 5.0,
          reason: '调整',
        ),
      ];

      final result = await service.generateYearlyAdvice(
        input: _testInput,
        allPoints: points,
      );

      expect(result, isA<Map<int, ActionAdvice>>());
      expect(result.length, equals(2));
      expect(result[2025]!.suggestions.length, equals(3));
      expect(result[2025]!.warnings.length, equals(2));
      expect(result[2025]!.basis, equals('甲子流年'));
      expect(result[2026]!.basis, isNull);
    });

    test(
      'returns empty map and skips API call when all points have advice',
      () async {
        const advice = ActionAdvice(
          suggestions: ['已有建议一', '已有建议二', '已有建议三'],
          warnings: ['已有警告一', '已有警告二'],
        );
        final point = KLinePoint(
          age: 1,
          year: 2025,
          ganZhi: '甲子',
          open: 5.0,
          close: 6.0,
          high: 7.0,
          low: 4.0,
          score: 5.5,
          reason: '平稳',
          actionAdvice: advice,
        );

        final result = await service.generateYearlyAdvice(
          input: _testInput,
          allPoints: [point],
        );

        expect(result, isEmpty);
        verifyNever(
          () => mockDio.post<dynamic>(
            any(),
            options: any(named: 'options'),
            data: any(named: 'data'),
          ),
        );
      },
    );
  });
}
