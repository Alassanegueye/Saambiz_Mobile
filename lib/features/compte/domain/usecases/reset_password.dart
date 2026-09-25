import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/compte_repository.dart';

class ResetPassword {
  final CompteRepository repository;
  ResetPassword(this.repository);

  Future<Either<Failure, void>> call({
    required String email,
    required String code,
    required String nouveauMotDePasse,
  }) {
    return repository.resetPassword(
      email: email,
      code: code,
      nouveauMotDePasse: nouveauMotDePasse,
    );
  }
}
