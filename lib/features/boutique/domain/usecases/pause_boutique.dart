import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/boutique_repository.dart';

class PauseBoutique {
  final BoutiqueRepository repository;
  PauseBoutique(this.repository);

  Future<Either<Failure, void>> call() => repository.pauseBoutique();
}
