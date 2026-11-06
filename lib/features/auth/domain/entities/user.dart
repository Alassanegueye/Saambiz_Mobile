import 'package:equatable/equatable.dart';

/// Lit un montant renvoye par l'API.
///
/// PostgreSQL rend les colonnes NUMERIC sous forme de chaine (« 1500.00 ») :
/// un `as double` casserait. On accepte donc les deux formes, et l'absence
/// de valeur vaut zero — un solde inconnu s'affiche comme vide, pas comme
/// une erreur.
double montantDepuisJson(dynamic valeur) {
  if (valeur is num) return valeur.toDouble();
  return double.tryParse('$valeur') ?? 0;
}

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

  /// Montant disponible sur le compte, en FCFA. Ne concerne que les vendeurs.
  ///
  /// Rien ne l'alimente encore cote serveur : la colonne existe, les
  /// reversements seront traites plus tard.
  final double soldeDisponible;

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
    this.soldeDisponible = 0,
  });

  /// Le nom à montrer à l'écran : prénom et nom, sinon l'e-mail, sinon le
  /// téléphone (un compte peut n'avoir renseigné qu'un identifiant).
  String get nomAffiche {
    final complet = '${prenom.trim()} ${nom.trim()}'.trim();
    if (complet.isNotEmpty) return complet;
    final mail = email.trim();
    return mail.isNotEmpty ? mail : telephone.trim();
  }

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
    'soldeDisponible': soldeDisponible,
  };

  @override
  List<Object?> get props => [
    id,
    nom,
    prenom,
    email,
    telephone,
    photoProfil,
    role,
    soldeDisponible,
  ];
}
