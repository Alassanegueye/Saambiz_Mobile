/// Ce qu'un signalement vise : la boutique ou le produit concerné.
///
/// Peut rester `null` quand la cible a disparu depuis — une boutique fermée,
/// un produit retiré. Le signalement, lui, reste : c'est tout son intérêt.
class CibleSignalement {
  final String id;
  final String nom;
  final String? image;

  const CibleSignalement({required this.id, required this.nom, this.image});

  static CibleSignalement? depuis(dynamic json) {
    if (json is! Map) return null;
    final nom = json['nom']?.toString().trim() ?? '';
    if (nom.isEmpty) return null;
    final image = json['image']?.toString().trim();
    return CibleSignalement(
      id: json['id']?.toString() ?? '',
      nom: nom,
      image: (image == null || image.isEmpty) ? null : image,
    );
  }
}

class SignalementModel {
  final String id;
  final String type; // 'produit' | 'boutique'
  final String raison;
  final String description;
  final String cibleId;
  final String statut;
  final DateTime? createdAt;

  /// La boutique ou le produit visé, nommé par le serveur.
  ///
  /// La liste n'en portait aucun : l'écran affichait la RAISON SAISIE en gros
  /// titre, et l'on ne savait plus de quoi on avait parlé.
  final CibleSignalement? cible;

  SignalementModel({
    required this.id,
    required this.type,
    required this.raison,
    required this.description,
    required this.cibleId,
    required this.statut,
    this.createdAt,
    this.cible,
  });

  /// `true` tant que l'équipe n'a pas tranché.
  bool get enAttente => statut == 'en_attente';

  /// Libellé lisible du statut. L'écran montrait la valeur brute de la base,
  /// soulignés compris : « en_attente ».
  String get libelleStatut => switch (statut) {
    'en_attente' => 'En attente',
    'traite' => 'Traité',
    'rejete' => 'Rejeté',
    _ => statut,
  };

  /// Ce que le signalement vise, en toutes lettres.
  String get libelleType => type == 'produit' ? 'Produit' : 'Boutique';

  factory SignalementModel.fromJson(Map<String, dynamic> json) {
    return SignalementModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      raison: json['raison']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      cibleId: json['cibleId']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'en_attente',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      cible: CibleSignalement.depuis(json['cible']),
    );
  }
}
