import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/suivi_boutique.dart';
import '../repositories/favoris_repository.dart';

class GetStatutSuivi {
  final FavorisRepository repository;
  GetStatutSuivi(this.repository);

  Future<Either<Failure, SuiviBoutique>> call(String boutiqueId) =>
      repository.statutSuivi(boutiqueId);
}
