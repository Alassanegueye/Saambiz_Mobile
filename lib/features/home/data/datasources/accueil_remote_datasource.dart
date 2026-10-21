import 'package:dio/dio.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../categories/data/categorie.dart';

/// Une bande de l'accueil : « Sélectionné pour vous », « Près de chez vous »…
/// Le backend décide des sections, de leur ordre et de leur libellé — c'est lui
/// qui connaît les affinités du client. L'application se contente d'afficher.
class AccueilSection {
  final String cle;
  final String titre;
  final String? sousTitre;
  final String type; // 'boutiques' ou 'produits'
  final List<Map<String, dynamic>> elements;

  const AccueilSection({
    required this.cle,
    required this.titre,
    this.sousTitre,
    required this.type,
    required this.elements,
  });

  factory AccueilSection.fromJson(Map<String, dynamic> json) => AccueilSection(
        cle: json['cle']?.toString() ?? '',
        titre: json['titre']?.toString() ?? '',
        sousTitre: json['sousTitre']?.toString(),
        type: json['type']?.toString() ?? 'boutiques',
        elements: (json['elements'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
}

class AccueilPersonnalise {
  final bool invite;
  final List<String> interets;
  final bool positionConnue;
  final List<AccueilSection> sections;

  /// Rangée de catégories en tête d'accueil, dans l'ordre fixé par l'admin.
  final List<Categorie> categories;

  const AccueilPersonnalise({
    required this.invite,
    required this.interets,
    required this.positionConnue,
    required this.sections,
    this.categories = const [],
  });

  factory AccueilPersonnalise.fromJson(Map<String, dynamic> json) =>
      AccueilPersonnalise(
        invite: json['invite'] == true,
        interets: (json['interets'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        positionConnue: json['positionConnue'] == true,
        sections: (json['sections'] as List? ?? [])
            .whereType<Map>()
            .map((e) => AccueilSection.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        categories: (json['categories'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Categorie.fromJson(Map<String, dynamic>.from(e)))
            .where((c) => c.nom.isNotEmpty)
            .toList(),
      );

  bool get estVide => sections.isEmpty && categories.isEmpty;
}

/// Accueil personnalisé — la seule route de l'application ouverte aux invités.
class AccueilRemoteDataSource {
  final Dio dio;
  const AccueilRemoteDataSource(this.dio);

  /// Les centres d'intérêt ne sont transmis que pour un invité : pour un
  /// client connecté, le backend utilise ceux qu'il a enregistrés.
  Future<AccueilPersonnalise> charger({
    List<String> interets = const [],
    double? latitude,
    double? longitude,
  }) async {
    try {
      final res = await dio.get(
        '/acheteurs/accueil-personnalise',
        queryParameters: {
          if (interets.isNotEmpty) 'interets': interets.join(','),
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
      return AccueilPersonnalise.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } on DioException catch (e) {
      logDebug('❌ accueil: ${e.response?.statusCode} ${e.response?.data}');
      rethrow;
    }
  }

  /// Tout le contenu d'une section de l'accueil (bouton « Voir tout »).
  Future<AccueilSection> chargerSection(
    String cle, {
    List<String> interets = const [],
    double? latitude,
    double? longitude,
  }) async {
    try {
      final res = await dio.get(
        '/acheteurs/accueil-section/$cle',
        queryParameters: {
          if (interets.isNotEmpty) 'interets': interets.join(','),
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          'limit': 60,
        },
      );
      final json = Map<String, dynamic>.from(res.data as Map);
      return AccueilSection.fromJson({...json, 'cle': cle, 'titre': json['titre'] ?? ''});
    } on DioException catch (e) {
      logDebug('❌ section $cle: ${e.response?.statusCode} ${e.response?.data}');
      rethrow;
    }
  }

  /// Enregistre côté serveur les centres d'intérêt et/ou la position.
  /// Réservé aux clients connectés — un invité garde tout sur son téléphone.
  Future<void> majPreferences({
    List<String>? interets,
    double? latitude,
    double? longitude,
    String? ville,
  }) async {
    try {
      await dio.put('/acheteurs/preferences', data: {
        if (interets != null) 'interets': interets,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (ville != null) 'ville': ville,
      });
    } on DioException catch (e) {
      // Non bloquant : la personnalisation se fera au prochain passage.
      logDebug('⚠️ préférences non enregistrées: ${e.response?.statusCode}');
    }
  }
}
