// Article du panier (stocké localement sur l'appareil)

class PanierItem {
  final String produitId;
  final String nom;
  final double prix;
  final String image;
  final String vendeurId;
  final String vendeurNom;

  /// Options choisies par le client : { 'Tailles': 'XL', 'Parfums': 'Bissap' }.
  final Map<String, String> options;
  int quantite;

  PanierItem({
    required this.produitId,
    required this.nom,
    required this.prix,
    required this.image,
    required this.vendeurId,
    required this.vendeurNom,
    this.options = const {},
    this.quantite = 1,
  });

  double get sousTotal => prix * quantite;

  /// Identifie une ligne : le produit ET les options choisies. Deux tailles
  /// d'un même habit font deux lignes.
  String get cle {
    if (options.isEmpty) return produitId;
    final cles = options.keys.toList()..sort();
    return '$produitId|${cles.map((k) => '$k=${options[k]}').join('&')}';
  }

  /// « Tailles : XL · Parfums : Bissap »
  String get libelleOptions =>
      options.entries.map((e) => '${e.key} : ${e.value}').join(' · ');

  Map<String, dynamic> toJson() => {
        'produitId': produitId,
        'nom': nom,
        'prix': prix,
        'image': image,
        'vendeurId': vendeurId,
        'vendeurNom': vendeurNom,
        if (options.isNotEmpty) 'options': options,
        'quantite': quantite,
      };

  factory PanierItem.fromJson(Map<String, dynamic> json) => PanierItem(
        produitId: json['produitId']?.toString() ?? '',
        nom: json['nom'] ?? '',
        prix: (json['prix'] is num)
            ? (json['prix'] as num).toDouble()
            : double.tryParse('${json['prix']}') ?? 0,
        image: json['image'] ?? '',
        vendeurId: json['vendeurId']?.toString() ?? '',
        vendeurNom: json['vendeurNom'] ?? '',
        options: json['options'] is Map
            ? (json['options'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
            : const {},
        quantite: (json['quantite'] is int)
            ? json['quantite']
            : int.tryParse('${json['quantite']}') ?? 1,
      );
}
