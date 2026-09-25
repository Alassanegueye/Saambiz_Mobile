import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/boutique_suivie.dart';
import '../../domain/entities/suivi_boutique.dart';
import '../../domain/repositories/favoris_repository.dart';
import '../datasources/favoris_remote_datasource.dart';

/// Implémentation du contrat de domaine.
///
/// Deux responsabilités, et seulement deux : convertir les exceptions du
/// datasource en [Failure] typés, et convertir les modèles de transport en
/// entités de domaine. Aucune règle métier ici.
class FavorisRepositoryImpl implements FavorisRepository {
  final FavorisRemoteDataSource remote;
  FavorisRepositoryImpl(this.remote);

  /// Traduit une exception en panne exploitable par l'interface.
  ///
  /// Le message du serveur est privilégié quand il existe : il est rédigé pour
  /// l'utilisateur, là où un message Dio parle de sockets et de timeouts.
  Failure _panne(Object e) {
    if (e is DioException) {
      final donnees = e.response?.data;
      if (donnees is Map && donnees['message'] != null) {
        return ServerFailure(errorMessage: donnees['message'].toString());
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return ServerFailure(
          errorMessage: 'Connexion impossible. Vérifiez votre réseau.',
        );
      }
      return ServerFailure(errorMessage: e.message ?? 'Erreur réseau');
    }
    return ServerFailure(errorMessage: e.toString());
  }

  @override
  Future<Either<Failure, void>> suivre(String boutiqueId) async {
    try {
      await remote.ajouter(boutiqueId);
      return const Right(null);
    } catch (e) {
      return Left(_panne(e));
    }
  }

  @override
  Future<Either<Failure, void>> nePlusSuivre(String boutiqueId) async {
    try {
      await remote.supprimer(boutiqueId);
      return const Right(null);
    } catch (e) {
      return Left(_panne(e));
    }
  }

  @override
  Future<Either<Failure, List<BoutiqueSuivie>>> mesBoutiquesSuivies() async {
    try {
      final modeles = await remote.mesFavoris();
      return Right(modeles
          .map((m) => BoutiqueSuivie(
                id: m.id,
                nom: m.nom,
                logo: m.logo,
                localisation: m.localisation,
                clocheActive: m.clocheActive,
              ))
          .toList());
    } catch (e) {
      return Left(_panne(e));
    }
  }

  @override
  Future<Either<Failure, bool>> basculerCloche(String boutiqueId, bool active) async {
    try {
      return Right(await remote.toggleCloche(boutiqueId, active));
    } catch (e) {
      return Left(_panne(e));
    }
  }

  @override
  Future<Either<Failure, SuiviBoutique>> statutSuivi(String boutiqueId) async {
    try {
      final brut = await remote.statutSuivi(boutiqueId);
      return Right(SuiviBoutique(
        boutiqueId: boutiqueId,
        suivi: brut['suivi'] ?? false,
        clocheActive: brut['clocheActive'] ?? false,
      ));
    } catch (e) {
      return Left(_panne(e));
    }
  }
}
