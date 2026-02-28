import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:life_k/blocs/user_input/user_input_bloc.dart';
import 'package:life_k/blocs/user_input/user_input_event.dart';
import 'package:life_k/blocs/user_input/user_input_state.dart';
import 'package:life_k/models/user_input.dart';
import 'package:life_k/services/storage_service.dart';

class _MockStorageService extends Mock implements StorageService {}

const _testInput = UserInput(
  name: '张三',
  gender: Gender.male,
  birthYear: '1990',
  yearPillar: '庚午',
  monthPillar: '甲子',
  dayPillar: '丙午',
  hourPillar: '戊申',
  startAge: '3',
);

void main() {
  late _MockStorageService storageService;

  setUpAll(() {
    registerFallbackValue(_testInput);
  });

  setUp(() {
    storageService = _MockStorageService();
  });

  group('UserInputBloc', () {
    test('initial state is UserInputInitial', () {
      final bloc = UserInputBloc(storageService: storageService);
      expect(bloc.state, equals(const UserInputInitial()));
    });

    group('UserInputLoaded', () {
      blocTest<UserInputBloc, UserInputState>(
        'emits [UserInputReady] when storage has saved data',
        build: () {
          when(
            () => storageService.loadUserInput(),
          ).thenAnswer((_) async => _testInput);
          return UserInputBloc(storageService: storageService);
        },
        act: (bloc) => bloc.add(const UserInputLoaded()),
        expect: () => [UserInputReady(_testInput)],
      );

      blocTest<UserInputBloc, UserInputState>(
        'emits nothing when storage is empty',
        build: () {
          when(
            () => storageService.loadUserInput(),
          ).thenAnswer((_) async => null);
          return UserInputBloc(storageService: storageService);
        },
        act: (bloc) => bloc.add(const UserInputLoaded()),
        expect: () => <UserInputState>[],
      );
    });

    group('UserInputUpdated', () {
      blocTest<UserInputBloc, UserInputState>(
        'saves to storage and emits [UserInputReady]',
        build: () {
          when(
            () => storageService.saveUserInput(any()),
          ).thenAnswer((_) async {});
          return UserInputBloc(storageService: storageService);
        },
        act: (bloc) => bloc.add(const UserInputUpdated(_testInput)),
        expect: () => [UserInputReady(_testInput)],
        verify: (_) {
          verify(() => storageService.saveUserInput(_testInput)).called(1);
        },
      );
    });

    group('UserInputCleared', () {
      blocTest<UserInputBloc, UserInputState>(
        'clears storage and emits [UserInputInitial]',
        build: () {
          when(() => storageService.clearAll()).thenAnswer((_) async {});
          return UserInputBloc(storageService: storageService);
        },
        seed: () => UserInputReady(_testInput),
        act: (bloc) => bloc.add(const UserInputCleared()),
        expect: () => [const UserInputInitial()],
        verify: (_) {
          verify(() => storageService.clearAll()).called(1);
        },
      );
    });
  });
}
