import 'package:saambiz/core/widgets/barre_pagination.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/boutique_suivie.dart';
import '../repositories/favoris_repository.dart';

class GetBoutiquesSuivies {
  final FavorisRepository repository;
  GetBoutiquesSuivies(this.repository);

  Future<Either<Failure, (List<BoutiqueSuivie>, Pagination)>> call({
    int page = 1,
  }) => repository.mesBoutiquesSuivies(page: page);
}
