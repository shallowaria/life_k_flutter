import 'package:equatable/equatable.dart';
import '../../models/life_destiny_result.dart';

abstract class DestinyResultState extends Equatable {
  const DestinyResultState();
  @override
  List<Object?> get props => [];
}

class DestinyResultInitial extends DestinyResultState {
  const DestinyResultInitial();
}

class DestinyResultLoading extends DestinyResultState {
  const DestinyResultLoading();
}

class DestinyResultSuccess extends DestinyResultState {
  final LifeDestinyResult result;
  final String userName;
  const DestinyResultSuccess({required this.result, required this.userName});
  @override
  List<Object?> get props => [result, userName];
}

class DestinyResultFailure extends DestinyResultState {
  final String error;
  final String? suggestion;
  const DestinyResultFailure({required this.error, this.suggestion});
  @override
  List<Object?> get props => [error, suggestion];
}
