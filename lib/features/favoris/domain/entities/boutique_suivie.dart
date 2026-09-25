import 'package:equatable/equatable.dart';

/// Une boutique suivie par l'acheteur, telle que l'interface l'affiche.
///
/// Entité de domaine : pas de `fromJson`, pas de dépendance à Dio. C'est ce
/// qui permet de tester la couche présentation sans réseau, et de changer de
/// format d'API sans toucher aux pages.
class BoutiqueSuivie extends Equatable {
  final String id;
  final String nom;
  final String? logo;
  final String? localisation;

  /// Notifications push actives pour cette boutique.
  ///
  /// Distinct du fait de suivre : on peut suivre une boutique sans vouloir
  /// être réveillé à chaque promotion. C'est le défaut.
  final bool clocheActive;

  const BoutiqueSuivie({
    required this.id,
    required this.nom,
    this.logo,
    this.localisation,
    this.clocheActive = false,
  });

  BoutiqueSuivie copyWith({bool? clocheActive}) => BoutiqueSuivie(
        id: id,
        nom: nom,
        logo: logo,
        localisation: localisation,
        clocheActive: clocheActive ?? this.clocheActive,
      );

  @override
  List<Object?> get props => [id, nom, logo, localisation, clocheActive];
}
