import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/produit_vendeur.dart';
import '../../domain/repositories/vendeur_produit_repository.dart';
import '../datasources/vendeur_produit_datasource.dart';
import '../models/categorie_model.dart';

class VendeurProduitRepositoryImpl implements VendeurProduitRepository {
  final VendeurProduitDataSource dataSource;
  VendeurProduitRepositoryImpl({required this.dataSource});

  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Une erreur est survenue';
    }
    return e.toString();
  }

  int? _statusCode(Object e) => e is DioException ? e.response?.statusCode : null;

  Failure _failure(Object e) =>
      ServerFailure(errorMessage: _errorMessage(e), statusCode: _statusCode(e));

  @override
  Future<Either<Failure, List<ProduitVendeur>>> mesProduits() async {
    try {
      return Right(await dataSource.mesProduits());
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, List<CategorieModel>>> categories() async {
    try {
      return Right(await dataSource.categories());
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, void>> ajouterProduit({
    required String nom,
    required String description,
    required num prix,
    required int quantite,
    required String categorieId,
    String? imagePath,
  }) async {
    try {
      await dataSource.ajouterProduit(
        nom: nom,
        description: description,
        prix: prix,
        quantite: quantite,
        categorieId: categorieId,
        imagePath: imagePath,
      );
      return const Right(null);
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, void>> modifierProduit({
    required String id,
    String? nom,
    String? description,
    num? prix,
    int? quantite,
    String? categorieId,
    String? imagePath,
  }) async {
    try {
      await dataSource.modifierProduit(
        id: id,
        nom: nom,
        description: description,
        prix: prix,
        quantite: quantite,
        categorieId: categorieId,
        imagePath: imagePath,
      );
      return const Right(null);
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, void>> supprimerProduit(String id) async {
    try {
      await dataSource.supprimerProduit(id);
      return const Right(null);
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, void>> toggleDisponibilite(String id) async {
    try {
      await dataSource.toggleDisponibilite(id);
      return const Right(null);
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, void>> dupliquerProduit(String id) async {
    try {
      await dataSource.dupliquerProduit(id);
      return const Right(null);
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, void>> ajouterImages(
      String produitId, List<String> imagePaths) async {
    try {
      await dataSource.ajouterImages(produitId, imagePaths);
      return const Right(null);
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, void>> supprimerImage(
      String produitId, String imageId) async {
    try {
      await dataSource.supprimerImage(produitId, imageId);
      return const Right(null);
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> dashboard() async {
    try {
      return Right(await dataSource.dashboard());
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> statistiques() async {
    try {
      return Right(await dataSource.statistiques());
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> statistiquesVues() async {
    try {
      return Right(await dataSource.statistiquesVues());
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> nombreProduit() async {
    try {
      return Right(await dataSource.nombreProduit());
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> nombreProduitCategorie() async {
    try {
      return Right(await dataSource.nombreProduitCategorie());
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, List<ProduitVendeur>>> rechercheProduits(
      String recherche) async {
    try {
      return Right(await dataSource.rechercheProduits(recherche));
    } catch (e) {
      return Left(_failure(e));
    }
  }
}
