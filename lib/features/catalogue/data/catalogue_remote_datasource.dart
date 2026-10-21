import 'package:dio/dio.dart';

import 'produit_catalogue.dart';

/// Catalogue public (`/catalogue`) : ouvert aux invités. Le jeton, s'il y en
/// a un, est ajouté par l'intercepteur commun et ne change rien aux données.
class CatalogueRemoteDataSource {
  final Dio dio;
  const CatalogueRemoteDataSource(this.dio);

  static List<ProduitCatalogue> _liste(dynamic brut) => (brut as List? ?? [])
      .whereType<Map>()
      .map((e) => ProduitCatalogue.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  /// [tri] : recents, populaires, prix_asc, prix_desc, promos.
  Future<PageProduits> produits({
    String? categorie,
    String? boutique,
    String? recherche,
    String? tri,
    bool promo = false,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await dio.get('/catalogue/produits', queryParameters: {
      if (categorie != null && categorie.isNotEmpty) 'categorie': categorie,
      if (boutique != null && boutique.isNotEmpty) 'boutique': boutique,
      if (recherche != null && recherche.trim().isNotEmpty) 'q': recherche.trim(),
      if (tri != null) 'tri': tri,
      if (promo) 'promo': '1',
      'page': page,
      'limit': limit,
    });
    final data = Map<String, dynamic>.from(res.data as Map);
    final pagination = data['pagination'] is Map ? data['pagination'] as Map : const {};
    return PageProduits(
      produits: _liste(data['produits']),
      total: (pagination['total'] is num) ? (pagination['total'] as num).toInt() : 0,
      pages: (pagination['pages'] is num) ? (pagination['pages'] as num).toInt() : 1,
      categorie: data['categorie'] is Map
          ? CategorieResume.fromJson(Map<String, dynamic>.from(data['categorie'] as Map))
          : null,
    );
  }

  /// Fiche d'un produit et ses produits similaires.
  Future<({ProduitCatalogue produit, List<ProduitCatalogue> similaires})> detail(String id) async {
    final res = await dio.get('/catalogue/produits/$id');
    final data = Map<String, dynamic>.from(res.data as Map);
    return (
      produit: ProduitCatalogue.fromJson(Map<String, dynamic>.from(data['produit'] as Map)),
      similaires: _liste(data['similaires']),
    );
  }

  /// Promotions en cours, celles qui se terminent le plus tôt d'abord.
  Future<List<ProduitCatalogue>> promotions({int limit = 30}) async {
    final res = await dio.get('/catalogue/promotions', queryParameters: {'limit': limit});
    return _liste((res.data as Map)['produits']);
  }

  /// Fiche publique d'une boutique.
  Future<Map<String, dynamic>> boutique(String id) async {
    final res = await dio.get('/catalogue/boutiques/$id');
    return Map<String, dynamic>.from((res.data as Map)['boutique'] as Map);
  }
}
