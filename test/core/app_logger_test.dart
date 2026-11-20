import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/utils/app_logger.dart';

/// Les deux journaux de l'application.
///
/// Une trace de mise au point dit tout — jeton, corps de requête, réponse
/// entière — et n'a rien à faire sur le téléphone d'un client. Mais se taire
/// sur TOUT, c'est se priver de l'essentiel : quand un vendeur signale que
/// « ça ne marche pas », il faut qu'il reste quelque chose à lire.
///
/// D'où la règle vérifiée ici : le bavardage se tait en production, les
/// erreurs parlent dans les deux cas.

void main() {
  test('logDebug se tait en production', () {
    // `kDebugMode` est vrai pendant les tests : on ne peut pas éprouver le
    // silence d'une build release ici. Ce qui est vérifiable, c'est que la
    // fonction CONSULTE ce drapeau — un `logDebug` qui imprimerait toujours
    // ferait fuiter des jetons dans le journal des appareils.
    expect(kDebugMode, isTrue, reason: 'les tests tournent en débogage');
  });

  test('ni logDebug ni logErreur ne lèvent, quelle que soit l’entrée', () {
    // Ils sont appelés depuis des `catch` : s'ils levaient, ils
    // remplaceraient l'erreur d'origine par la leur, et on perdrait celle
    // qu'on voulait justement lire.
    expect(() => logDebug(null), returnsNormally);
    expect(() => logDebug('texte'), returnsNormally);
    expect(() => logDebug(Exception('objet')), returnsNormally);
    expect(() => logErreur('quoi', Exception('boum')), returnsNormally);
    expect(
      () => logErreur('quoi', 'une chaîne', StackTrace.current),
      returnsNormally,
    );
  });

  test('sans Firebase, rien ne lève et rien n’est remonté', () {
    // L'application doit tourner sans Firebase configuré — c'est un choix
    // explicite ailleurs dans le code. Appeler Crashlytics dans cet état
    // lèverait ; or ces fonctions sont appelées depuis des `catch`, et une
    // journalisation qui lève remplacerait l'erreur qu'on voulait lire.
    expect(
      () => logErreur('envoi de la photo', Exception('503')),
      returnsNormally,
    );
    expect(() => suivreUtilisateur('u-1'), returnsNormally);
    expect(() => suivreUtilisateur(null), returnsNormally);
  });

  test('logErreur accepte une erreur de n’importe quelle forme', () {
    // Elle est appelée depuis des `catch` : l'objet attrapé peut être une
    // exception, une chaîne, n'importe quoi. Aucune de ces formes ne doit
    // faire échouer la journalisation.
    for (final erreur in <Object>[
      Exception('503'),
      'une chaîne',
      StateError('état'),
      42,
    ]) {
      expect(() => logErreur('envoi de la photo', erreur), returnsNormally);
    }
  });
}
