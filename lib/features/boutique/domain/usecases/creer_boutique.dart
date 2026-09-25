import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/boutique.dart';
import '../repositories/boutique_repository.dart';

class CreerBoutique {
  final BoutiqueRepository repository;
  CreerBoutique(this.repository);

  Future<Either<Failure, Boutique>> call({
    required String nom,
    required String description,
    required String localisation,
    required String telephone,
    String? logoPath,
  }) {
    return repository.creerBoutique(
      nom: nom,
      description: description,
      localisation: localisation,
      telephone: telephone,
      logoPath: logoPath,
    );
  }
}
