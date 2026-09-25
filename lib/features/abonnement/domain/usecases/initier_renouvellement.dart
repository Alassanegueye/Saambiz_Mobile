import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/abonnement_repository.dart';

class InitierRenouvellement {
  final AbonnementRepository repository;
  InitierRenouvellement(this.repository);

  Future<Either<Failure, String>> call({num? montant}) =>
      repository.initierRenouvellement(montant: montant);
}
