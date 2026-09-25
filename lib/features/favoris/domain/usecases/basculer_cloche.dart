import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/favoris_repository.dart';

/// Active ou coupe les notifications push d'une boutique suivie.
///
/// Renvoie l'état réel après l'opération, et non celui qu'on a demandé : si le
/// serveur refuse — quota de notifications du vendeur atteint, par exemple —
/// l'interface doit afficher l'état vrai, pas l'intention.
class BasculerCloche {
  final FavorisRepository repository;
  BasculerCloche(this.repository);

  Future<Either<Failure, bool>> call(String boutiqueId, {required bool active}) =>
      repository.basculerCloche(boutiqueId, active);
}
