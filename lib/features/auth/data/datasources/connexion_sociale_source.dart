import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/config/env.dart';

enum FournisseurSocial { google, apple }

/// Identité prouvée par Google ou Apple, à faire valider par le serveur
/// (`POST /auth/social`). Le serveur ne croit que le jeton signé : prénom et
/// nom ne servent qu'à baptiser un compte créé à cette occasion.
class IdentiteSociale {
  final FournisseurSocial fournisseur;
  final String idToken;
  final String? nonce;
  final String? prenom;
  final String? nom;

  const IdentiteSociale({
    required this.fournisseur,
    required this.idToken,
    this.nonce,
    this.prenom,
    this.nom,
  });

  Map<String, dynamic> toJson() => {
    'fournisseur': fournisseur.name,
    'idToken': idToken,
    if (nonce != null) 'nonce': nonce,
    if (prenom != null && prenom!.trim().isNotEmpty) 'prenom': prenom!.trim(),
    if (nom != null && nom!.trim().isNotEmpty) 'nom': nom!.trim(),
  };
}

/// L'utilisateur a fermé la fenêtre Google / Apple : rien à signaler.
class ConnexionSocialeAnnulee implements Exception {
  const ConnexionSocialeAnnulee();
}

/// Google n'est pas encore configuré dans cette version de l'application
/// (identifiants client absents) : le bouton est affiché, mais la connexion
/// ne peut pas aboutir.
class ConnexionSocialeIndisponible implements Exception {
  const ConnexionSocialeIndisponible();
}

/// Ouvre la fenêtre de connexion native de Google ou d'Apple et en rapporte
/// le jeton d'identité.
class ConnexionSocialeSource {
  bool _googlePret = false;

  bool get _ios => !kIsWeb && Platform.isIOS;
  bool get _android => !kIsWeb && Platform.isAndroid;

  /// Google : disponible dès que l'identifiant client de la plateforme est
  /// fourni à la compilation (voir `Env`). Sans lui, le SDK iOS s'arrête net.
  bool get googleDisponible =>
      (_ios && Env.googleIosClientId.isNotEmpty) ||
      (_android && Env.googleServerClientId.isNotEmpty);

  /// Le bouton Google est toujours proposé sur téléphone, même tant que
  /// l'identifiant client n'est pas fourni : un toucher l'explique alors.
  bool get googleAffiche => _ios || _android;

  /// Apple : sur iPhone uniquement (connexion native, exigée par l'App Store
  /// dès qu'une autre connexion tierce est proposée).
  bool get appleDisponible => _ios;

  Future<IdentiteSociale> obtenir(FournisseurSocial fournisseur) =>
      switch (fournisseur) {
        FournisseurSocial.google => _google(),
        FournisseurSocial.apple => _apple(),
      };

  Future<IdentiteSociale> _google() async {
    // Sans identifiant client, le SDK iOS ferait planter l'application.
    if (!googleDisponible) throw const ConnexionSocialeIndisponible();
    final google = GoogleSignIn.instance;
    if (!_googlePret) {
      await google.initialize(
        clientId: _ios ? Env.googleIosClientId : null,
        serverClientId: Env.googleServerClientId.isEmpty
            ? null
            : Env.googleServerClientId,
      );
      _googlePret = true;
    }
    try {
      final compte = await google.authenticate(scopeHint: const ['email']);
      final jeton = compte.authentication.idToken;
      if (jeton == null || jeton.isEmpty) {
        throw StateError('Google n\'a pas fourni de jeton d\'identité.');
      }
      // On ne garde pas la session Google ouverte dans l'application : la
      // prochaine connexion reproposera le choix du compte.
      google.signOut().ignore();
      final morceaux = (compte.displayName ?? '').trim().split(RegExp(r'\s+'));
      return IdentiteSociale(
        fournisseur: FournisseurSocial.google,
        idToken: jeton,
        prenom: morceaux.isNotEmpty ? morceaux.first : null,
        nom: morceaux.length > 1 ? morceaux.sublist(1).join(' ') : null,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const ConnexionSocialeAnnulee();
      }
      rethrow;
    }
  }

  Future<IdentiteSociale> _apple() async {
    // Nonce : Apple en inscrit l'empreinte dans le jeton, le serveur la
    // recalcule. Un jeton intercepté ne peut pas être rejoué ailleurs.
    final nonce = _nonce();
    try {
      final identifiants = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(nonce)).toString(),
      );
      final jeton = identifiants.identityToken;
      if (jeton == null || jeton.isEmpty) {
        throw StateError('Apple n\'a pas fourni de jeton d\'identité.');
      }
      return IdentiteSociale(
        fournisseur: FournisseurSocial.apple,
        idToken: jeton,
        nonce: nonce,
        // Fournis par Apple à la toute première connexion seulement.
        prenom: identifiants.givenName,
        nom: identifiants.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const ConnexionSocialeAnnulee();
      }
      rethrow;
    }
  }

  static String _nonce([int longueur = 32]) {
    const alphabet =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final aleatoire = Random.secure();
    return List.generate(
      longueur,
      (_) => alphabet[aleatoire.nextInt(alphabet.length)],
    ).join();
  }
}
