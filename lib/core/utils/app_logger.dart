import 'package:flutter/foundation.dart';

/// Journalisation sécurisée.
///
/// N'imprime QU'EN mode débogage. En build release (production), aucun log
/// n'est émis → pas de fuite de données sensibles (tokens, mots de passe,
/// corps de requêtes) dans les logs de l'appareil.
void logDebug(Object? message) {
  if (kDebugMode) {
    // ignore: avoid_print
    print(message);
  }
}
