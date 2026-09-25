import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/compte_repository.dart';

class ForgotPassword {
  final CompteRepository repository;
  ForgotPassword(this.repository);

  Future<Either<Failure, void>> call(String email) =>
      repository.forgotPassword(email);
}
