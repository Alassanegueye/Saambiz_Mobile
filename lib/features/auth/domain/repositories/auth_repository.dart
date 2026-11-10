import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user.dart';
import '../../data/datasources/connexion_sociale_source.dart';

/// Connexion uniquement.
///
/// L'inscription passe par `SignupRemoteDataSource` : elle se fait en deux
/// temps, l'adresse étant vérifiée par code avant que le compte n'existe.
abstract class AuthRepository {
  Future<Either<Failure, User>> login(String identifiant, String motDePasse);

  /// Connexion Google / Apple, à partir de l'identité obtenue du fournisseur.
  Future<Either<Failure, User>> connexionSociale(IdentiteSociale identite);
}
