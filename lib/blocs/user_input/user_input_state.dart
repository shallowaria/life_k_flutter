import 'package:equatable/equatable.dart';
import '../../models/user_input.dart';

abstract class UserInputState extends Equatable {
  const UserInputState();
  @override
  List<Object?> get props => [];
}

class UserInputInitial extends UserInputState {
  const UserInputInitial();
}

class UserInputReady extends UserInputState {
  final UserInput input;
  const UserInputReady(this.input);
  @override
  List<Object?> get props => [input];
}
