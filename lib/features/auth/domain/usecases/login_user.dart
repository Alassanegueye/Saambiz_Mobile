import 'package:dartz/dartz.dart';
import 'package:saambiz/core/errors/failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUser {
  final AuthRepository repository;

  LoginUser(this.repository);

  /// identifiant = email OU téléphone
  /// motDePasse = mot de passe utilisateur
  Future<Either<Failure, User>> call(
      String identifiant,
      String motDePasse,
      ) async {
    return await repository.login(
      identifiant,
      motDePasse,
    );
  }
}
