import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/boutique_repository.dart';

class ReactiverBoutique {
  final BoutiqueRepository repository;
  ReactiverBoutique(this.repository);

  Future<Either<Failure, void>> call() => repository.reactiverBoutique();
}
