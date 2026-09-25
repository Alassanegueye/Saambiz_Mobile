import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/vendeur_produit_repository.dart';

class ToggleDisponibiliteProduitUsecase {
  final VendeurProduitRepository repository;
  ToggleDisponibiliteProduitUsecase(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.toggleDisponibilite(id);
}
