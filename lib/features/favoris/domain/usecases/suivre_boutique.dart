import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/favoris_repository.dart';

/// Ajouter une boutique à ses favoris. La cloche reste désactivée : c'est un
/// second geste, volontaire.
class SuivreBoutique {
  final FavorisRepository repository;
  SuivreBoutique(this.repository);

  Future<Either<Failure, void>> call(String boutiqueId) =>
      repository.suivre(boutiqueId);
}
