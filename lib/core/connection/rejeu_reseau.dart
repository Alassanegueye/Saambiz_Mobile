import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// Rejoue une requête quand le réseau a flanché, pas quand le serveur a dit non.
///
/// Sur un réseau mobile, une coupure d'une seconde — un changement d'antenne,
/// un ascenseur — faisait échouer l'écran immédiatement : l'utilisateur voyait
/// une erreur et devait tirer pour rafraîchir. Deux tentatives espacées
/// suffisent à absorber la quasi-totalité de ces micro-coupures.
///
/// ## Ce qui est rejoué, et surtout ce qui ne l'est pas
///
/// **Uniquement les requêtes idempotentes** : GET, HEAD. Rejouer un
/// `POST /commandes` dont la réponse s'est perdue en route créerait une
/// deuxième commande — le serveur l'a peut-être enregistrée avant la coupure.
/// Le risque n'est pas théorique : c'est précisément quand le réseau est
/// mauvais que la réponse se perd alors que la requête est passée.
///
/// **Uniquement les pannes de transport** : pas de réponse (coupure, délai
/// dépassé) ou 502/503/504, qui disent « réessayez ». Un 400, un 401 ou un
/// 404 sont des réponses : les rejouer ne changerait rien et retarderait
/// l'affichage de l'erreur.
///
/// Un appel peut se retirer du rejeu avec
/// `options.extra[RejeuReseau.cleDesactiver] = true`.
class RejeuReseau extends Interceptor {
  /// Posez `extra[cleDesactiver] = true` pour qu'une requête ne soit jamais
  /// rejouée, même en GET.
  static const String cleDesactiver = 'sansRejeu';

  /// Compteur de tentatives, porté par la requête elle-même.
  static const String _cleTentative = 'tentativeRejeu';

  final Dio dio;

  /// Nombre de rejeux APRÈS l'échec initial.
  final int tentatives;

  /// Attente avant le premier rejeu ; elle double ensuite.
  final Duration attenteInitiale;

  final Random _alea;

  RejeuReseau(
    this.dio, {
    this.tentatives = 2,
    this.attenteInitiale = const Duration(milliseconds: 400),
    Random? alea,
  }) : _alea = alea ?? Random();

  @override
  Future<void> onError(
    DioException erreur,
    ErrorInterceptorHandler handler,
  ) async {
    final requete = erreur.requestOptions;
    final faite = (requete.extra[_cleTentative] as int?) ?? 0;

    if (!_rejouable(erreur) || faite >= tentatives) {
      return handler.next(erreur);
    }

    // Attente croissante, avec une part d'aléatoire : sans elle, tous les
    // téléphones qui ont perdu le réseau en même temps — une antenne qui
    // tombe — reviendraient frapper le serveur à la même milliseconde.
    final base = attenteInitiale * pow(2, faite).toInt();
    final gigue = Duration(milliseconds: _alea.nextInt(150));
    await Future<void>.delayed(base + gigue);

    requete.extra[_cleTentative] = faite + 1;

    try {
      final reponse = await dio.fetch<dynamic>(requete);
      return handler.resolve(reponse);
    } on DioException catch (suivante) {
      return handler.next(suivante);
    }
  }

  bool _rejouable(DioException erreur) {
    final requete = erreur.requestOptions;

    if (requete.extra[cleDesactiver] == true) return false;

    // Annulation volontaire : l'écran a été quitté, il n'attend plus rien.
    if (erreur.type == DioExceptionType.cancel) return false;

    final methode = requete.method.toUpperCase();
    if (methode != 'GET' && methode != 'HEAD') return false;

    switch (erreur.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      case DioExceptionType.badResponse:
        final code = erreur.response?.statusCode;
        return code == 502 || code == 503 || code == 504;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return false;
    }
  }
}
