import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/vendeur_produit_repository.dart';

class AjouterImagesProduitUsecase {
  final VendeurProduitRepository repository;
  AjouterImagesProduitUsecase(this.repository);

  Future<Either<Failure, void>> call(String produitId, List<String> imagePaths) =>
      repository.ajouterImages(produitId, imagePaths);
}
