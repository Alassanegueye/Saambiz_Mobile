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

  /// Retire le site public de la boutique.
  ///
  /// La boutique reste, seul son site disparaît : le vendeur peut en
  /// regénérer un ensuite avec l'assistant.
  Future<Either<Failure, void>> supprimerVitrine();

  /// Photos du haut du site, qui y défilent en boucle. Chaque geste est
  /// enregistré tout de suite et renvoie le site à jour ; l'ajout y joint la
  /// phrase du serveur (« 3 photos ajoutées… »).
  Future<Either<Failure, ({Vitrine vitrine, String message})>> ajouterPhotos(
    List<String> chemins,
  );
  Future<Either<Failure, Vitrine>> retirerPhoto(String id);
  Future<Either<Failure, Vitrine>> ordonnerPhotos(List<String> ids);
}
