import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/abonnement.dart';
import '../repositories/abonnement_repository.dart';

class GetMonAbonnement {
  final AbonnementRepository repository;
  GetMonAbonnement(this.repository);

  Future<Either<Failure, Abonnement>> call() => repository.monAbonnement();
}
