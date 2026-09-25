double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class PromotionModel {
  final String id;
  final String titre;
  final String description;
  final double prixPromo;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String produitId;
  final String? produitNom;
  final String? produitImage;

  PromotionModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.prixPromo,
    this.dateDebut,
    this.dateFin,
    required this.produitId,
    this.produitNom,
    this.produitImage,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    final produit = json['produit'] as Map<String, dynamic>?;
    return PromotionModel(
      id: json['id']?.toString() ?? '',
      titre: json['titre']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      prixPromo: _toDouble(json['prixPromo']),
      dateDebut: json['dateDebut'] != null
          ? DateTime.tryParse(json['dateDebut'].toString())
          : null,
      dateFin: json['dateFin'] != null
          ? DateTime.tryParse(json['dateFin'].toString())
          : null,
      produitId: (json['produitId'] ?? produit?['id'])?.toString() ?? '',
      produitNom: produit?['nom']?.toString(),
      produitImage: produit?['image']?.toString(),
    );
  }
}
