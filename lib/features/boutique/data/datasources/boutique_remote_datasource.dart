import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/boutique_vendeur_model.dart';

abstract class BoutiqueRemoteDataSource {
  Future<BoutiqueVendeurModel> getMaBoutique();

  Future<BoutiqueVendeurModel> creerBoutique({
    required String nom,
    required String description,
    required String localisation,
    required String telephone,
    String? categorie,
    List<String>? categories,
    String? slogan,
    String? logoPath,
  });

  Future<BoutiqueVendeurModel> modifierBoutique({
    String? nom,
    String? description,
    String? localisation,
    String? telephone,
    String? categorie,
    List<String>? categories,
    String? slogan,
    String? logoPath,
  });

  Future<void> pauseBoutique();

  /// État de la demande de badge « Boutique vérifiée ».
  Future<Map<String, dynamic>> statutVerification();

  /// Dépôt du dossier de vérification.
  Future<Map<String, dynamic>> soumettreVerification(
    Map<String, dynamic> dossier,
  );

  /// Fiche d'un abonné de la boutique.
  Future<Map<String, dynamic>> abonne(String id);

  Future<void> reactiverBoutique();
}

class BoutiqueRemoteDataSourceImpl implements BoutiqueRemoteDataSource {
  final Dio dio;
  BoutiqueRemoteDataSourceImpl(this.dio);

  @override
  Future<BoutiqueVendeurModel> getMaBoutique() async {
    final res = await dio.get(BoutiqueEndpoints.maBoutique);
    return BoutiqueVendeurModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<BoutiqueVendeurModel> creerBoutique({
    required String nom,
    required String description,
    required String localisation,
    required String telephone,
    String? categorie,
    List<String>? categories,
    String? slogan,
    String? logoPath,
  }) async {
    final form = FormData.fromMap({
      'nom': nom,
      'description': description,
      'localisation': localisation,
      'telephone': telephone,
      if (categorie != null) 'categorie': categorie,
      // 1 à 3 slugs ; envoyés en JSON car le formulaire est multipart.
      if (categories != null && categories.isNotEmpty)
        'categories': jsonEncode(categories),
      if (slogan != null) 'slogan': slogan,
      if (logoPath != null) 'logo': await MultipartFile.fromFile(logoPath),
    });
    final res = await dio.post(BoutiqueEndpoints.creerBoutique, data: form);
    return BoutiqueVendeurModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<BoutiqueVendeurModel> modifierBoutique({
    String? nom,
    String? description,
    String? localisation,
    String? telephone,
    String? categorie,
    List<String>? categories,
    String? slogan,
    String? logoPath,
  }) async {
    final form = FormData.fromMap({
      if (nom != null) 'nom': nom,
      if (description != null) 'description': description,
      if (localisation != null) 'localisation': localisation,
      if (telephone != null) 'telephone': telephone,
      if (categorie != null) 'categorie': categorie,
      // 1 à 3 slugs ; envoyés en JSON car le formulaire est multipart.
      if (categories != null && categories.isNotEmpty)
        'categories': jsonEncode(categories),
      if (slogan != null) 'slogan': slogan,
      if (logoPath != null) 'logo': await MultipartFile.fromFile(logoPath),
    });
    final res = await dio.put(BoutiqueEndpoints.modifierBoutique, data: form);
    return BoutiqueVendeurModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> pauseBoutique() async {
    await dio.patch(BoutiqueEndpoints.pause);
  }

  @override
  Future<void> reactiverBoutique() async {
    await dio.patch(BoutiqueEndpoints.reactiver);
  }

  // Les trois routes ci-dessous existaient côté backend sans être appelées :
  // le vendeur ne pouvait ni demander son badge, ni suivre sa demande, ni
  // ouvrir la fiche d'un abonné.

  @override
  Future<Map<String, dynamic>> statutVerification() async {
    final res = await dio.get(BoutiqueEndpoints.statutVerification);
    return _objet(res.data);
  }

  @override
  Future<Map<String, dynamic>> soumettreVerification(
    Map<String, dynamic> dossier,
  ) async {
    final res = await dio.post(
      BoutiqueEndpoints.soumettreVerification,
      data: dossier,
    );
    return _objet(res.data);
  }

  @override
  Future<Map<String, dynamic>> abonne(String id) async {
    final res = await dio.get(BoutiqueEndpoints.abonne(id));
    return _objet(res.data);
  }

  /// Certaines routes enveloppent la charge utile dans `data`, d'autres non.
  static Map<String, dynamic> _objet(dynamic brut) {
    if (brut is Map<String, dynamic>) {
      final data = brut['data'];
      if (data is Map<String, dynamic>) return data;
      return brut;
    }
    if (brut is Map) return Map<String, dynamic>.from(brut);
    return const {};
  }
}
