import 'package:dio/dio.dart';

/// Traduit une erreur réseau en une phrase lisible par l'utilisateur.
///
/// Ce point unique remplace huit extractions recopiées dans les repositories,
/// qui se contentaient pour la plupart de `e.message`. Or `e.message` est
/// rédigé par Dio, en anglais : sur une coupure de réseau l'utilisateur lisait
/// « The connection errored: Failed host lookup », et sur un dépassement de
/// délai « The request connection took longer than 0:00:30.000000 ».
///
/// L'ordre compte : le message renvoyé par le backend prime, parce qu'il est
/// le seul à connaître la raison métier (« Ce numéro est déjà utilisé »,
/// « Le montant doit être positif »). Les libellés génériques ci-dessous ne
/// servent que lorsqu'il n'y en a pas.
String messageErreurReseau(Object erreur, {String? repli}) {
  if (erreur is! DioException) {
    return repli ?? "Une erreur inattendue s'est produite.";
  }

  // 1. Ce que dit le backend.
  final messageBackend = _messageDuBackend(erreur.response?.data);
  if (messageBackend != null) return messageBackend;

  // 2. Les pannes de transport, qui n'ont pas de réponse du tout.
  switch (erreur.type) {
    case DioExceptionType.connectionError:
      return 'Pas de connexion internet. Vérifiez votre réseau puis réessayez.';
    case DioExceptionType.connectionTimeout:
      return "Le serveur met trop de temps à répondre. Vérifiez votre connexion puis réessayez.";
    case DioExceptionType.sendTimeout:
      return "L'envoi a pris trop de temps. Vérifiez votre connexion puis réessayez.";
    case DioExceptionType.receiveTimeout:
      return 'Le serveur met trop de temps à répondre. Réessayez dans un instant.';
    case DioExceptionType.cancel:
      return 'Opération annulée.';
    case DioExceptionType.badCertificate:
      return 'Connexion non sécurisée. Réessayez depuis un autre réseau.';
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
    case DioExceptionType.transformTimeout:
      break;
  }

  // 3. Le code HTTP, quand le backend n'a rien expliqué.
  final code = erreur.response?.statusCode;
  switch (code) {
    case 400:
      return 'Les informations envoyées sont incomplètes ou invalides.';
    case 401:
      return 'Votre session a expiré. Reconnectez-vous.';
    case 403:
      return "Vous n'avez pas les droits pour cette action.";
    case 404:
      return 'Cette ressource est introuvable.';
    case 409:
      return 'Cette opération entre en conflit avec des données existantes.';
    case 413:
      return 'Le fichier envoyé est trop volumineux.';
    case 422:
      return 'Certains champs sont invalides. Corrigez-les puis réessayez.';
    case 429:
      return 'Trop de tentatives. Patientez un instant avant de réessayer.';
    case 500:
    case 502:
    case 503:
    case 504:
      return 'Le serveur rencontre un problème. Réessayez dans quelques minutes.';
  }

  return repli ?? "Une erreur s'est produite. Réessayez.";
}

/// Extrait le message d'un corps de réponse du backend.
///
/// Le backend répond `{ success: false, message: "…" }`, mais les erreurs de
/// validation Joi arrivent parfois sous `errors: [{ message }]`. Une réponse
/// vide ou en HTML — une page d'erreur de Nginx, par exemple — ne doit rien
/// produire ici : elle vaut mieux traduite par son code HTTP.
String? _messageDuBackend(dynamic corps) {
  if (corps is Map) {
    final message = corps['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();

    final erreurs = corps['errors'];
    if (erreurs is List && erreurs.isNotEmpty) {
      final premiere = erreurs.first;
      if (premiere is Map && premiere['message'] is String) {
        return (premiere['message'] as String).trim();
      }
      if (premiere is String && premiere.trim().isNotEmpty) {
        return premiere.trim();
      }
    }

    final erreur = corps['error'];
    if (erreur is String && erreur.trim().isNotEmpty) return erreur.trim();
  }
  return null;
}
