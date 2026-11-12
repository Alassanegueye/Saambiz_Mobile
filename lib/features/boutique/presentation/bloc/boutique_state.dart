import 'package:equatable/equatable.dart';

import '../../domain/entities/boutique.dart';

abstract class BoutiqueState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BoutiqueInitial extends BoutiqueState {}

class BoutiqueLoading extends BoutiqueState {}

class BoutiqueLoaded extends BoutiqueState {
  final Boutique boutique;

  /// Message à confirmer à l'utilisateur après une action réussie.
  final String? succes;
  BoutiqueLoaded(this.boutique, {this.succes});
  @override
  List<Object?> get props => [boutique, succes];
}

/// Aucune boutique n'existe encore pour ce vendeur (404 côté backend).
class BoutiqueInexistante extends BoutiqueState {}

class BoutiqueError extends BoutiqueState {
  final String message;
  BoutiqueError(this.message);
  @override
  List<Object?> get props => [message];
}
