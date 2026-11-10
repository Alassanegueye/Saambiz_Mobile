import 'package:dio/dio.dart';

import 'comptes_memorises.dart';
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

  /// Comptes mémorisés sur l'appareil : leur jeton suit chaque
  /// renouvellement, sinon le choix du compte proposerait une session morte.
  final ComptesMemorises? comptes;

  SessionService({required this.jetons, required this.dio, this.comptes});

  Future<String?> _idCourant() async {
    try {
      return await jetons.secureStorage.read(key: 'user_id');
    } catch (_) {
      return null;
    }
  }

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
      final nouveau = res.data['refreshToken']?.toString();
      await jetons.setToken(res.data['token']?.toString());
      await jetons.setRefreshToken(nouveau);
      await comptes?.majJeton(await _idCourant(), nouveau);
      return ResultatRenouvellement.renouvele;
    } on DioException catch (e) {
      final statut = e.response?.statusCode;
      if (statut == 400 || statut == 401 || statut == 403) {
        await comptes?.majJeton(await _idCourant(), null);
        await jetons.clearToken();
        return ResultatRenouvellement.refuse;
      }
      return ResultatRenouvellement.injoignable;
    }
  }

  /// Revenir sur un compte mémorisé dont la session est restée ouverte : son
  /// jeton de rafraîchissement est échangé contre une session neuve, qui
  /// devient la session courante.
  Future<ResultatRenouvellement> reprendre(CompteMemorise compte) async {
    if (!compte.sessionOuverte) return ResultatRenouvellement.aucune;
    try {
      final res = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': compte.refreshToken},
      );
      final nouveau = res.data['refreshToken']?.toString();
      await jetons.setRefreshToken(nouveau);
      await jetons.secureStorage.write(key: 'user_id', value: compte.id);
      await jetons.setToken(res.data['token']?.toString());
      await comptes?.majJeton(compte.id, nouveau);
      return ResultatRenouvellement.renouvele;
    } on DioException catch (e) {
      final statut = e.response?.statusCode;
      if (statut == 400 || statut == 401 || statut == 403) {
        await comptes?.majJeton(compte.id, null);
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

  /// « Retirer ce compte » d'un compte dont la session est restée ouverte :
  /// le serveur la ferme aussi, au mieux (sans réseau, elle expirera).
  Future<void> fermerSessionMemorisee(CompteMemorise compte) async {
    if (!compte.sessionOuverte) return;
    try {
      final res = await dio
          .post('/auth/refresh', data: {'refreshToken': compte.refreshToken})
          .timeout(const Duration(seconds: 4));
      final token = res.data['token']?.toString();
      final refresh = res.data['refreshToken']?.toString();
      if (token == null || refresh == null) return;
      await dio
          .post(
            '/auth/logout',
            data: {'refreshToken': refresh},
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      /* au mieux */
    }
  }
}
