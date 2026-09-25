import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/boutique.dart';
import '../repositories/boutique_repository.dart';

class GetMaBoutique {
  final BoutiqueRepository repository;
  GetMaBoutique(this.repository);

  Future<Either<Failure, Boutique>> call() => repository.getMaBoutique();
}
