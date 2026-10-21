import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/vitrine.dart';
import '../models/vitrine_model.dart';

abstract class VitrineRemoteDataSource {
  Future<List<SecteurVitrine>> getSecteurs();
  Future<VitrineModel> getMaVitrine();

  /// Analyse un logo sans rien enregistrer.
  Future<ResultatAnalyse> analyserLogo({
    required String logoPath,
    String? secteur,
    String? activite,
  });

  /// Crée le site et le publie — dernière étape de l'assistant.
  Future<VitrineModel> genererVitrine({
    String? logoPath,
    required String secteur,
    String? activite,
    String? modele,
    String? accent,
    String? slogan,
    String? apropos,
    String? horaires,
    String? annonce,
    bool commande,
    bool paiementLivraison,
    bool active,
    Map<String, dynamic>? blocs,
  });

  /// Reprise des réglages, une fois le site créé.
  Future<VitrineModel> modifierVitrine(Map<String, dynamic> champs);
}

class VitrineRemoteDataSourceImpl implements VitrineRemoteDataSource {
  final Dio dio;
  VitrineRemoteDataSourceImpl(this.dio);

  @override
  Future<List<SecteurVitrine>> getSecteurs() async {
    final res = await dio.get(VitrineEndpoints.secteurs);
    final liste = deballer(res.data)['secteurs'];
    return (liste as List? ?? [])
        .whereType<Map>()
        .map((s) => SecteurVitrineModel.fromMap(s.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<VitrineModel> getMaVitrine() async {
    final res = await dio.get(VitrineEndpoints.maVitrine);
    return VitrineModel.fromJson(res.data);
  }

  @override
  Future<ResultatAnalyse> analyserLogo({
    required String logoPath,
    String? secteur,
    String? activite,
  }) async {
    final form = FormData.fromMap({
      'logo': await MultipartFile.fromFile(logoPath),
      // Le secteur accompagne le fichier : le serveur renvoie ainsi l'analyse
      // ET le site proposé en un seul aller-retour. Sur une connexion mobile,
      // deux requêtes pour peindre un écran se voient.
      if (secteur != null) 'secteur': secteur,
      if (activite != null && activite.isNotEmpty) 'activite': activite,
    });

    final res = await dio.post(VitrineEndpoints.analyserLogo, data: form);
    return ResultatAnalyse.fromJson(res.data);
  }

  @override
  Future<VitrineModel> genererVitrine({
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
    Map<String, dynamic>? blocs,
  }) async {
    // Multipart et non JSON : le logo voyage avec les réponses, et refaire un
    // second appel pour le fichier laisserait un site créé sans son logo si le
    // réseau lâchait entre les deux.
    final form = FormData.fromMap({
      if (logoPath != null) 'logo': await MultipartFile.fromFile(logoPath),
      'secteur': secteur,
      if (activite != null) 'activite': activite,
      if (modele != null) 'modele': modele,
      if (accent != null) 'accent': accent,
      if (slogan != null) 'slogan': slogan,
      if (apropos != null) 'apropos': apropos,
      if (horaires != null) 'horaires': horaires,
      if (annonce != null) 'annonce': annonce,
      'commande': commande.toString(),
      'paiementLivraison': paiementLivraison.toString(),
      'active': active.toString(),
      // Avantages (« Livraison rapide »…) et icônes des catégories.
      if (blocs != null) 'blocs': jsonEncode(blocs),
    });

    final res = await dio.post(VitrineEndpoints.generer, data: form);
    return VitrineModel.fromJson(res.data);
  }

  @override
  Future<VitrineModel> modifierVitrine(Map<String, dynamic> champs) async {
    final res = await dio.put(VitrineEndpoints.maVitrine, data: champs);
    return VitrineModel.fromJson(res.data);
  }
}
