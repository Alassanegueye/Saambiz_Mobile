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
///   --dart-define=API_BASE_URL=https://api.saambiz.sn/saambiz/v1 \
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
    defaultValue: 'http://10.0.2.2:5000/saambiz/v1',
  );

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
  static void verifier() {
    if (apiBaseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL est vide. Passez-la par --dart-define au lancement.',
      );
    }

    if (estProduction) {
      if (apiBaseUrl.startsWith('http://')) {
        throw StateError(
          'API_BASE_URL est en HTTP simple en production ($apiBaseUrl). '
          'Le trafic passerait en clair.',
        );
      }
      if (apiBaseUrl.contains('localhost') || apiBaseUrl.contains('10.0.2.2')) {
        throw StateError(
          "API_BASE_URL pointe sur une adresse de développement en production "
          '($apiBaseUrl).',
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
