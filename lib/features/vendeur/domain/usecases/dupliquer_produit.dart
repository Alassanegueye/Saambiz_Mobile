import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/vendeur_produit_repository.dart';

class DupliquerProduitUsecase {
  final VendeurProduitRepository repository;
  DupliquerProduitUsecase(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.dupliquerProduit(id);
}
