import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/storage_service.dart';
import 'user_input_event.dart';
import 'user_input_state.dart';

class UserInputBloc extends Bloc<UserInputEvent, UserInputState> {
  final StorageService _storageService;

  UserInputBloc({required StorageService storageService})
    : _storageService = storageService,
      super(const UserInputInitial()) {
    on<UserInputLoaded>(_onLoaded);
    on<UserInputUpdated>(_onUpdated);
    on<UserInputCleared>(_onCleared);
  }

  Future<void> _onLoaded(
    UserInputLoaded event,
    Emitter<UserInputState> emit,
  ) async {
    final input = await _storageService.loadUserInput();
    if (input != null) {
      emit(UserInputReady(input));
    }
  }

  Future<void> _onUpdated(
    UserInputUpdated event,
    Emitter<UserInputState> emit,
  ) async {
    await _storageService.saveUserInput(event.input);
    emit(UserInputReady(event.input));
  }

  Future<void> _onCleared(
    UserInputCleared event,
    Emitter<UserInputState> emit,
  ) async {
    await _storageService.clearAll();
    emit(const UserInputInitial());
  }
}
