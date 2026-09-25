import '../../../auth/domain/entities/user.dart';

/// Modèle de données du compte utilisateur connecté (GET /account/me,
/// PUT /account/modifier-profil). Miroir de [User] de la feature `auth`.
class CompteModel extends User {
  const CompteModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.mot_de_passe,
    required super.adresse,
    required super.telephone,
    required super.role,
    super.photoProfil,
  });

  factory CompteModel.fromJson(Map<String, dynamic> json) {
    final data = (json['utilisateur'] ?? json['user'] ?? json) as Map<String, dynamic>;
    return CompteModel(
      id: data['id']?.toString() ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      mot_de_passe: data['mot_de_passe'] ?? '',
      adresse: data['adresse'] ?? '',
      telephone: data['telephone'] ?? '',
      role: data['role'] ?? '',
      photoProfil: data['photoProfil'],
    );
  }
}
