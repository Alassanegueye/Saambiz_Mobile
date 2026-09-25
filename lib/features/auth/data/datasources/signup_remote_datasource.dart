import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/app_logger.dart';

/// Erreur d'inscription porteuse du message renvoyé par le backend.
/// Les écrans l'affichent tel quel : les messages du backend sont déjà
/// rédigés pour l'utilisateur final (email déjà utilisé, code incorrect…).
class SignupException implements Exception {
  final String message;
  const SignupException(this.message);

  @override
  String toString() => message;
}

/// Parcours d'inscription mobile, en deux temps :
///
///   1. [envoyerCode]    — un code à 6 chiffres part à l'adresse saisie ;
///   2. [verifierCode]   — le code est validé, un jeton est remis ;
///   3. [register]       — le compte est créé, en présentant ce jeton.
///
/// L'ordre n'est pas un détail. Créer le compte d'abord laissait une ligne
/// utilisateur définitive derrière chaque adresse jamais confirmée — fautes de
/// frappe comprises — et n'empêchait rien, puisque la connexion ne regardait
/// pas si l'adresse avait été vérifiée.
///
/// Volontairement séparé de [AuthRemoteDataSource] : celui-ci ne connaît ni le
/// rôle ni les champs boutique, et le refondre casserait la connexion déjà en
/// place. Ici on parle directement au backend avec le Dio partagé.
class SignupRemoteDataSource {
  final Dio dio;

  const SignupRemoteDataSource(this.dio);

  /// Étape 1 — demande l'envoi d'un code à 6 chiffres.
  ///
  /// Aucun compte n'est créé ici. Renvoie le message du backend, qui indique
  /// à quelle adresse le code est parti.
  Future<String> envoyerCode({required String email, String? prenom}) async {
    try {
      final res = await dio.post(
        AuthEndpoints.envoyerCodeInscription,
        data: {
          'email': email,
          if (prenom != null && prenom.trim().isNotEmpty) 'prenom': prenom.trim(),
        },
      );
      final data = res.data;
      if (data is Map && data['message'] is String) return data['message'];
      return 'Un code à 6 chiffres vient de vous être envoyé.';
    } on DioException catch (e) {
      throw SignupException(_message(e, "Impossible d'envoyer le code."));
    }
  }

  /// Étape 2 — valide le code et rend le jeton à présenter à [register].
  ///
  /// Ce jeton lie la création du compte à cette vérification-là : sans lui,
  /// entre la validation du code et l'envoi du formulaire, un tiers
  /// connaissant l'adresse pourrait s'inscrire à sa place.
  Future<String> verifierCode({
    required String email,
    required String code,
  }) async {
    try {
      final res = await dio.post(
        AuthEndpoints.verifierCodeInscription,
        data: {'email': email, 'code': code},
      );
      final jeton = (res.data is Map) ? res.data['jetonEmail'] : null;
      if (jeton is! String || jeton.isEmpty) {
        throw const SignupException(
          'Réponse inattendue du serveur. Réessayez dans un instant.',
        );
      }
      return jeton;
    } on DioException catch (e) {
      throw SignupException(_message(e, 'Code incorrect ou expiré.'));
    }
  }

  /// Étape 3 — crée le compte, l'adresse étant déjà vérifiée.
  Future<void> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String role, // 'Acheteur' ou 'Vendeur'
    required String jetonEmail,
    String? telephone,
  }) async {
    // Le endpoint accepte du multipart (photo de profil, logo) : on envoie un
    // FormData même sans fichier pour rester sur le même parseur côté serveur.
    final form = FormData.fromMap({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'mot_de_passe': motDePasse,
      'role': role,
      'jetonEmail': jetonEmail,
      if (telephone != null && telephone.trim().isNotEmpty)
        'telephone': telephone.trim(),
    });

    try {
      await dio.post(AuthEndpoints.register, data: form);
    } on DioException catch (e) {
      throw SignupException(_message(e, "Impossible de créer le compte."));
    }
  }

  /// Valide le code d'un compte DÉJÀ créé — parcours conservé pour les
  /// comptes ouverts avant l'inscription en deux temps.
  Future<void> verifierEmail({
    required String email,
    required String code,
  }) async {
    try {
      await dio.post(
        AuthEndpoints.verifyEmail,
        data: {'email': email, 'code': code},
      );
    } on DioException catch (e) {
      throw SignupException(_message(e, 'Code incorrect ou expiré.'));
    }
  }

  /// Redemande un code d'inscription : le précédent est invalidé côté
  /// serveur, et le compteur d'essais repart à zéro.
  Future<String> renvoyerCode(String email) async {
    try {
      final res = await dio.post(
        AuthEndpoints.envoyerCodeInscription,
        data: {'email': email},
      );
      final data = res.data;
      if (data is Map && data['message'] is String) return data['message'];
      return 'Un nouveau code vient de vous être envoyé.';
    } on DioException catch (e) {
      throw SignupException(_message(e, "Impossible d'envoyer le code."));
    }
  }

  // Le backend répond { message } (ou { errors: [...] } via le validateur).
  String _message(DioException e, String fallback) {
    logDebug('❌ signup: ${e.response?.statusCode} ${e.response?.data}');
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is String) return first;
        if (first is Map && first['message'] is String) return first['message'];
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Connexion impossible. Vérifiez votre réseau.';
    }
    return fallback;
  }
}
