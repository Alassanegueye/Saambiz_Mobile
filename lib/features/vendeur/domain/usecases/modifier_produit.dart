import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/vendeur_produit_repository.dart';

class ModifierProduitUsecase {
  final VendeurProduitRepository repository;
  ModifierProduitUsecase(this.repository);

  Future<Either<Failure, void>> call({
    required String id,
    String? nom,
    String? description,
    num? prix,
    int? quantite,
    String? categorieId,
    String? imagePath,
  }) {
    return repository.modifierProduit(
      id: id,
      nom: nom,
      description: description,
      prix: prix,
      quantite: quantite,
      categorieId: categorieId,
      imagePath: imagePath,
    );
  }
}
