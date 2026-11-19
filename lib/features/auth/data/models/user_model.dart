import '../../domain/entities/user.dart';

/// Le nom d'une boutique, qu'elle arrive en objet ou en simple chaine.
String? _nomBoutique(dynamic valeur) {
  if (valeur is Map) {
    final nom = valeur['nom']?.toString().trim();
    return (nom == null || nom.isEmpty) ? null : nom;
  }
  final nom = valeur?.toString().trim();
  return (nom == null || nom.isEmpty) ? null : nom;
}

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.mot_de_passe,
    required super.adresse,
    required super.telephone,
    required super.role,
    super.photoProfil,
    super.soldeDisponible,
    super.boutiqueNom,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      mot_de_passe: json['mot_de_passe'] ?? '',
      adresse: json['adresse'] ?? '',
      telephone: json['telephone'] ?? '',
      role: json['role'] ?? '',
      photoProfil: json['photoProfil'],
      soldeDisponible: montantDepuisJson(json['soldeDisponible']),
      // Le serveur la joint a la session d'un vendeur. Absente d'un jeton
      // relu (il ne porte que l'identite), d'ou la lecture tolerante.
      boutiqueNom: _nomBoutique(json['boutique']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'mot_de_passe': mot_de_passe,
      'adresse': adresse,
      'telephone': telephone,
      'role': role,
      'photoProfil': photoProfil,
      'soldeDisponible': soldeDisponible,
      if (boutiqueNom != null) 'boutique': {'nom': boutiqueNom},
    };
  }
}

class AuthResponseModel {
  final String token;
  final String? refreshToken;
  final UserModel user;

  AuthResponseModel({
    required this.token,
    required this.user,
    this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userData = json['utilisateur'] ?? {};

    return AuthResponseModel(
      token: json['token'] ?? '',
      refreshToken: json['refreshToken']?.toString(),
      user: UserModel.fromJson(userData as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'utilisateur': user.toJson()};
  }
}
