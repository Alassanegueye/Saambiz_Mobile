import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Les deux journaux de l'application.
///
/// ## Pourquoi deux, et pas un
///
/// Une trace de mise au point dit tout : jeton, corps de requête, réponse
/// entière. Ce détail n'a rien à faire sur le téléphone d'un client — il
/// resterait lisible par n'importe quelle application capable de lire le
/// journal système. [logDebug] se tait donc en production.
///
/// Mais se taire sur TOUT, c'est se priver de l'essentiel : quand un vendeur
/// signale que « ça ne marche pas », il n'y a plus rien à regarder. [logErreur]
/// parle donc en production aussi — sans la charge utile, avec ce qui a
/// échoué et où.
///
/// ## Où cela ressort
///
/// `dart:developer` écrit dans le journal du SYSTÈME, pas dans la console de
/// Flutter : la console Xcode (Fenêtre > Appareils) côté iOS, `adb logcat`
/// côté Android. On y lit donc les erreurs d'un téléphone branché, même sur
/// une version installée depuis TestFlight.
///
/// Ce qu'il ne fait pas : remonter quoi que ce soit à distance. Pour lire le
/// journal d'un testeur à l'autre bout de la ville, il faut un service de
/// remontée (Crashlytics, Sentry) — ce n'est pas installé.
const String _canal = 'SaamBiz';

/// Trace de mise au point. Verbeuse, et SEULEMENT en débogage.
void logDebug(Object? message) {
  if (kDebugMode) {
    developer.log('$message', name: _canal);
  }
}

/// Une erreur, visible EN PRODUCTION AUSSI.
///
/// [quoi] dit ce qui a échoué, en clair et sans donnée personnelle :
/// « renouvellement de session », « envoi de la photo ». L'erreur et la pile
/// suivent, c'est le reste du travail.
void logErreur(String quoi, Object erreur, [StackTrace? pile]) {
  developer.log(
    quoi,
    name: _canal,
    error: erreur,
    stackTrace: pile,
    // 1000 = SEVERE : repérable d'un coup d'œil au milieu du reste.
    level: 1000,
  );
}
