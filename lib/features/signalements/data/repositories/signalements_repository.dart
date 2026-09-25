import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../datasources/signalements_remote_datasource.dart';
import '../models/signalement_model.dart';

/// Repository signalements — try/catch → Either<Failure, T> au-dessus du datasource.
class SignalementsRepository {
  final SignalementsRemoteDataSource remote;
  SignalementsRepository(this.remote);

  String _msg(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Erreur réseau';
    }
    return e.toString();
  }

  Future<Either<Failure, SignalementModel>> creerSignalement({
    required String type,
    required String raison,
    required String description,
    required String cibleId,
  }) async {
    try {
      return Right(await remote.creerSignalement(
          type: type, raison: raison, description: description, cibleId: cibleId));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, List<SignalementModel>>> mesSignalements() async {
    try {
      return Right(await remote.mesSignalements());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }
}
