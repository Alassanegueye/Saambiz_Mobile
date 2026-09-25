import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../datasources/messagerie_remote_datasource.dart';
import '../models/message_model.dart';

/// Repository messagerie — try/catch → Either<Failure, T> au-dessus du datasource.
class MessagerieRepository {
  final MessagerieRemoteDataSource remote;
  MessagerieRepository(this.remote);

  String _msg(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Erreur réseau';
    }
    return e.toString();
  }

  Future<Either<Failure, MessageModel>> envoyerMessage(
      {required String destinataireId, required String contenu}) async {
    try {
      return Right(await remote.envoyerMessage(
          destinataireId: destinataireId, contenu: contenu));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, List<ConversationModel>>> conversations() async {
    try {
      return Right(await remote.conversations());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, List<MessageModel>>> historique(String userId) async {
    try {
      return Right(await remote.historique(userId));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, void>> marquerLu(String messageId) async {
    try {
      await remote.marquerLu(messageId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, int>> nombreNonLus() async {
    try {
      return Right(await remote.nombreNonLus());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }
}
