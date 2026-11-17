import 'package:saambiz/core/widgets/barre_pagination.dart';
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

  /// Où l'on est dans la liste, et combien il reste.
  final Pagination pagination;

  SignalementsLoaded(this.signalements, [this.pagination = const Pagination()]);
  @override
  List<Object?> get props => [signalements, pagination.page, pagination.pages];
}

class SignalementEnvoye extends SignalementsState {}

class SignalementsError extends SignalementsState {
  final String message;
  SignalementsError(this.message);
  @override
  List<Object?> get props => [message];
}
