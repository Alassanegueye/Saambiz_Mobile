import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/compte_repository.dart';

class DeleteAccount {
  final CompteRepository repository;
  DeleteAccount(this.repository);

  Future<Either<Failure, void>> call({String? motif}) {
    return repository.deleteAccount(motif: motif);
  }
}
