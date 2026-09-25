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
  BoutiqueLoaded(this.boutique);
  @override
  List<Object?> get props => [boutique];
}

/// Aucune boutique n'existe encore pour ce vendeur (404 côté backend).
class BoutiqueInexistante extends BoutiqueState {}

class BoutiqueError extends BoutiqueState {
  final String message;
  BoutiqueError(this.message);
  @override
  List<Object?> get props => [message];
}
