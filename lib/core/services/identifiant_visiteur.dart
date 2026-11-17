import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Identifiant anonyme de l'appareil, envoyé (`X-Visiteur`) à l'ouverture de
/// la page d'une boutique : le serveur compte ainsi une visite par personne
/// et par jour, même sans compte.
///
/// Sans lui, deux clients sans compte derrière la même adresse IP d'un
/// opérateur — et l'application envoie le même « Dart/… » à tous — ne
/// comptaient que pour un.
///
/// Tiré au hasard une fois, gardé sur l'appareil, lié à personne. Un client
/// connecté est reconnu par son compte : l'identifiant ne sert qu'aux autres.
class IdentifiantVisiteur {
  IdentifiantVisiteur._();

  static const cle = 'saambiz.identifiant_visiteur';
  static final _format = RegExp(r'^[0-9a-f]{32}$');

  /// L'identifiant de l'appareil, créé au premier appel.
  static String lire(SharedPreferences prefs, {Random? hasard}) {
    final existant = prefs.getString(cle);
    if (existant != null && _format.hasMatch(existant)) return existant;
    final r = hasard ?? Random.secure();
    final nouveau = [
      for (var i = 0; i < 16; i++)
        r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
    prefs.setString(cle, nouveau);
    return nouveau;
  }
}
