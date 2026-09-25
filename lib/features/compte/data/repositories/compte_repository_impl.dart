import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/compte_repository.dart';
import '../datasources/compte_remote_datasource.dart';

class CompteRepositoryImpl implements CompteRepository {
  final CompteRemoteDataSource remoteDataSource;

  CompteRepositoryImpl({required this.remoteDataSource});

  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Une erreur est survenue';
    }
    return e.toString();
  }

  @override
  Future<Either<Failure, User>> getMe() async {
    try {
      final user = await remoteDataSource.getMe();
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, User>> modifierProfil({
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
    String? photoProfilPath,
  }) async {
    try {
      final user = await remoteDataSource.modifierProfil(
        nom: nom,
        prenom: prenom,
        adresse: adresse,
        telephone: telephone,
        photoProfilPath: photoProfilPath,
      );
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  }) async {
    try {
      await remoteDataSource.changePassword(
        ancienMotDePasse: ancienMotDePasse,
        nouveauMotDePasse: nouveauMotDePasse,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await remoteDataSource.forgotPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String nouveauMotDePasse,
  }) async {
    try {
      await remoteDataSource.resetPassword(
        email: email,
        code: code,
        nouveauMotDePasse: nouveauMotDePasse,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount({String? motif}) async {
    try {
      await remoteDataSource.deleteAccount(motif: motif);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }
}
