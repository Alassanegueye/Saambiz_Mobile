import 'package:equatable/equatable.dart';

abstract class FavorisEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFavoris extends FavorisEvent {}

class AjouterFavori extends FavorisEvent {
  final String boutiqueId;
  AjouterFavori(this.boutiqueId);
  @override
  List<Object?> get props => [boutiqueId];
}

class SupprimerFavori extends FavorisEvent {
  final String boutiqueId;
  SupprimerFavori(this.boutiqueId);
  @override
  List<Object?> get props => [boutiqueId];
}

/// 🔔 Active/désactive la cloche de notifications d'une boutique suivie.
class ToggleClocheFavori extends FavorisEvent {
  final String boutiqueId;
  final bool active;
  ToggleClocheFavori(this.boutiqueId, this.active);
  @override
  List<Object?> get props => [boutiqueId, active];
}
