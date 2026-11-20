import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
/// ## Ce qui part chez Firebase
///
/// [logErreur] envoie AUSSI l'erreur à Crashlytics, pour qu'une panne chez un
/// vendeur se lise depuis la console Firebase sans réclamer son téléphone.
/// Ce qui part : le libellé, le type de l'erreur et la pile d'appels. Jamais
/// la charge utile d'une requête — c'est pourquoi les appelants écrivent un
/// libellé en clair plutôt que de jeter l'objet entier.
///
/// Rien n'est envoyé si Firebase n'est pas configuré sur cet appareil : la
/// fonction se replie alors sur le seul journal système, et l'application
/// tourne sans rien savoir de Crashlytics.
const String _canal = 'SaamBiz';

/// Vrai quand Firebase est en place sur cet appareil.
///
/// Appeler Crashlytics sans Firebase initialisé lève ; or ces fonctions sont
/// appelées depuis des `catch`, et une journalisation qui lève remplacerait
/// l'erreur qu'on voulait lire.
bool get _firebasePret {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}

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

  if (!_firebasePret) return;
  try {
    // `fatal: false` : l'application continue de tourner. Ce sont les
    // incidents non fatals de la console Firebase — une requête qui échoue,
    // une session qu'on n'a pas pu renouveler.
    FirebaseCrashlytics.instance.recordError(
      erreur,
      pile,
      reason: quoi,
      fatal: false,
    );
  } catch (e) {
    // Crashlytics indisponible : on garde la trace système et on continue.
    developer.log('remontée impossible', name: _canal, error: e);
  }
}

/// Attache l'identifiant du compte aux incidents remontés.
///
/// Sans lui, une erreur dans la console n'est rattachée à personne : on voit
/// qu'une chose casse, sans pouvoir rappeler le vendeur qui l'a subie.
/// L'identifiant seul — ni nom, ni e-mail, ni téléphone.
void suivreUtilisateur(String? id) {
  if (!_firebasePret) return;
  try {
    FirebaseCrashlytics.instance.setUserIdentifier(id ?? '');
  } catch (_) {
    // Sans incidence sur ce que fait l'application.
  }
}
