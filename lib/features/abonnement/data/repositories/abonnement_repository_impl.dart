import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/abonnement.dart';
import '../../domain/entities/paiement.dart';
import '../../domain/repositories/abonnement_repository.dart';
import '../datasources/abonnement_remote_datasource.dart';

class AbonnementRepositoryImpl implements AbonnementRepository {
  final AbonnementRemoteDataSource remoteDataSource;
  AbonnementRepositoryImpl({required this.remoteDataSource});

  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Une erreur est survenue';
    }
    return e.toString();
  }

  @override
  Future<Either<Failure, Abonnement>> monAbonnement() async {
    try {
      return Right(await remoteDataSource.monAbonnement());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, String>> initierRenouvellement({num? montant}) async {
    try {
      return Right(await remoteDataSource.initierRenouvellement(montant: montant));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<Paiement>>> historiquePaiements() async {
    try {
      return Right(await remoteDataSource.historiquePaiementsAbonnement());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, ({String? paymentUrl, String? transactionId})>> payer({
    required num montant,
    required String numeroTelephone,
    required String methode,
  }) async {
    try {
      final res = await remoteDataSource.payer(
        montant: montant,
        numeroTelephone: numeroTelephone,
        methode: methode,
      );
      return Right((paymentUrl: res['paymentUrl'], transactionId: res['transactionId']));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, Paiement>> getPaiement(String id) async {
    try {
      return Right(await remoteDataSource.getPaiement(id));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<Paiement>>> historiquePaiementGeneral() async {
    try {
      return Right(await remoteDataSource.historiquePaiementGeneral());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }
}
