import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/destiny_api_service.dart';
import '../../services/storage_service.dart';
import 'destiny_result_event.dart';
import 'destiny_result_state.dart';

class DestinyResultBloc extends Bloc<DestinyResultEvent, DestinyResultState> {
  final DestinyApiService _apiService;
  final StorageService _storageService;

  DestinyResultBloc({
    required DestinyApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
       _storageService = storageService,
       super(const DestinyResultInitial()) {
    on<DestinyResultGenerate>(_onGenerate);
    on<DestinyResultLoaded>(_onLoaded);
    on<DestinyResultCleared>(_onCleared);
  }

  Future<void> _onGenerate(
    DestinyResultGenerate event,
    Emitter<DestinyResultState> emit,
  ) async {
    emit(const DestinyResultLoading());
    try {
      final result = await _apiService.generateDestiny(event.userInput);
      final userName = event.userInput.name ?? '未命名';

      await _storageService.saveDestinyResult(result);
      await _storageService.saveUserName(userName);

      emit(DestinyResultSuccess(result: result, userName: userName));
    } catch (e) {
      emit(
        DestinyResultFailure(error: e.toString(), suggestion: '请检查网络连接，或稍后重试'),
      );
    }
  }

  Future<void> _onLoaded(
    DestinyResultLoaded event,
    Emitter<DestinyResultState> emit,
  ) async {
    final result = await _storageService.loadDestinyResult();
    final userName = await _storageService.loadUserName();
    if (result != null) {
      emit(DestinyResultSuccess(result: result, userName: userName));
    }
  }

  Future<void> _onCleared(
    DestinyResultCleared event,
    Emitter<DestinyResultState> emit,
  ) async {
    emit(const DestinyResultInitial());
  }
}
