import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/abonnement_repository.dart';

class Payer {
  final AbonnementRepository repository;
  Payer(this.repository);

  Future<Either<Failure, ({String? paymentUrl, String? transactionId})>> call({
    required num montant,
    required String numeroTelephone,
    required String methode,
  }) {
    return repository.payer(
      montant: montant,
      numeroTelephone: numeroTelephone,
      methode: methode,
    );
  }
}
