import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../data/models/categorie_model.dart';
import '../repositories/vendeur_produit_repository.dart';

class GetCategoriesVendeur {
  final VendeurProduitRepository repository;
  GetCategoriesVendeur(this.repository);

  Future<Either<Failure, List<CategorieModel>>> call() =>
      repository.categories();
}
