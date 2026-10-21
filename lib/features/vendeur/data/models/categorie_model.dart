import '../../../categories/data/specification.dart';

class CategorieModel {
  final String id;
  final String nom;

  /// Ce que le vendeur renseigne pour un produit de cette catégorie
  /// (tailles, pointures, contenance…). Défini dans le dashboard admin.
  final List<SpecificationProduit> specifications;

  CategorieModel({required this.id, required this.nom, this.specifications = const []});

  factory CategorieModel.fromJson(Map<String, dynamic> json) => CategorieModel(
        id: json['id']?.toString() ?? '',
        nom: json['nom'] ?? '',
        specifications: SpecificationProduit.liste(json['specifications']),
      );
}
