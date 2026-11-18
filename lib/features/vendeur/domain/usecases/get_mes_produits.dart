import 'package:saambiz/core/widgets/barre_pagination.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/produit_vendeur.dart';
import '../repositories/vendeur_produit_repository.dart';

class GetMesProduits {
  final VendeurProduitRepository repository;
  GetMesProduits(this.repository);

  Future<Either<Failure, (List<ProduitVendeur>, Pagination)>> call({
    int page = 1,
  }) => repository.mesProduits(page: page);

  /// TOUS les produits, page après page.
  ///
  /// Pour les écrans qui doivent en PROPOSER UN À CHOISIR — les sections du
  /// site, le formulaire de promotion : un choix tronqué aux dix premiers
  /// n'est pas un choix, et la pagination le leur aurait coupé sans
  /// prévenir.
  ///
  /// Bornée à vingt pages : au-delà, ce n'est plus une liste de choix mais
  /// un catalogue, et il faudra une recherche côté serveur.
  Future<Either<Failure, List<ProduitVendeur>>> tous() async {
    final tous = <ProduitVendeur>[];
    for (var page = 1; page <= 20; page++) {
      final resultat = await repository.mesProduits(page: page);
      final panne = resultat.fold<Failure?>((f) => f, (_) => null);
      if (panne != null) return Left(panne);
      final (liste, pagination) = resultat.getOrElse(
        () => (const <ProduitVendeur>[], const Pagination()),
      );
      tous.addAll(liste);
      if (page >= pagination.pages) break;
    }
    return Right(tous);
  }
}
