import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/vitrine.dart';
import '../../domain/repositories/vitrine_repository.dart';
import '../datasources/vitrine_remote_datasource.dart';
import '../models/vitrine_model.dart';

class VitrineRepositoryImpl implements VitrineRepository {
  final VitrineRemoteDataSource remoteDataSource;
  VitrineRepositoryImpl({required this.remoteDataSource});

  /// Le message du serveur passe avant le nôtre : « Cette adresse est déjà
  /// prise par une autre boutique » est écrit pour le vendeur, « erreur 409 »
  /// ne lui apprend rien.
  String _message(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Une erreur est survenue';
    }
    return e.toString();
  }

  int? _statut(Object e) => e is DioException ? e.response?.statusCode : null;

  Future<Either<Failure, T>> _proteger<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _message(e), statusCode: _statut(e)));
    }
  }

  @override
  Future<Either<Failure, List<SecteurVitrine>>> getSecteurs() =>
      _proteger(() => remoteDataSource.getSecteurs());

  @override
  Future<Either<Failure, Vitrine>> getMaVitrine() =>
      _proteger(() => remoteDataSource.getMaVitrine());

  @override
  Future<Either<Failure, ResultatAnalyse>> analyserLogo({
    required String logoPath,
    String? secteur,
    String? activite,
  }) =>
      _proteger(() => remoteDataSource.analyserLogo(
            logoPath: logoPath,
            secteur: secteur,
            activite: activite,
          ));

  @override
  Future<Either<Failure, Vitrine>> genererVitrine({
    String? logoPath,
    required String secteur,
    String? activite,
    String? modele,
    String? accent,
    String? slogan,
    String? apropos,
    String? horaires,
    String? annonce,
    bool commande = true,
    bool paiementLivraison = true,
    bool active = true,
  }) =>
      _proteger(() => remoteDataSource.genererVitrine(
            logoPath: logoPath,
            secteur: secteur,
            activite: activite,
            modele: modele,
            accent: accent,
            slogan: slogan,
            apropos: apropos,
            horaires: horaires,
            annonce: annonce,
            commande: commande,
            paiementLivraison: paiementLivraison,
            active: active,
          ));

  @override
  Future<Either<Failure, Vitrine>> modifierVitrine(Map<String, dynamic> champs) =>
      _proteger(() => remoteDataSource.modifierVitrine(champs));
}
