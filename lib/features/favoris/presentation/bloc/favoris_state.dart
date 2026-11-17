import 'package:saambiz/core/widgets/barre_pagination.dart';
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

  /// Où l'on est dans la liste. Une page unique replie la barre.
  final Pagination pagination;

  FavorisLoaded(
    this.boutiques, {
    this.succes,
    this.pagination = const Pagination(),
  });
  @override
  List<Object?> get props => [boutiques, succes];
}

class FavorisError extends FavorisState {
  final String message;
  FavorisError(this.message);
  @override
  List<Object?> get props => [message];
}
