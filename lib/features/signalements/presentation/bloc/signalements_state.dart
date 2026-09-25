import 'package:equatable/equatable.dart';

import '../../data/models/signalement_model.dart';

abstract class SignalementsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SignalementsInitial extends SignalementsState {}

class SignalementsLoading extends SignalementsState {}

class SignalementsLoaded extends SignalementsState {
  final List<SignalementModel> signalements;
  SignalementsLoaded(this.signalements);
  @override
  List<Object?> get props => [signalements];
}

class SignalementEnvoye extends SignalementsState {}

class SignalementsError extends SignalementsState {
  final String message;
  SignalementsError(this.message);
  @override
  List<Object?> get props => [message];
}
