import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';

/// Un avis laissé par un acheteur sur une boutique.
class Avis {
  final String id;
  final int note;
  final String commentaire;
  final String auteur;
  final String? photoAuteur;
  final DateTime? date;

  const Avis({
    required this.id,
    required this.note,
    required this.commentaire,
    required this.auteur,
    this.photoAuteur,
    this.date,
  });

  factory Avis.fromJson(Map<String, dynamic> json) {
    // Le backend joint l'acheteur sous `acheteur` ; il peut manquer si le
    // compte a été supprimé depuis.
    final acheteur = json['acheteur'];
    final prenom = acheteur is Map ? (acheteur['prenom'] ?? '') : '';
    final nom = acheteur is Map ? (acheteur['nom'] ?? '') : '';
    final complet = '$prenom $nom'.trim();

    return Avis(
      id: json['id']?.toString() ?? '',
      note: (json['note'] is num) ? (json['note'] as num).toInt() : 0,
      commentaire: (json['commentaire'] ?? '').toString(),
      auteur: complet.isEmpty ? 'Client SaamBiz' : complet,
      photoAuteur: acheteur is Map ? acheteur['photoProfil']?.toString() : null,
      date: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

/// Avis d'une boutique : la liste, la moyenne et le total.
class AvisBoutique {
  final double moyenne;
  final int total;
  final List<Avis> avis;

  const AvisBoutique({
    required this.moyenne,
    required this.total,
    required this.avis,
  });

  static const vide = AvisBoutique(moyenne: 0, total: 0, avis: []);
}

/// Accès aux avis (`/avis`).
///
/// Les quatre routes existaient côté backend depuis le début et aucune
/// n'était appelée par un écran : un acheteur ne pouvait ni lire les avis
/// d'une boutique, ni en laisser un, ni relire le sien, ni le retirer. Seule
/// la note moyenne, calculée par le serveur, apparaissait sur la fiche.
class AvisRemoteDataSource {
  final Dio dio;
  const AvisRemoteDataSource(this.dio);

  /// Liste publique des avis d'une boutique, moyenne et total.
  ///
  /// Ouverte aux visiteurs sans compte.
  Future<AvisBoutique> avisBoutique(String boutiqueId) async {
    final res = await dio.get(AvisEndpoints.boutique(boutiqueId));
    final data = res.data;
    if (data is! Map) return AvisBoutique.vide;

    return AvisBoutique(
      moyenne: (data['moyenne'] is num)
          ? (data['moyenne'] as num).toDouble()
          : 0,
      total: (data['total'] is num) ? (data['total'] as num).toInt() : 0,
      avis: (data['avis'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Avis.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// L'avis de l'acheteur connecté sur cette boutique, s'il en a laissé un.
  ///
  /// `null` quand il n'en a pas encore : le backend répond alors `avis: null`,
  /// ce qui n'est pas une erreur.
  Future<Avis?> monAvis(String boutiqueId) async {
    final res = await dio.get(AvisEndpoints.monAvis(boutiqueId));
    final data = res.data;
    final brut = data is Map ? data['avis'] : null;
    if (brut is! Map) return null;
    return Avis.fromJson(Map<String, dynamic>.from(brut));
  }

  /// Publie l'avis, ou met à jour celui qui existe déjà.
  ///
  /// Le backend fait un `findOrCreate` sur le couple acheteur/boutique : un
  /// même client ne peut donc pas noter deux fois la même boutique, et
  /// renvoyer le formulaire revient à corriger son avis.
  Future<AvisBoutique> laisser({
    required String boutiqueId,
    required int note,
    String? commentaire,
  }) async {
    final res = await dio.post(
      AvisEndpoints.avis,
      data: {
        'boutiqueId': boutiqueId,
        'note': note,
        if (commentaire != null && commentaire.trim().isNotEmpty)
          'commentaire': commentaire.trim(),
      },
    );
    final data = res.data;
    if (data is! Map) return AvisBoutique.vide;
    // La réponse porte les statistiques à jour : l'écran peut les afficher
    // sans redemander la liste.
    return AvisBoutique(
      moyenne: (data['moyenne'] is num)
          ? (data['moyenne'] as num).toDouble()
          : 0,
      total: (data['total'] is num) ? (data['total'] as num).toInt() : 0,
      avis: const [],
    );
  }

  /// Retire l'avis de l'acheteur connecté.
  Future<void> supprimer(String boutiqueId) async {
    await dio.delete(AvisEndpoints.boutique(boutiqueId));
  }
}
