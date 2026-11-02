import 'package:flutter/material.dart';

/// Palette SaamBiz, relevée sur le logo : bleu marine #01154B et or #FBB900.
///
/// Fond gris clair neutre, surfaces blanches : le marine porte la structure
/// (en-têtes, textes, boutons), l'or signale ce qui compte (onglet actif,
/// remises, action principale). Le rouge et le vert restent réservés aux
/// erreurs et aux succès.
class AppColor {
  AppColor._();

  // Couleurs de la marque
  static const Color kPrimary = Color(0xFF01154B);
  static const Color kSecondary = Color(0xFFFBB900);

  // Déclinaisons du bleu
  static const Color kPrimaryDark = Color(0xFF000B30);
  static const Color kPrimaryMedium = Color(0xFF1D3F9E);

  /// Fond doux des pastilles d'icônes et des cartes sélectionnées : bleu
  /// très pâle.
  static const Color kPrimaryLight = Color(0xFFEDF0F8);

  // Déclinaisons de l'or
  static const Color kSecondaryDark = Color(0xFF9A6B00);
  static const Color kSecondaryLight = Color(0xFFFFF4D1);

  /// Anciens noms, conservés pour les écrans qui les utilisent encore.
  static const Color kAccent = kSecondary;
  static const Color kAccentLight = Color(0xFFFFCB3D);
  static const Color kAccentSoft = kPrimaryLight;

  // États
  static const Color kSucces = Color(0xFF13804A);
  static const Color kErreur = Color(0xFFC6382B);
  static const Color kSuccesLight = Color(0xFFDDF5E6);
  static const Color kErreurLight = Color(0xFFFBECE8);
  static const Color kAlerte = kSecondaryDark;
  static const Color kInfo = kPrimaryMedium;

  // Neutres
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kBlack = Color(0xFF0B1220);
  static const Color kGrayscaleDark100 = Color(0xFF0E1A3A);
  static const Color kGrayscale80 = Color(0xFF2F3A52);
  static const Color kGrayscale60 = Color(0xFF4B5568);
  static const Color kGrayscale40 = Color(0xFF667085);
  static const Color kGrayscale30 = Color(0xFF98A2B3);
  static const Color kGrayscale20 = Color(0xFFD9DEE7);
  static const Color kLine = Color(0xFFE6E9EF);

  /// Surface des champs et des lignes d'information dans une carte blanche.
  static const Color kSurface = Color(0xFFF7F8FA);

  /// Contour bleu clair (puces, cartes sélectionnées).
  static const Color kPrimaryBorder = Color(0xFFC9D2EA);
  static const Color kErreurBorder = Color(0xFFF2C9C1);

  static const Color kWhatsapp = Color(0xFF25D366);

  /// Fond des écrans : gris clair neutre.
  static const Color kBackground = Color(0xFFF4F5F8);
  static const Color kBackground2 = Color(0xFFEBEEF3);
  static const Color kOnBoardingColor = kWhite;
}
