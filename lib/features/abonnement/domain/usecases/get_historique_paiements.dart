import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/paiement.dart';
import '../repositories/abonnement_repository.dart';
import 'package:saambiz/core/widgets/barre_pagination.dart';

class GetHistoriquePaiements {
  final AbonnementRepository repository;
  GetHistoriquePaiements(this.repository);

  Future<Either<Failure, (List<Paiement>, Pagination)>> call({int page = 1}) =>
      repository.historiquePaiements(page: page);
}
