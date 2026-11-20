import '../../../../core/widgets/barre_pagination.dart';
import 'package:saambiz/core/utils/fichier_envoi.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../../core/demo/donnees_demo.dart';
import '../../../home/data/models/produit_model.dart';
import '../models/categorie_model.dart';
import '../../../../core/constants/api_endpoints.dart';

/// Accès aux endpoints VENDEUR de gestion des produits (.../vendeur/...).
/// Le token est ajouté automatiquement par l'intercepteur du Dio partagé.
/// Une page de produits du vendeur : la liste, et où elle se situe.
class PageProduitsVendeur {
  final List<ProduitModel> produits;
  final Pagination pagination;
  const PageProduitsVendeur(this.produits, this.pagination);
}

class VendeurProduitDataSource {
  final Dio dio;
  VendeurProduitDataSource(this.dio);

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      for (final k in ['produits', 'categories', 'data', 'items', 'results']) {
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

  /// Une page de produits du vendeur. Le serveur en rend dix.
  Future<PageProduitsVendeur> mesProduits({int page = 1}) async {
    if (modeDemo) {
      return PageProduitsVendeur(
        produitsDemo().map(ProduitModel.fromJson).toList(),
        const Pagination(),
      );
    }
    final res = await dio.get(
      VendeurProduitEndpoints.listeProduits,
      queryParameters: {'page': page},
    );
    return PageProduitsVendeur(
      _extractList(
        res.data,
      ).map((e) => ProduitModel.fromJson(e as Map<String, dynamic>)).toList(),
      Pagination.depuis(
        res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null,
      ),
    );
  }

  /// TOUS les produits du vendeur, page après page.
  ///
  /// Pour les écrans qui doivent en PROPOSER UN À CHOISIR — nouvelle
  /// commande, formulaire de promotion, sections du site : un choix tronqué
  /// aux dix premiers produits n'est pas un choix, et la pagination seule
  /// couperait la liste sans prévenir.
  ///
  /// Bornée à vingt pages : au-delà, ce n'est plus une liste de choix mais
  /// un catalogue, et il faudra une recherche côté serveur.
  Future<List<ProduitModel>> tousMesProduits() async {
    final tous = <ProduitModel>[];
    for (var page = 1; page <= 20; page++) {
      final recue = await mesProduits(page: page);
      tous.addAll(recue.produits);
      if (page >= recue.pagination.pages) break;
    }
    return tous;
  }

  Future<List<CategorieModel>> categories() async {
    final res = await dio.get(VendeurProduitEndpoints.categories);
    return _extractList(
      res.data,
    ).map((e) => CategorieModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Crée le produit et renvoie son identifiant (pour y joindre ensuite les
  /// photos supplémentaires), ou `null` si la réponse ne le donne pas.
  Future<String?> ajouterProduit({
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
      if (imagePath != null) 'image': await fichierAEnvoyer(imagePath),
    });
    final res = await dio.post(
      VendeurProduitEndpoints.ajouterProduit,
      data: form,
    );
    final data = res.data;
    if (data is Map && data['produit'] is Map) {
      return (data['produit'] as Map)['id']?.toString();
    }
    return null;
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
      if (imagePath != null) 'image': await fichierAEnvoyer(imagePath),
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
      'images': [for (final path in imagePaths) await fichierAEnvoyer(path)],
    });
    await dio.post(VendeurProduitEndpoints.images(produitId), data: form);
  }

  Future<void> supprimerImage(String produitId, String imageId) async {
    await dio.delete(VendeurProduitEndpoints.image(produitId, imageId));
  }

  // Dashboard / statistiques
  Future<Map<String, dynamic>> dashboard() async {
    if (modeDemo) return dashboardDemo();
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
    return _extractList(
      res.data,
    ).map((e) => ProduitModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
