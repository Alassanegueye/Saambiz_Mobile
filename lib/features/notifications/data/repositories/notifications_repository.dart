import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../../home/domain/entities/notification_model.dart';
import '../datasources/notifications_remote_datasource.dart';

/// Repository notifications — try/catch → Either<Failure, T> au-dessus du datasource.
class NotificationsRepository {
  final NotificationsRemoteDataSource remote;
  NotificationsRepository(this.remote);

  String _msg(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Erreur réseau';
    }
    return e.toString();
  }

  Future<Either<Failure, List<NotificationModel>>> notifications() async {
    try {
      return Right(await remote.notifications());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, int>> nombreNonLues() async {
    try {
      return Right(await remote.nombreNonLues());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, void>> marquerToutesLues() async {
    try {
      await remote.marquerToutesLues();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, void>> marquerLue(String id) async {
    try {
      await remote.marquerLue(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, void>> registerDeviceToken(
      {required String token, required String platform}) async {
    try {
      await remote.registerDeviceToken(token: token, platform: platform);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, void>> unregisterDeviceToken(String token) async {
    try {
      await remote.unregisterDeviceToken(token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }
}
