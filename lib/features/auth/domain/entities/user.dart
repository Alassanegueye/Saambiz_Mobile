import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String mot_de_passe;
  final String adresse;
  final String telephone;
  final String? photoProfil;
  final String role;

  const User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.mot_de_passe,
    required this.adresse,
    required this.telephone,
    required this.role,
    this.photoProfil,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'mot_de_passe': mot_de_passe,
    'adresse': adresse,
    'telephone': telephone,
    'photoProfil': photoProfil,
    'role': role,

  };

  @override
  List<Object?> get props => [id, nom, prenom, email, telephone, photoProfil, role ];
}
