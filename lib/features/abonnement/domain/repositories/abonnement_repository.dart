import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/abonnement.dart';
import '../entities/paiement.dart';

abstract class AbonnementRepository {
  Future<Either<Failure, Abonnement>> monAbonnement();

  /// Retourne l'id du paiement initié pour le renouvellement.
  Future<Either<Failure, String>> initierRenouvellement({num? montant});

  Future<Either<Failure, List<Paiement>>> historiquePaiements();

  /// Retourne l'URL de paiement (Orange Money / Wave) + id de transaction.
  Future<Either<Failure, ({String? paymentUrl, String? transactionId})>> payer({
    required num montant,
    required String numeroTelephone,
    required String methode,
  });

  Future<Either<Failure, Paiement>> getPaiement(String id);

  Future<Either<Failure, List<Paiement>>> historiquePaiementGeneral();
}
