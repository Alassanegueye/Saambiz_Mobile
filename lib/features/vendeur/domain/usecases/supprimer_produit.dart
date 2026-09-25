import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/vendeur_produit_repository.dart';

class SupprimerProduitUsecase {
  final VendeurProduitRepository repository;
  SupprimerProduitUsecase(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.supprimerProduit(id);
}
