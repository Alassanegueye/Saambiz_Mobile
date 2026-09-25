import 'package:equatable/equatable.dart';

abstract class PromotionsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPromotionsActives extends PromotionsEvent {}

class LoadMesPromotions extends PromotionsEvent {}

class CreerPromotion extends PromotionsEvent {
  final String titre;
  final String description;
  final num prixPromo;
  final String dateDebut;
  final String dateFin;
  final String produitId;

  CreerPromotion({
    required this.titre,
    required this.description,
    required this.prixPromo,
    required this.dateDebut,
    required this.dateFin,
    required this.produitId,
  });

  @override
  List<Object?> get props =>
      [titre, description, prixPromo, dateDebut, dateFin, produitId];
}

class ModifierPromotion extends PromotionsEvent {
  final String id;
  final String? titre;
  final String? description;
  final num? prixPromo;
  final String? dateDebut;
  final String? dateFin;

  ModifierPromotion(
    this.id, {
    this.titre,
    this.description,
    this.prixPromo,
    this.dateDebut,
    this.dateFin,
  });

  @override
  List<Object?> get props => [id, titre, description, prixPromo, dateDebut, dateFin];
}

class SupprimerPromotion extends PromotionsEvent {
  final String id;
  SupprimerPromotion(this.id);
  @override
  List<Object?> get props => [id];
}
