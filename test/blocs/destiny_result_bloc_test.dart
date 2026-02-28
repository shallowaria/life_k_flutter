import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:life_k/blocs/destiny_result/destiny_result_bloc.dart';
import 'package:life_k/blocs/destiny_result/destiny_result_event.dart';
import 'package:life_k/blocs/destiny_result/destiny_result_state.dart';
import 'package:life_k/models/analysis_data.dart';
import 'package:life_k/models/k_line_point.dart';
import 'package:life_k/models/life_destiny_result.dart';
import 'package:life_k/models/user_input.dart';
import 'package:life_k/services/destiny_api_service.dart';
import 'package:life_k/services/storage_service.dart';

class _MockDestinyApiService extends Mock implements DestinyApiService {}

class _MockStorageService extends Mock implements StorageService {}

// Minimal fixtures

const _testInput = UserInput(
  name: '李四',
  gender: Gender.female,
  birthYear: '1995',
  yearPillar: '乙亥',
  monthPillar: '丙子',
  dayPillar: '丁丑',
  hourPillar: '戊寅',
  startAge: '4',
);

KLinePoint _makePoint(int age) => KLinePoint(
  age: age,
  year: 2020 + age,
  ganZhi: '甲子',
  open: 5.0,
  close: 6.0,
  high: 7.0,
  low: 4.0,
  score: 5.5,
  reason: '测试',
);

final _testResult = LifeDestinyResult(
  chartData: List.generate(30, _makePoint),
  analysis: const AnalysisData(
    bazi: ['乙亥', '丙子', '丁丑', '戊寅'],
    summary: '测试摘要',
    summaryScore: 7.0,
    personality: '测试个性',
    personalityScore: 6.5,
    industry: '测试行业',
    industryScore: 7.5,
    fengShui: '测试风水',
    fengShuiScore: 5.0,
    wealth: '测试财富',
    wealthScore: 8.0,
    marriage: '测试婚姻',
    marriageScore: 6.0,
    health: '测试健康',
    healthScore: 7.0,
    family: '测试家庭',
    familyScore: 6.5,
    crypto: '测试加密',
    cryptoScore: 4.0,
    cryptoYear: '2028',
    cryptoStyle: '稳健',
  ),
);

void main() {
  late _MockDestinyApiService apiService;
  late _MockStorageService storageService;

  setUpAll(() {
    registerFallbackValue(_testInput);
    registerFallbackValue(_testResult);
  });

  setUp(() {
    apiService = _MockDestinyApiService();
    storageService = _MockStorageService();
  });

  group('DestinyResultBloc', () {
    test('initial state is DestinyResultInitial', () {
      final bloc = DestinyResultBloc(
        apiService: apiService,
        storageService: storageService,
      );
      expect(bloc.state, equals(const DestinyResultInitial()));
    });

    group('DestinyResultGenerate', () {
      blocTest<DestinyResultBloc, DestinyResultState>(
        'emits [Loading, Success] on successful API response',
        build: () {
          when(
            () => apiService.generateDestiny(any()),
          ).thenAnswer((_) async => _testResult);
          when(
            () => storageService.saveDestinyResult(any()),
          ).thenAnswer((_) async {});
          when(
            () => storageService.saveUserName(any()),
          ).thenAnswer((_) async {});
          return DestinyResultBloc(
            apiService: apiService,
            storageService: storageService,
          );
        },
        act: (bloc) => bloc.add(const DestinyResultGenerate(_testInput)),
        expect: () => [
          const DestinyResultLoading(),
          DestinyResultSuccess(result: _testResult, userName: '李四'),
        ],
        verify: (_) {
          verify(() => apiService.generateDestiny(_testInput)).called(1);
          verify(() => storageService.saveDestinyResult(_testResult)).called(1);
          verify(() => storageService.saveUserName('李四')).called(1);
        },
      );

      blocTest<DestinyResultBloc, DestinyResultState>(
        'uses "未命名" when name is null',
        build: () {
          when(
            () => apiService.generateDestiny(any()),
          ).thenAnswer((_) async => _testResult);
          when(
            () => storageService.saveDestinyResult(any()),
          ).thenAnswer((_) async {});
          when(
            () => storageService.saveUserName(any()),
          ).thenAnswer((_) async {});
          return DestinyResultBloc(
            apiService: apiService,
            storageService: storageService,
          );
        },
        act: (bloc) => bloc.add(
          const DestinyResultGenerate(
            UserInput(
              gender: Gender.male,
              birthYear: '1990',
              yearPillar: '庚午',
              monthPillar: '甲子',
              dayPillar: '丙午',
              hourPillar: '戊申',
              startAge: '3',
            ),
          ),
        ),
        expect: () => [
          const DestinyResultLoading(),
          DestinyResultSuccess(result: _testResult, userName: '未命名'),
        ],
      );

      blocTest<DestinyResultBloc, DestinyResultState>(
        'emits [Loading, Failure] when API throws',
        build: () {
          when(
            () => apiService.generateDestiny(any()),
          ).thenThrow(Exception('网络错误'));
          return DestinyResultBloc(
            apiService: apiService,
            storageService: storageService,
          );
        },
        act: (bloc) => bloc.add(const DestinyResultGenerate(_testInput)),
        expect: () => [
          const DestinyResultLoading(),
          isA<DestinyResultFailure>().having(
            (s) => s.error,
            'error',
            contains('网络错误'),
          ),
        ],
      );
    });

    group('DestinyResultLoaded', () {
      blocTest<DestinyResultBloc, DestinyResultState>(
        'emits [Success] when storage has saved result',
        build: () {
          when(
            () => storageService.loadDestinyResult(),
          ).thenAnswer((_) async => _testResult);
          when(
            () => storageService.loadUserName(),
          ).thenAnswer((_) async => '李四');
          return DestinyResultBloc(
            apiService: apiService,
            storageService: storageService,
          );
        },
        act: (bloc) => bloc.add(const DestinyResultLoaded()),
        expect: () => [
          DestinyResultSuccess(result: _testResult, userName: '李四'),
        ],
      );

      blocTest<DestinyResultBloc, DestinyResultState>(
        'emits nothing when storage is empty',
        build: () {
          when(
            () => storageService.loadDestinyResult(),
          ).thenAnswer((_) async => null);
          when(() => storageService.loadUserName()).thenAnswer((_) async => '');
          return DestinyResultBloc(
            apiService: apiService,
            storageService: storageService,
          );
        },
        act: (bloc) => bloc.add(const DestinyResultLoaded()),
        expect: () => <DestinyResultState>[],
      );
    });

    group('DestinyResultCleared', () {
      blocTest<DestinyResultBloc, DestinyResultState>(
        'emits [Initial] regardless of previous state',
        build: () => DestinyResultBloc(
          apiService: apiService,
          storageService: storageService,
        ),
        seed: () => DestinyResultSuccess(result: _testResult, userName: '李四'),
        act: (bloc) => bloc.add(const DestinyResultCleared()),
        expect: () => [const DestinyResultInitial()],
      );
    });
  });
}
