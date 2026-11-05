import 'package:dio/dio.dart';

import 'token_service.dart';

enum ResultatRenouvellement {
  /// Nouveaux jetons enregistrés.
  renouvele,

  /// Le serveur refuse (session révoquée ou trop ancienne) : il faut se
  /// reconnecter.
  refuse,

  /// Réseau ou serveur indisponible : la session reste valable, on réessaiera.
  injoignable,

  /// Aucune session à renouveler (visiteur, ou compte connecté avant que
  /// l'application ne garde ce jeton).
  aucune,
}

/// Garde la session ouverte : le jeton d'accès ne vit qu'une heure, le jeton de
/// rafraîchissement permet d'en obtenir un autre sans redemander le mot de passe.
class SessionService {
  final TokenService jetons;

  /// Sans intercepteur : ces appels ne doivent pas se déclencher eux-mêmes.
  final Dio dio;

  Future<ResultatRenouvellement>? _enCours;

  SessionService({required this.jetons, required this.dio});

  /// Un seul renouvellement à la fois : le serveur révoque le jeton dès son
  /// premier usage, un second appel simultané serait refusé et couperait la
  /// session alors que tout va bien.
  Future<ResultatRenouvellement> renouveler() {
    return _enCours ??= _renouveler().whenComplete(() => _enCours = null);
  }

  Future<ResultatRenouvellement> _renouveler() async {
    final refresh = await jetons.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      return ResultatRenouvellement.aucune;
    }
    try {
      final res = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      await jetons.setToken(res.data['token']?.toString());
      await jetons.setRefreshToken(res.data['refreshToken']?.toString());
      return ResultatRenouvellement.renouvele;
    } on DioException catch (e) {
      final statut = e.response?.statusCode;
      if (statut == 400 || statut == 401 || statut == 403) {
        await jetons.clearToken();
        return ResultatRenouvellement.refuse;
      }
      return ResultatRenouvellement.injoignable;
    }
  }

  /// Déconnexion : le serveur oublie la session. Au mieux : sans réseau, les
  /// jetons sont tout de même effacés du téléphone.
  Future<void> revoquer() async {
    try {
      final token = await jetons.getToken();
      final refresh = await jetons.getRefreshToken();
      if (token == null || refresh == null) return;
      await dio
          .post(
            '/auth/logout',
            data: {'refreshToken': refresh},
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      /* la déconnexion locale suit de toute façon */
    }
  }
}
