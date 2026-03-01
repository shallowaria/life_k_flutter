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
      final msg = e.toString();
      final String suggestion;
      if (msg.contains('网络超时') || msg.contains('超时')) {
        suggestion = '网络请求超时，请检查网络连接后重试';
      } else if (msg.contains('API 错误 (4')) {
        suggestion = '请求参数有误，请检查出生信息后重试';
      } else if (msg.contains('解析')) {
        suggestion = '数据解析失败，请重新生成';
      } else if (msg.contains('网络错误') || msg.contains('网络连接')) {
        suggestion = '网络连接失败，请检查网络设置后重试';
      } else {
        suggestion = 'API 服务暂时不可用，请稍后重试';
      }
      emit(DestinyResultFailure(error: msg, suggestion: suggestion));
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
