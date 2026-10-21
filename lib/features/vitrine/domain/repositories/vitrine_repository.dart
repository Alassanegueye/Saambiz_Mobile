import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../data/models/vitrine_model.dart';
import '../entities/vitrine.dart';

/// Le site web public de la boutique.
///
/// Toutes les méthodes renvoient `Either<Failure, T>` : aucune exception ne
/// doit remonter jusqu'à un widget.
abstract class VitrineRepository {
  Future<Either<Failure, List<SecteurVitrine>>> getSecteurs();
  Future<Either<Failure, Vitrine>> getMaVitrine();

  Future<Either<Failure, ResultatAnalyse>> analyserLogo({
    required String logoPath,
    String? secteur,
    String? activite,
  });

  Future<Either<Failure, Vitrine>> genererVitrine({
    String? logoPath,
    required String secteur,
    String? activite,
    String? modele,
    String? accent,
    String? slogan,
    String? apropos,
    String? horaires,
    String? annonce,
    bool commande,
    bool paiementLivraison,
    bool active,
    Map<String, dynamic>? blocs,
  });

  Future<Either<Failure, Vitrine>> modifierVitrine(Map<String, dynamic> champs);
}
