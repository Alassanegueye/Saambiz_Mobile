class BoutiqueModel {
  final String  id;
  final String  nom;
  final String  description;
  final String  localisation;
  final String? telephone;
  final String? logo;
  final String  vendeurId;
  final String  vendeurNom;
  final String  vendeurPrenom;
  final String  vendeurNumero;
  // 🔔 Cloche active pour cette boutique suivie (renseigné via /favoris).
  final bool    clocheActive;
  // ⭐ Note moyenne (0 si aucun avis) + nombre d'avis (renseignés par le backend).
  final double  note;
  final int     nombreAvis;

  BoutiqueModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.localisation,
    this.telephone,
    this.logo,
    required this.vendeurId,
    required this.vendeurNom,
    required this.vendeurPrenom,
    required this.vendeurNumero,
    this.clocheActive = true,
    this.note = 0,
    this.nombreAvis = 0,
  });

  factory BoutiqueModel.fromJson(Map<String, dynamic> json) {
    final vendeur       = json['vendeur'] as Map<String, dynamic>?;
    final vendeurId     = vendeur?['id']?.toString()     ?? '';
    final vendeurNom    = vendeur?['nom']?.toString()    ?? '';
    final vendeurPrenom = vendeur?['prenom']?.toString() ?? '';
    final vendeurNumero = vendeur?['telephone']?.toString() ?? '';

    return BoutiqueModel(
      id:             json['id']?.toString()           ?? '',
      nom:            json['nom']?.toString()           ?? '',
      description:    json['description']?.toString()   ?? '',
      localisation:   json['localisation']?.toString()  ?? '',
      telephone:      json['telephone']?.toString(),
      logo:           json['logo']?.toString(),
      vendeurId:      vendeurId,
      vendeurNom:     vendeurNom,
      vendeurPrenom:  vendeurPrenom,
      vendeurNumero:  vendeurNumero,
      clocheActive:   json['clocheActive'] == null ? true : json['clocheActive'] == true,
      note:           (json['note'] is num) ? (json['note'] as num).toDouble() : double.tryParse('${json['note'] ?? 0}') ?? 0,
      nombreAvis:     (json['nombreAvis'] is num) ? (json['nombreAvis'] as num).toInt() : int.tryParse('${json['nombreAvis'] ?? 0}') ?? 0,
    );
  }

  String get vendeurNomComplet => '$vendeurPrenom $vendeurNom'.trim();

  // Horaires d'ouverture supprimés du projet (boutique en ligne) → toujours vide.
  String get horaires => '';

  Map<String, dynamic> toJson() => {
    'id':              id,
    'nom':             nom,
    'description':     description,
    'localisation':    localisation,
    'telephone':       telephone,
    'logo':            logo,
    'vendeur': {
      'id':     vendeurId,
      'nom':    vendeurNom,
      'prenom': vendeurPrenom,
      'telephone': vendeurNumero,
    },
  };
}