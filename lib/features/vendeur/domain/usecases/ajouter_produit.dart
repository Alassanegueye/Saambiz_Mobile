import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/vendeur_produit_repository.dart';

class AjouterProduitUsecase {
  final VendeurProduitRepository repository;
  AjouterProduitUsecase(this.repository);

  Future<Either<Failure, void>> call({
    required String nom,
    required String description,
    required num prix,
    required int quantite,
    required String categorieId,
    String? imagePath,
  }) {
    return repository.ajouterProduit(
      nom: nom,
      description: description,
      prix: prix,
      quantite: quantite,
      categorieId: categorieId,
      imagePath: imagePath,
    );
  }
}
