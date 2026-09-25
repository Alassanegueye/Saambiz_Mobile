import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/vendeur_produit_repository.dart';

class SupprimerImageProduitUsecase {
  final VendeurProduitRepository repository;
  SupprimerImageProduitUsecase(this.repository);

  Future<Either<Failure, void>> call(String produitId, String imageId) =>
      repository.supprimerImage(produitId, imageId);
}
