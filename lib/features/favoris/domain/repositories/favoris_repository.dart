import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/boutique_suivie.dart';
import '../entities/suivi_boutique.dart';

/// Contrat de la couche données pour les abonnements aux boutiques.
///
/// La présentation ne connaît que cette interface : elle ignore qu'il y a du
/// Dio derrière, et aucune exception ne peut lui remonter — tout échec est un
/// [Failure] typé qu'elle sait afficher.
abstract class FavorisRepository {
  /// Ajoute la boutique aux favoris. La cloche reste désactivée.
  Future<Either<Failure, void>> suivre(String boutiqueId);

  Future<Either<Failure, void>> nePlusSuivre(String boutiqueId);

  Future<Either<Failure, List<BoutiqueSuivie>>> mesBoutiquesSuivies();

  /// Bascule la cloche et renvoie son état réel après l'opération.
  Future<Either<Failure, bool>> basculerCloche(String boutiqueId, bool active);

  Future<Either<Failure, SuiviBoutique>> statutSuivi(String boutiqueId);
}
