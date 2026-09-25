// Article du panier (stocké localement sur l'appareil)

class PanierItem {
  final String produitId;
  final String nom;
  final double prix;
  final String image;
  final String vendeurId;
  final String vendeurNom;
  int quantite;

  PanierItem({
    required this.produitId,
    required this.nom,
    required this.prix,
    required this.image,
    required this.vendeurId,
    required this.vendeurNom,
    this.quantite = 1,
  });

  double get sousTotal => prix * quantite;

  Map<String, dynamic> toJson() => {
        'produitId': produitId,
        'nom': nom,
        'prix': prix,
        'image': image,
        'vendeurId': vendeurId,
        'vendeurNom': vendeurNom,
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
        quantite: (json['quantite'] is int)
            ? json['quantite']
            : int.tryParse('${json['quantite']}') ?? 1,
      );
}
