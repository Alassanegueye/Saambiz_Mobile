import 'package:flutter/material.dart';

/// Palette SaamBiz, relevée sur le logo et l'icône de l'application :
/// bleu marine #01154B et or #FBB900.
///
/// Fonds blancs et gris bleuté très clair, comme le design d'origine : le
/// marine porte la structure (titres, boutons, icônes), l'or ne sert qu'à ce
/// qui doit attirer l'œil (remises, onglet actif, action principale sur fond
/// marine). Le rouge et le vert restent réservés aux erreurs et aux succès.
class AppColor {
  AppColor._();

  // Couleurs de la marque
  static const Color kPrimary = Color(0xFF01154B);
  static const Color kSecondary = Color(0xFFFBB900);

  // Déclinaisons du bleu
  static const Color kPrimaryDark = Color(0xFF000C33);

  /// Bleu plus clair : liens, valeurs secondaires, icônes d'information.
  static const Color kPrimaryMedium = Color(0xFF2B4A9C);

  /// Fond des pastilles d'icônes et des éléments sélectionnés.
  static const Color kPrimaryLight = Color(0xFFEDF1FA);

  // Déclinaisons de l'or
  /// Or foncé, lisible sur fond clair (texte, icône).
  static const Color kSecondaryDark = Color(0xFF8A5F00);
  static const Color kSecondaryLight = Color(0xFFFFF5D6);

  /// Anciens noms, conservés pour les écrans qui les utilisent encore.
  static const Color kAccent = kSecondary;
  static const Color kAccentLight = Color(0xFFFFCB3D);
  static const Color kAccentSoft = kPrimaryLight;

  // États
  static const Color kSucces = Color(0xFF12805C);
  static const Color kErreur = Color(0xFFC8372D);
  static const Color kSuccesLight = Color(0xFFE2F5EC);
  static const Color kErreurLight = Color(0xFFFCEDEA);
  static const Color kAlerte = kSecondaryDark;
  static const Color kInfo = kPrimaryMedium;

  // Neutres, légèrement bleutés pour rester dans la famille du marine
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kBlack = Color(0xFF0A1330);

  /// Titres et texte fort.
  static const Color kGrayscaleDark100 = Color(0xFF0B1638);

  /// Texte courant.
  static const Color kGrayscale80 = Color(0xFF2E3A55);
  static const Color kGrayscale60 = Color(0xFF4A5672);

  /// Texte secondaire (dates, villes, mentions).
  static const Color kGrayscale40 = Color(0xFF66708A);

  /// Texte désactivé, icônes discrètes, indications de champ.
  static const Color kGrayscale30 = Color(0xFF9AA3B8);
  static const Color kGrayscale20 = Color(0xFFDAE0EA);

  /// Filets et séparateurs.
  static const Color kLine = Color(0xFFE8ECF3);

  /// Surface des champs et des lignes d'information dans une carte blanche.
  static const Color kSurface = Color(0xFFF5F7FB);

  /// Contour bleu clair (puces, cartes sélectionnées).
  static const Color kPrimaryBorder = Color(0xFFC9D3EC);
  static const Color kErreurBorder = Color(0xFFF2C9C2);

  static const Color kWhatsapp = Color(0xFF25D366);

  /// Fond des écrans : blanc à peine bleuté, sur lequel les cartes blanches
  /// se détachent sans contour.
  static const Color kBackground = Color(0xFFF5F7FB);
  static const Color kBackground2 = Color(0xFFECF0F7);
  static const Color kOnBoardingColor = kWhite;
}
