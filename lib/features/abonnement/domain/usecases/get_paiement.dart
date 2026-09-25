import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/paiement.dart';
import '../repositories/abonnement_repository.dart';

class GetPaiement {
  final AbonnementRepository repository;
  GetPaiement(this.repository);

  Future<Either<Failure, Paiement>> call(String id) => repository.getPaiement(id);
}
