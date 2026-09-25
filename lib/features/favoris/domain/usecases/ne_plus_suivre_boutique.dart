import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/favoris_repository.dart';

class NePlusSuivreBoutique {
  final FavorisRepository repository;
  NePlusSuivreBoutique(this.repository);

  Future<Either<Failure, void>> call(String boutiqueId) =>
      repository.nePlusSuivre(boutiqueId);
}
