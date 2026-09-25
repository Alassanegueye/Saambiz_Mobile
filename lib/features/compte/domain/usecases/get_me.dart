import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/domain/entities/user.dart';
import '../repositories/compte_repository.dart';

class GetMe {
  final CompteRepository repository;
  GetMe(this.repository);

  Future<Either<Failure, User>> call() => repository.getMe();
}
