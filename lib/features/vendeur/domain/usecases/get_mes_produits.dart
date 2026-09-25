import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/produit_vendeur.dart';
import '../repositories/vendeur_produit_repository.dart';

class GetMesProduits {
  final VendeurProduitRepository repository;
  GetMesProduits(this.repository);

  Future<Either<Failure, List<ProduitVendeur>>> call() =>
      repository.mesProduits();
}
