import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/vendeur_produit_repository.dart';

/// Regroupe les données du tableau de bord vendeur (dashboard + stats liées).
///
/// Un seul usecase orchestre les appels dashboard/statistiques afin de garder
/// le domaine simple : il n'y a pour l'instant pas d'écran dédié, mais la
/// couche data/domain est prête pour en construire un.
class GetVendeurDashboard {
  final VendeurProduitRepository repository;
  GetVendeurDashboard(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call() =>
      repository.dashboard();

  Future<Either<Failure, Map<String, dynamic>>> statistiques() =>
      repository.statistiques();

  Future<Either<Failure, Map<String, dynamic>>> statistiquesVues() =>
      repository.statistiquesVues();

  Future<Either<Failure, Map<String, dynamic>>> nombreProduit() =>
      repository.nombreProduit();

  Future<Either<Failure, Map<String, dynamic>>> nombreProduitCategorie() =>
      repository.nombreProduitCategorie();
}
