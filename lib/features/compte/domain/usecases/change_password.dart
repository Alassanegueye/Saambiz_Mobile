import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/compte_repository.dart';

class ChangePassword {
  final CompteRepository repository;
  ChangePassword(this.repository);

  Future<Either<Failure, void>> call({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  }) {
    return repository.changePassword(
      ancienMotDePasse: ancienMotDePasse,
      nouveauMotDePasse: nouveauMotDePasse,
    );
  }
}
