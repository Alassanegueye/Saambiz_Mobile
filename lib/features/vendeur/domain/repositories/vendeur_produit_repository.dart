import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../data/models/categorie_model.dart';
import '../entities/produit_vendeur.dart';

/// Contrat du domaine pour la gestion des produits + dashboard côté vendeur.
abstract class VendeurProduitRepository {
  Future<Either<Failure, List<ProduitVendeur>>> mesProduits();

  Future<Either<Failure, List<CategorieModel>>> categories();

  Future<Either<Failure, void>> ajouterProduit({
    required String nom,
    required String description,
    required num prix,
    required int quantite,
    required String categorieId,
    String? imagePath,
  });

  Future<Either<Failure, void>> modifierProduit({
    required String id,
    String? nom,
    String? description,
    num? prix,
    int? quantite,
    String? categorieId,
    String? imagePath,
  });

  Future<Either<Failure, void>> supprimerProduit(String id);

  Future<Either<Failure, void>> toggleDisponibilite(String id);

  Future<Either<Failure, void>> dupliquerProduit(String id);

  Future<Either<Failure, void>> ajouterImages(
      String produitId, List<String> imagePaths);

  Future<Either<Failure, void>> supprimerImage(
      String produitId, String imageId);

  // ── Dashboard / statistiques ──────────────────────────────────────────

  Future<Either<Failure, Map<String, dynamic>>> dashboard();

  Future<Either<Failure, Map<String, dynamic>>> statistiques();

  Future<Either<Failure, Map<String, dynamic>>> statistiquesVues();

  Future<Either<Failure, Map<String, dynamic>>> nombreProduit();

  Future<Either<Failure, Map<String, dynamic>>> nombreProduitCategorie();

  Future<Either<Failure, List<ProduitVendeur>>> rechercheProduits(
      String recherche);
}
