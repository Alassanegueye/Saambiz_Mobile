import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/entities/user.dart';

/// Un compte déjà utilisé sur ce téléphone.
///
/// [refreshToken] est présent quand la session de ce compte est restée
/// ouverte (« Changer de compte ») : on y revient d'un toucher. Il est effacé
/// à la déconnexion : le compte reste proposé, mais avec son mot de passe.
class CompteMemorise {
  final String id;
  final String prenom;
  final String nom;
  final String email;
  final String telephone;
  final String role;
  final String? photoProfil;
  final String? refreshToken;
  final DateTime derniereUtilisation;

  const CompteMemorise({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.role,
    required this.derniereUtilisation,
    this.photoProfil,
    this.refreshToken,
  });

  bool get sessionOuverte => refreshToken != null && refreshToken!.isNotEmpty;
  bool get estVendeur => role.toUpperCase() == 'VENDEUR';

  String get nomComplet {
    final n = '$prenom $nom'.trim();
    return n.isEmpty ? email : n;
  }

  /// Identifiant à pré-remplir dans le formulaire de connexion.
  String get identifiant => email.isNotEmpty ? email : telephone;

  CompteMemorise copie({String? refreshToken, bool effacerJeton = false}) =>
      CompteMemorise(
        id: id,
        prenom: prenom,
        nom: nom,
        email: email,
        telephone: telephone,
        role: role,
        photoProfil: photoProfil,
        derniereUtilisation: derniereUtilisation,
        refreshToken: effacerJeton ? null : (refreshToken ?? this.refreshToken),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'prenom': prenom,
    'nom': nom,
    'email': email,
    'telephone': telephone,
    'role': role,
    'photoProfil': photoProfil,
    'refreshToken': refreshToken,
    'derniereUtilisation': derniereUtilisation.toIso8601String(),
  };

  factory CompteMemorise.fromJson(Map<String, dynamic> json) => CompteMemorise(
    id: '${json['id']}',
    prenom: json['prenom'] ?? '',
    nom: json['nom'] ?? '',
    email: json['email'] ?? '',
    telephone: json['telephone'] ?? '',
    role: json['role'] ?? '',
    photoProfil: json['photoProfil'],
    refreshToken: json['refreshToken'],
    derniereUtilisation:
        DateTime.tryParse('${json['derniereUtilisation']}') ?? DateTime(2000),
  );
}

/// Les comptes (clients et vendeurs) utilisés sur ce téléphone, pour choisir
/// sur l'écran de connexion celui où l'on revient.
///
/// Dans le stockage sécurisé : ils portent des jetons de session.
class ComptesMemorises {
  ComptesMemorises({required this.stockage});

  final FlutterSecureStorage stockage;

  static const String _cle = 'comptes_memorises';

  /// Au-delà, le compte le moins récemment utilisé est oublié.
  static const int maximum = 5;

  /// Du plus récemment utilisé au plus ancien.
  Future<List<CompteMemorise>> lister() async {
    try {
      final brut = await stockage.read(key: _cle);
      if (brut == null || brut.isEmpty) return [];
      final comptes = (jsonDecode(brut) as List)
          .whereType<Map>()
          .map((e) => CompteMemorise.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.derniereUtilisation.compareTo(a.derniereUtilisation));
      return comptes;
    } catch (_) {
      return []; // contenu illisible : on repart d'une liste vide
    }
  }

  Future<void> _ecrire(List<CompteMemorise> comptes) => stockage.write(
    key: _cle,
    value: jsonEncode(comptes.map((c) => c.toJson()).toList()),
  );

  /// Après une connexion réussie : le compte passe en tête de liste, avec sa
  /// session.
  Future<void> enregistrer(User user, String? refreshToken) async {
    final comptes = await lister();
    comptes.removeWhere((c) => c.id == user.id);
    comptes.insert(
      0,
      CompteMemorise(
        id: user.id,
        prenom: user.prenom,
        nom: user.nom,
        email: user.email,
        telephone: user.telephone,
        role: user.role,
        photoProfil: user.photoProfil,
        refreshToken: refreshToken,
        derniereUtilisation: DateTime.now(),
      ),
    );
    await _ecrire(comptes.take(maximum).toList());
  }

  /// Le serveur a renouvelé (ou refusé, `null`) la session de ce compte.
  Future<void> majJeton(String? idCompte, String? refreshToken) async {
    if (idCompte == null || idCompte.isEmpty) return;
    final comptes = await lister();
    final i = comptes.indexWhere((c) => c.id == idCompte);
    if (i < 0) return;
    comptes[i] = refreshToken == null || refreshToken.isEmpty
        ? comptes[i].copie(effacerJeton: true)
        : comptes[i].copie(refreshToken: refreshToken);
    await _ecrire(comptes);
  }

  /// « Retirer ce compte » de l'écran de connexion.
  Future<void> oublier(String idCompte) async {
    final comptes = await lister();
    comptes.removeWhere((c) => c.id == idCompte);
    await _ecrire(comptes);
  }
}
