import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../home/data/models/produit_model.dart';
import '../models/categorie_model.dart';
import '../../../../core/constants/api_endpoints.dart';

/// Accès aux endpoints VENDEUR de gestion des produits (.../vendeur/...).
/// Le token est ajouté automatiquement par l'intercepteur du Dio partagé.
class VendeurProduitDataSource {
  final Dio dio;
  VendeurProduitDataSource(this.dio);

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      for (final k in ['produits', 'data', 'items', 'results']) {
        if (raw[k] is List) return raw[k] as List;
      }
    }
    return const [];
  }

  /// Normalise une réponse "objet" du backend : certaines routes enveloppent
  /// le payload dans `data`, d'autres le renvoient tel quel.
  Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  Future<List<ProduitModel>> mesProduits() async {
    final res = await dio.get(VendeurProduitEndpoints.listeProduits);
    return _extractList(res.data)
        .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategorieModel>> categories() async {
    final res = await dio.get(VendeurProduitEndpoints.categories);
    return _extractList(res.data)
        .map((e) => CategorieModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> ajouterProduit({
    required String nom,
    required String description,
    required num prix,
    required int quantite,
    required String categorieId,
    String? imagePath,
    Map<String, dynamic>? attributs,
  }) async {
    final form = FormData.fromMap({
      'nom': nom,
      'description': description,
      'prix': prix,
      'quantite': quantite,
      'categorieId': categorieId,
      // Caractéristiques de la catégorie, en JSON (formulaire multipart).
      if (attributs != null) 'attributs': jsonEncode(attributs),
      if (imagePath != null)
        'image': await MultipartFile.fromFile(imagePath),
    });
    await dio.post(VendeurProduitEndpoints.ajouterProduit, data: form);
  }

  Future<void> modifierProduit({
    required String id,
    String? nom,
    String? description,
    num? prix,
    int? quantite,
    String? categorieId,
    String? imagePath,
    Map<String, dynamic>? attributs,
  }) async {
    final form = FormData.fromMap({
      if (attributs != null) 'attributs': jsonEncode(attributs),
      if (nom != null) 'nom': nom,
      if (description != null) 'description': description,
      if (prix != null) 'prix': prix,
      if (quantite != null) 'quantite': quantite,
      if (categorieId != null) 'categorieId': categorieId,
      if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
    });
    await dio.put(VendeurProduitEndpoints.modifierProduit(id), data: form);
  }

  Future<void> supprimerProduit(String id) async {
    await dio.delete(VendeurProduitEndpoints.supprimerProduit(id));
  }

  Future<void> toggleDisponibilite(String id) async {
    await dio.patch(VendeurProduitEndpoints.disponibilite(id));
  }

  /// Duplique un produit existant (POST /vendeur/produit/:id/dupliquer).
  Future<void> dupliquerProduit(String id) async {
    await dio.post(VendeurProduitEndpoints.dupliquer(id));
  }

  /// Upload de plusieurs images pour un produit (multipart, champ `images`).
  /// Contrat backend en cours de déploiement en parallèle.
  Future<void> ajouterImages(String produitId, List<String> imagePaths) async {
    final form = FormData.fromMap({
      'images': [
        for (final path in imagePaths) await MultipartFile.fromFile(path),
      ],
    });
    await dio.post(VendeurProduitEndpoints.images(produitId), data: form);
  }

  Future<void> supprimerImage(String produitId, String imageId) async {
    await dio.delete(VendeurProduitEndpoints.image(produitId, imageId));
  }

  // ── Dashboard / statistiques ──────────────────────────────────────────

  Future<Map<String, dynamic>> dashboard() async {
    final res = await dio.get(VendeurDashboardEndpoints.dashboard);
    return _extractMap(res.data);
  }

  Future<Map<String, dynamic>> statistiques() async {
    final res = await dio.get(VendeurDashboardEndpoints.statistiques);
    return _extractMap(res.data);
  }

  Future<Map<String, dynamic>> statistiquesVues() async {
    final res = await dio.get(VendeurDashboardEndpoints.statistiquesVues);
    return _extractMap(res.data);
  }

  Future<Map<String, dynamic>> nombreProduit() async {
    final res = await dio.get(VendeurDashboardEndpoints.nombreProduit);
    return _extractMap(res.data);
  }

  Future<Map<String, dynamic>> nombreProduitCategorie() async {
    final res = await dio.get(VendeurDashboardEndpoints.nombreProduitCategorie);
    return _extractMap(res.data);
  }

  Future<List<ProduitModel>> rechercheProduits(String recherche) async {
    final res = await dio.get(
      VendeurDashboardEndpoints.rechercheProduits,
      queryParameters: {'recherche': recherche},
    );
    return _extractList(res.data)
        .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
