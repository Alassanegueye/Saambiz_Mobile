import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/boutique_suivie.dart';
import '../repositories/favoris_repository.dart';

class GetBoutiquesSuivies {
  final FavorisRepository repository;
  GetBoutiquesSuivies(this.repository);

  Future<Either<Failure, List<BoutiqueSuivie>>> call() =>
      repository.mesBoutiquesSuivies();
}
