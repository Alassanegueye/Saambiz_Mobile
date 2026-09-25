import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/vitrine.dart';
import '../repositories/vitrine_repository.dart';

/// Les secteurs proposés à la première question de l'assistant.
class GetSecteursVitrine {
  final VitrineRepository repository;
  GetSecteursVitrine(this.repository);

  Future<Either<Failure, List<SecteurVitrine>>> call() => repository.getSecteurs();
}
