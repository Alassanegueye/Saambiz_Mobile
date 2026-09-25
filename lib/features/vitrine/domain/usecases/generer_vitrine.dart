import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/vitrine.dart';
import '../repositories/vitrine_repository.dart';

/// Crée le site et le publie — dernière étape de l'assistant.
class GenererVitrine {
  final VitrineRepository repository;
  GenererVitrine(this.repository);

  Future<Either<Failure, Vitrine>> call({
    String? logoPath,
    required String secteur,
    String? activite,
    String? modele,
    String? accent,
    String? slogan,
    String? apropos,
    String? horaires,
    String? annonce,
    bool commande = true,
    bool paiementLivraison = true,
    bool active = true,
  }) =>
      repository.genererVitrine(
        logoPath: logoPath,
        secteur: secteur,
        activite: activite,
        modele: modele,
        accent: accent,
        slogan: slogan,
        apropos: apropos,
        horaires: horaires,
        annonce: annonce,
        commande: commande,
        paiementLivraison: paiementLivraison,
        active: active,
      );
}
