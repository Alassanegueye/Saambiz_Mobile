import 'package:equatable/equatable.dart';

import '../../domain/entities/abonnement.dart';
import '../../domain/entities/paiement.dart';

abstract class AbonnementState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AbonnementInitial extends AbonnementState {}

class AbonnementLoading extends AbonnementState {}

class AbonnementLoaded extends AbonnementState {
  final Abonnement abonnement;
  AbonnementLoaded(this.abonnement);
  @override
  List<Object?> get props => [abonnement];
}

class HistoriquePaiementsLoaded extends AbonnementState {
  final List<Paiement> paiements;
  HistoriquePaiementsLoaded(this.paiements);
  @override
  List<Object?> get props => [paiements];
}

class PaiementInitieAbonnement extends AbonnementState {
  final String? paymentUrl;
  final String? transactionId;
  PaiementInitieAbonnement({this.paymentUrl, this.transactionId});
  @override
  List<Object?> get props => [paymentUrl, transactionId];
}

class RenouvellementInitie extends AbonnementState {
  final String paiementId;
  RenouvellementInitie(this.paiementId);
  @override
  List<Object?> get props => [paiementId];
}

class AbonnementError extends AbonnementState {
  final String message;
  AbonnementError(this.message);
  @override
  List<Object?> get props => [message];
}
