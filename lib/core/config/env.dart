import 'package:flutter/foundation.dart';

/// Configuration de l'application, injectée à la compilation.
///
/// Pourquoi `--dart-define` et non un `.env` embarqué : un fichier déclaré
/// dans `pubspec.yaml` est un asset. Il part tel quel dans l'APK, et
/// n'importe qui peut le lire en dézippant le paquet — `unzip app.apk` suffit.
/// Tout ce qu'on y met est donc public.
///
/// Les valeurs passées par `--dart-define` sont compilées dans le binaire.
/// Ce n'est pas un coffre-fort — un binaire se décompile — mais ça retire la
/// lecture triviale, et surtout ça sort la configuration du dépôt.
///
/// Lancement en développement :
/// ```
/// flutter run \
///   --dart-define=API_BASE_URL=http://10.0.2.2:5000/saambiz/v1 \
///   --dart-define=ENVIRONNEMENT=dev
/// ```
///
/// Compilation de production :
/// ```
/// flutter build apk --release \
///   --dart-define=API_BASE_URL=https://saambiz-back-uj2z.onrender.com/saambiz/v1 \
///   --dart-define=ENVIRONNEMENT=prod \
///   --dart-define=EMPREINTES_CERTIFICAT=sha256/AAAA…,sha256/BBBB…
/// ```
class Env {
  Env._();

  // ─── Environnement ────────────────────────────────────────────────────────
  static const String environnement =
      String.fromEnvironment('ENVIRONNEMENT', defaultValue: 'dev');

  static bool get estProduction => environnement == 'prod';
  static bool get estDeveloppement => !estProduction;

  // ─── API ──────────────────────────────────────────────────────────────────
  /// Adresse de l'API.
  ///
  /// Le repli vise l'émulateur Android : `10.0.2.2` est l'alias de la machine
  /// hôte vu depuis l'émulateur. Sur un appareil physique il faut passer
  /// l'adresse IP du poste de développement par `--dart-define`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Adresse de l'API en ligne (Render) : un build lancé sans --dart-define
    // ni .env vise la production plutôt qu'un émulateur.
    defaultValue: 'https://saambiz-back-uj2z.onrender.com/saambiz/v1',
  );

  /// Vrai si `API_BASE_URL` a réellement été passée par `--dart-define`.
  ///
  /// `String.fromEnvironment` ne permet pas de distinguer « non fournie » de
  /// « fournie avec la valeur par défaut » : il faut `hasEnvironment`.
  static const bool apiBaseUrlCompilee = bool.hasEnvironment('API_BASE_URL');

  static String _apiBaseUrlEffective = apiBaseUrl;

  /// L'adresse que le client HTTP utilise vraiment. **C'est celle-ci qu'il
  /// faut lire**, pas [apiBaseUrl].
  static String get apiBaseUrlEffective => _apiBaseUrlEffective;

  /// Arbitre entre le `--dart-define` et le `.env`, une fois pour toutes.
  ///
  /// Le `--dart-define` l'emporte dès qu'il a été fourni : c'est lui qui porte
  /// la configuration de production. Le `.env` ne sert que de repli pour les
  /// postes de développement qui ne le passent pas encore.
  ///
  /// L'ordre était inversé, et silencieusement : le `.env` gagnait toujours.
  /// Comme `pubspec.yaml` le déclare en asset, il part dans l'APK — un build
  /// de production compilé avec l'URL HTTPS réelle continuait donc d'appeler
  /// l'adresse LAN du poste de développement qui traînait dans ce fichier.
  /// [verifier] ne voyait rien : elle contrôlait [apiBaseUrl], pas la valeur
  /// employée.
  static void resoudreApiBaseUrl(String? depuisDotenv) {
    if (apiBaseUrlCompilee) {
      _apiBaseUrlEffective = apiBaseUrl;
      return;
    }
    final repli = depuisDotenv?.trim() ?? '';
    _apiBaseUrlEffective = repli.isNotEmpty ? repli : apiBaseUrl;
  }

  static const Duration timeoutConnexion = Duration(seconds: 30);
  static const Duration timeoutReception = Duration(seconds: 60);
  static const Duration timeoutEnvoi = Duration(seconds: 60);

  // ─── Épinglage de certificat ──────────────────────────────────────────────
  /// Empreintes SHA-256 des clés publiques acceptées, séparées par des virgules.
  ///
  /// Vide = pas d'épinglage, on s'en remet à la validation système. C'est le
  /// mode de développement, où l'on passe souvent par un proxy ou un certificat
  /// auto-signé.
  static const String _empreintesBrutes =
      String.fromEnvironment('EMPREINTES_CERTIFICAT', defaultValue: '');

  static List<String> get empreintesCertificat => _empreintesBrutes
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  static bool get epinglageActif => estProduction && empreintesCertificat.isNotEmpty;

  // ─── Mise à jour forcée ───────────────────────────────────────────────────
  /// Adresse consultée au démarrage pour connaître la version minimale exigée.
  static const String urlConfigApp = String.fromEnvironment(
    'URL_CONFIG_APP',
    defaultValue: '',
  );

  // ─── Rapports de plantage ─────────────────────────────────────────────────
  /// Désactivés en débogage : sinon chaque rechargement à chaud pollue la
  /// console Crashlytics de plantages qui n'existent pas en production.
  static bool get crashlyticsActif => estProduction && !kDebugMode;

  /// Contrôle de cohérence, appelé au démarrage.
  ///
  /// Mieux vaut un écran d'erreur explicite au lancement qu'une application
  /// qui tourne en production contre l'API de développement.
  /// À appeler APRÈS [resoudreApiBaseUrl] : le contrôle porte sur l'adresse
  /// réellement employée. Le faire sur [apiBaseUrl] laissait passer une
  /// configuration de production qui appelait ensuite tout autre chose.
  static void verifier() {
    final url = _apiBaseUrlEffective;

    if (url.isEmpty) {
      throw StateError(
        'API_BASE_URL est vide. Passez-la par --dart-define au lancement.',
      );
    }

    if (estProduction) {
      if (url.startsWith('http://')) {
        throw StateError(
          'API_BASE_URL est en HTTP simple en production ($url). '
          'Le trafic passerait en clair.',
        );
      }
      if (url.contains('localhost')
          || url.contains('10.0.2.2')
          || RegExp(r'//(127\.|192\.168\.|10\.|172\.(1[6-9]|2\d|3[01])\.)')
              .hasMatch(url)) {
        throw StateError(
          "API_BASE_URL pointe sur une adresse de développement en production "
          '($url).',
        );
      }
    }
  }

  /// Résumé lisible, affiché au démarrage en débogage.
  static Map<String, Object?> get resume => {
        'environnement': environnement,
        'apiBaseUrl': apiBaseUrl,
        'épinglage': epinglageActif ? '${empreintesCertificat.length} empreinte(s)' : 'désactivé',
        'crashlytics': crashlyticsActif,
      };
}
