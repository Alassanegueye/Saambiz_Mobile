import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/vitrine.dart';
import '../repositories/vitrine_repository.dart';

/// Reprise des réglages, une fois le site créé.
class ModifierVitrine {
  final VitrineRepository repository;
  ModifierVitrine(this.repository);

  Future<Either<Failure, Vitrine>> call(Map<String, dynamic> champs) =>
      repository.modifierVitrine(champs);
}
