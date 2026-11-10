import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/vitrine_repository.dart';

/// Retire le site public de la boutique.
///
/// `DELETE /vendeur/ma-vitrine` existait côté backend sans qu'aucun écran ne
/// l'appelle : un vendeur pouvait créer son site, pas le retirer.
///
/// La boutique n'est pas touchée : seul son site disparaît, et l'assistant
/// permet d'en regénérer un.
class SupprimerVitrine {
  final VitrineRepository repository;
  SupprimerVitrine(this.repository);

  Future<Either<Failure, void>> call() => repository.supprimerVitrine();
}
