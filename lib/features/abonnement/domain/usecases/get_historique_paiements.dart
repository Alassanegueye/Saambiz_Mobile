import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/paiement.dart';
import '../repositories/abonnement_repository.dart';

class GetHistoriquePaiements {
  final AbonnementRepository repository;
  GetHistoriquePaiements(this.repository);

  Future<Either<Failure, List<Paiement>>> call() => repository.historiquePaiements();
}
