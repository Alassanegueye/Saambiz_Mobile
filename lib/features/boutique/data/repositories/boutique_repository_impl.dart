import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/boutique.dart';
import '../../domain/repositories/boutique_repository.dart';
import '../datasources/boutique_remote_datasource.dart';

class BoutiqueRepositoryImpl implements BoutiqueRepository {
  final BoutiqueRemoteDataSource remoteDataSource;
  BoutiqueRepositoryImpl({required this.remoteDataSource});

  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Une erreur est survenue';
    }
    return e.toString();
  }

  int? _statusCode(Object e) => e is DioException ? e.response?.statusCode : null;

  @override
  Future<Either<Failure, Boutique>> getMaBoutique() async {
    try {
      return Right(await remoteDataSource.getMaBoutique());
    } catch (e) {
      return Left(ServerFailure(
          errorMessage: _errorMessage(e), statusCode: _statusCode(e)));
    }
  }

  @override
  Future<Either<Failure, Boutique>> creerBoutique({
    required String nom,
    required String description,
    required String localisation,
    required String telephone,
    List<String>? categories,
    String? logoPath,
  }) async {
    try {
      return Right(await remoteDataSource.creerBoutique(
        nom: nom,
        description: description,
        localisation: localisation,
        telephone: telephone,
        categories: categories,
        logoPath: logoPath,
      ));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, Boutique>> modifierBoutique({
    String? nom,
    String? description,
    String? localisation,
    String? telephone,
    List<String>? categories,
    String? logoPath,
  }) async {
    try {
      return Right(await remoteDataSource.modifierBoutique(
        nom: nom,
        description: description,
        localisation: localisation,
        telephone: telephone,
        categories: categories,
        logoPath: logoPath,
      ));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> pauseBoutique() async {
    try {
      await remoteDataSource.pauseBoutique();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> reactiverBoutique() async {
    try {
      await remoteDataSource.reactiverBoutique();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _errorMessage(e)));
    }
  }
}
