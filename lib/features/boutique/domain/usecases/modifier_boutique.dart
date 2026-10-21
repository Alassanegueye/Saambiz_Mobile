import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/boutique.dart';
import '../repositories/boutique_repository.dart';

class ModifierBoutique {
  final BoutiqueRepository repository;
  ModifierBoutique(this.repository);

  Future<Either<Failure, Boutique>> call({
    String? nom,
    String? description,
    String? localisation,
    String? telephone,
    List<String>? categories,
    String? logoPath,
  }) {
    return repository.modifierBoutique(
      nom: nom,
      description: description,
      localisation: localisation,
      telephone: telephone,
      categories: categories,
      logoPath: logoPath,
    );
  }
}
