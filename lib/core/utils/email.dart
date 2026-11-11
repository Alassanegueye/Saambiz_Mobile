import 'package:flutter/services.dart';

/// Format d'une adresse e-mail : partie locale, « @ », domaine avec au moins
/// un point et une extension de 2 lettres ou plus. Pas d'espace, pas de
/// point double, pas de point en début ou fin de partie.
final RegExp _formatEmail = RegExp(
  r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*"
  r'@[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*\.[A-Za-z]{2,}$',
);

bool estEmailValide(String saisie) {
  final e = saisie.trim();
  return e.length <= 254 && _formatEmail.hasMatch(e);
}

/// Message d'erreur, ou null si l'adresse est valable.
String? verifierEmail(String? saisie, {bool obligatoire = true}) {
  final e = (saisie ?? '').trim();
  if (e.isEmpty) return obligatoire ? 'Adresse e-mail requise.' : null;
  if (!estEmailValide(e)) {
    return 'Adresse e-mail invalide (ex. nom@exemple.com).';
  }
  return null;
}

/// À poser sur les champs e-mail : interdit les espaces et limite la taille.
final List<TextInputFormatter> formatsEmail = [
  FilteringTextInputFormatter.deny(RegExp(r'\s')),
  LengthLimitingTextInputFormatter(254),
];
