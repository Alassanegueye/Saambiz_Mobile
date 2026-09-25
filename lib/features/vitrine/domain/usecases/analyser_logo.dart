import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../data/models/vitrine_model.dart';
import '../repositories/vitrine_repository.dart';

/// Analyse le logo sans rien enregistrer : couleurs, forme, site proposé.
///
/// Séparé de la création pour que le vendeur VOIE ce qui a été trouvé et
/// puisse changer de fichier avant de valider.
class AnalyserLogo {
  final VitrineRepository repository;
  AnalyserLogo(this.repository);

  Future<Either<Failure, ResultatAnalyse>> call({
    required String logoPath,
    String? secteur,
    String? activite,
  }) =>
      repository.analyserLogo(
        logoPath: logoPath,
        secteur: secteur,
        activite: activite,
      );
}
