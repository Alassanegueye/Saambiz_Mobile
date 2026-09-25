import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/services/token_service.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Connexion uniquement.
///
/// L'inscription passe par `SignupRemoteDataSource` : elle se fait en deux
/// temps, l'adresse étant vérifiée par code avant que le compte n'existe.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> login(
      String identifiant,
      String motDePasse,
      ) async {
    try {
      final authResponse =
      await remoteDataSource.login(identifiant, motDePasse);

      await sl<TokenService>().setToken(authResponse.token);

      await sl<FlutterSecureStorage>().write(
        key: 'user_id',
        value: authResponse.user.id.toString(),
      );

      return Right(authResponse.user);
    } on DioException catch (e) {
      // Le message du backend passe avant le nôtre : « Identifiant ou mot de
      // passe incorrect » est écrit pour l'utilisateur, « erreur 401 » ne lui
      // apprend rien.
      String message = 'Une erreur est survenue';

      if (e.response?.data is Map &&
          e.response?.data['message'] != null) {
        message = e.response!.data['message'];
      } else if (e.message != null) {
        message = e.message!;
      }

      return Left(ServerFailure(
        errorMessage: message,
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }
}
