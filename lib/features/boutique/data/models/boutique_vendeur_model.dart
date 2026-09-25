import '../../domain/entities/boutique.dart';

class BoutiqueVendeurModel extends Boutique {
  const BoutiqueVendeurModel({
    required super.id,
    required super.nom,
    required super.description,
    required super.localisation,
    super.telephone,
    super.logo,
    super.enPause,
  });

  factory BoutiqueVendeurModel.fromJson(Map<String, dynamic> json) {
    final data =
        (json['boutique'] ?? json) as Map<String, dynamic>;
    final statut = data['statut']?.toString();
    return BoutiqueVendeurModel(
      id: data['id']?.toString() ?? '',
      nom: data['nom']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      localisation: data['localisation']?.toString() ?? '',
      telephone: data['telephone']?.toString(),
      logo: data['logo']?.toString(),
      enPause: statut == 'pause' || data['enPause'] == true,
    );
  }
}
