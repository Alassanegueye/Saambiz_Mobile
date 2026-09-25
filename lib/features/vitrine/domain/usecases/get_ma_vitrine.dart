import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/vitrine.dart';
import '../repositories/vitrine_repository.dart';

/// L'état du site du vendeur : créé ou non, en ligne ou non, ses réglages.
class GetMaVitrine {
  final VitrineRepository repository;
  GetMaVitrine(this.repository);

  Future<Either<Failure, Vitrine>> call() => repository.getMaVitrine();
}
