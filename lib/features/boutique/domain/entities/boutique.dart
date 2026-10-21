import 'package:equatable/equatable.dart';

/// Boutique du vendeur connecté (GET/POST/PUT /vendeur/*-boutique).
class Boutique extends Equatable {
  final String id;
  final String nom;
  final String description;
  final String localisation;
  final String? telephone;
  final String? logo;
  final bool enPause;

  /// Slugs des catégories (1 à 3), la principale en premier.
  final List<String> categories;

  const Boutique({
    required this.id,
    required this.nom,
    required this.description,
    required this.localisation,
    this.telephone,
    this.logo,
    this.enPause = false,
    this.categories = const [],
  });

  @override
  List<Object?> get props => [
        id,
        nom,
        description,
        localisation,
        telephone,
        logo,
        enPause,
        categories,
      ];
}
