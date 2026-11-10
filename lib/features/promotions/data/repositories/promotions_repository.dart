import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../datasources/promotions_remote_datasource.dart';
import '../models/promotion_model.dart';
import '../../../../core/errors/message_erreur.dart';

/// Repository promotions, try/catch → Either<Failure, T> au-dessus du datasource.
class PromotionsRepository {
  final PromotionsRemoteDataSource remote;
  PromotionsRepository(this.remote);

  String _msg(Object e) => messageErreurReseau(e);

  Future<Either<Failure, List<PromotionModel>>> promotionsActives() async {
    try {
      return Right(await remote.promotionsActives());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, List<PromotionModel>>> mesPromotions() async {
    try {
      return Right(await remote.mesPromotions());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, PromotionModel>> creerPromotion({
    required String titre,
    required String description,
    required num prixPromo,
    required String dateDebut,
    required String dateFin,
    required String produitId,
  }) async {
    try {
      return Right(
        await remote.creerPromotion(
          titre: titre,
          description: description,
          prixPromo: prixPromo,
          dateDebut: dateDebut,
          dateFin: dateFin,
          produitId: produitId,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, PromotionModel>> modifierPromotion(
    String id, {
    String? titre,
    String? description,
    num? prixPromo,
    String? dateDebut,
    String? dateFin,
  }) async {
    try {
      return Right(
        await remote.modifierPromotion(
          id,
          titre: titre,
          description: description,
          prixPromo: prixPromo,
          dateDebut: dateDebut,
          dateFin: dateFin,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, void>> supprimerPromotion(String id) async {
    try {
      await remote.supprimerPromotion(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }
}
