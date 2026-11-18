double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

/// Remise en pour cent d'un prix promo sur un prix normal, arrondie ; nulle
/// si l'un manque ou si le prix promo n'est pas une baisse.
int? remiseEnPourcent(double? prix, double? prixPromo) {
  if (prix == null || prixPromo == null) return null;
  if (prix <= 0 || prixPromo <= 0 || prixPromo >= prix) return null;
  return ((prix - prixPromo) / prix * 100).round();
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

  /// Prix normal du produit : de quoi afficher la remise et le prix barré.
  /// Nul si le serveur ne l'envoie pas.
  final double? produitPrix;

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
    this.produitPrix,
  });

  /// Remise en pour cent, arrondie ; nulle sans prix normal connu.
  int? get remise => remiseEnPourcent(produitPrix, prixPromo);

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    // Le serveur inclut le produit sans alias : Sequelize le range alors sous
    // le nom du modèle, « Produit ». Lue sous « produit » seulement, la clé
    // ne trouvait rien : ni photo, ni nom de produit sur les promotions.
    final brut = json['produit'] ?? json['Produit'];
    final produit = brut is Map ? Map<String, dynamic>.from(brut) : null;
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
      produitPrix: produit?['prix'] == null
          ? null
          : _toDouble(produit!['prix']),
    );
  }
}
