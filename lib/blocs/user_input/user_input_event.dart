import 'package:equatable/equatable.dart';
import '../../models/user_input.dart';

abstract class UserInputEvent extends Equatable {
  const UserInputEvent();
  @override
  List<Object?> get props => [];
}

class UserInputUpdated extends UserInputEvent {
  final UserInput input;
  const UserInputUpdated(this.input);
  @override
  List<Object?> get props => [input];
}

class UserInputLoaded extends UserInputEvent {
  const UserInputLoaded();
}

class UserInputCleared extends UserInputEvent {
  const UserInputCleared();
}
