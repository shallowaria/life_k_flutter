import 'package:equatable/equatable.dart';
import '../../models/user_input.dart';

abstract class DestinyResultEvent extends Equatable {
  const DestinyResultEvent();
  @override
  List<Object?> get props => [];
}

class DestinyResultGenerate extends DestinyResultEvent {
  final UserInput userInput;
  const DestinyResultGenerate(this.userInput);
  @override
  List<Object?> get props => [userInput];
}

class DestinyResultLoaded extends DestinyResultEvent {
  const DestinyResultLoaded();
}

class DestinyResultCleared extends DestinyResultEvent {
  const DestinyResultCleared();
}
