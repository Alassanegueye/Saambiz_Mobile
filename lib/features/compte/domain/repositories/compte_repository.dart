import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/domain/entities/user.dart';

abstract class CompteRepository {
  Future<Either<Failure, User>> getMe();

  Future<Either<Failure, User>> modifierProfil({
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
    String? photoProfilPath,
  });

  Future<Either<Failure, void>> changePassword({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  });

  Future<Either<Failure, void>> forgotPassword(String email);

  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String nouveauMotDePasse,
  });

  Future<Either<Failure, void>> deleteAccount({String? motif});
}
