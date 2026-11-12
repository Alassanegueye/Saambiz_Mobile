import 'package:equatable/equatable.dart';

import '../../domain/entities/boutique_suivie.dart';

abstract class FavorisState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FavorisInitial extends FavorisState {}

class FavorisLoading extends FavorisState {}

class FavorisLoaded extends FavorisState {
  final List<BoutiqueSuivie> boutiques;

  /// Message à confirmer à l'utilisateur après une action réussie (suivre,
  /// ne plus suivre, alertes). `null` pour un simple chargement.
  final String? succes;
  FavorisLoaded(this.boutiques, {this.succes});
  @override
  List<Object?> get props => [boutiques, succes];
}

class FavorisError extends FavorisState {
  final String message;
  FavorisError(this.message);
  @override
  List<Object?> get props => [message];
}
