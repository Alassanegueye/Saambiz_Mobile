import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/boutique.dart';

abstract class BoutiqueRepository {
  Future<Either<Failure, Boutique>> getMaBoutique();

  Future<Either<Failure, Boutique>> creerBoutique({
    required String nom,
    required String description,
    required String localisation,
    required String telephone,
    List<String>? categories,
    String? logoPath,
  });

  Future<Either<Failure, Boutique>> modifierBoutique({
    String? nom,
    String? description,
    String? localisation,
    String? telephone,
    List<String>? categories,
    String? logoPath,
  });

  Future<Either<Failure, void>> pauseBoutique();

  Future<Either<Failure, void>> reactiverBoutique();
}
