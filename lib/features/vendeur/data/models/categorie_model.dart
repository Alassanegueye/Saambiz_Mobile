class CategorieModel {
  final String id;
  final String nom;

  CategorieModel({required this.id, required this.nom});

  factory CategorieModel.fromJson(Map<String, dynamic> json) => CategorieModel(
        id: json['id']?.toString() ?? '',
        nom: json['nom'] ?? '',
      );
}
