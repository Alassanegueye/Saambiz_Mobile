import 'package:flutter/material.dart';

/// Palette SaamBiz : bleu marine #0D1B3D et or #F2B705 — les couleurs du site
/// saambiz.com. Les autres teintes en sont des déclinaisons, à l'exception du
/// rouge et du vert réservés aux erreurs et aux succès.
///
/// Organisation reprise de l'application Yobante Boutique : mêmes noms de
/// jetons, pour que les écrans partagent la même construction.
class AppColor {
  AppColor._();

  // ── Couleurs de la marque ──────────────────────────────────────────────────
  static const Color kPrimary = Color(0xFF0D1B3D);
  static const Color kSecondary = Color(0xFFF2B705);

  // ── Déclinaisons du bleu ───────────────────────────────────────────────────
  static const Color kPrimaryDark = Color(0xFF060F26);
  static const Color kPrimaryMedium = Color(0xFF1E3A78);

  /// Fond bleu très clair (pastilles d'icônes, cartes sélectionnées).
  static const Color kPrimaryLight = Color(0xFFE8EDF7);

  // ── Déclinaisons de l'or ───────────────────────────────────────────────────
  static const Color kSecondaryDark = Color(0xFF8A6503);
  static const Color kSecondaryLight = Color(0xFFFEF3D6);

  /// Anciens noms, conservés pour les écrans qui les utilisent encore.
  static const Color kAccent = kSecondary;
  static const Color kAccentLight = Color(0xFFFFC93C);
  static const Color kAccentSoft = kPrimaryLight;

  // ── États ──────────────────────────────────────────────────────────────────
  static const Color kSucces = Color(0xFF15803D);
  static const Color kErreur = Color(0xFFC62828);
  static const Color kSuccesLight = Color(0xFFDCFCE7);
  static const Color kErreurLight = Color(0xFFFBEAEA);
  static const Color kAlerte = kSecondaryDark;
  static const Color kInfo = kPrimaryMedium;

  // ── Neutres ────────────────────────────────────────────────────────────────
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kBlack = Color(0xFF0D0D0F);
  static const Color kGrayscaleDark100 = Color(0xFF0D1B3D);
  static const Color kGrayscale80 = Color(0xFF2C3E63);
  static const Color kGrayscale60 = Color(0xFF4A5875);
  static const Color kGrayscale40 = Color(0xFF5B6C8A);
  static const Color kGrayscale30 = Color(0xFF93A1B8);
  static const Color kGrayscale20 = Color(0xFFDCE2EC);
  static const Color kLine = Color(0xFFE3E8F0);

  /// Surface des champs et des lignes d'information dans une carte blanche.
  static const Color kSurface = Color(0xFFF7F9FC);

  /// Contour bleu clair (puces, cartes sélectionnées).
  static const Color kPrimaryBorder = Color(0xFFC5D3E8);
  static const Color kErreurBorder = Color(0xFFF3C4C4);

  static const Color kWhatsapp = Color(0xFF25D366);

  /// Fond des écrans : blanc légèrement teinté de bleu.
  static const Color kBackground = Color(0xFFF5F7FB);
  static const Color kBackground2 = Color(0xFFEDF1F8);
  static const Color kOnBoardingColor = kWhite;
}
