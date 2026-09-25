import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/domain/entities/user.dart';
import '../repositories/compte_repository.dart';

class ModifierProfil {
  final CompteRepository repository;
  ModifierProfil(this.repository);

  Future<Either<Failure, User>> call({
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
    String? photoProfilPath,
  }) {
    return repository.modifierProfil(
      nom: nom,
      prenom: prenom,
      adresse: adresse,
      telephone: telephone,
      photoProfilPath: photoProfilPath,
    );
  }
}
