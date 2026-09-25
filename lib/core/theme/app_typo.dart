import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color.dart';

/// Échelle typographique de l'application.
///
/// Chaque page redéfinissait ses propres `TextStyle` : une même information —
/// un titre de section, un prix — n'avait pas la même taille d'un écran à
/// l'autre, et un changement de charte se faisait page par page.
///
/// Deux familles, comme sur le site vitrine : Sora pour les titres (elle a du
/// caractère et se tient en gras), DM Sans pour le texte courant (elle se lit
/// en petit corps, ce dont une liste de produits a besoin).
/// L'échelle elle-même, en nombres.
///
/// Séparée des `TextStyle` : les tailles sont la décision de design, la
/// police n'est que le rendu. Les isoler permet de les vérifier par un test
/// sans charger la moindre ressource — GoogleFonts va chercher ses fichiers
/// sur le réseau, ce qu'un test ne doit jamais faire.
class TailleTexte {
  TailleTexte._();

  static const double titreXL = 28;
  static const double titreL = 23;
  static const double titreM = 18;
  static const double titreS = 15.5;
  static const double corps = 14.5;
  static const double petit = 12.5;
  static const double minuscule = 11;
  static const double bouton = 15;
  static const double etiquette = 11;
  static const double prix = 16;
  static const double prixGrand = 22;
}

class AppTypo {
  AppTypo._();

  // ─── Titres ───────────────────────────────────────────────────────────────
  static TextStyle get titreXL => GoogleFonts.sora(
        fontSize: TailleTexte.titreXL, fontWeight: FontWeight.w800, height: 1.15,
        letterSpacing: -0.8, color: AppColor.kPrimaryDark,
      );

  static TextStyle get titreL => GoogleFonts.sora(
        fontSize: TailleTexte.titreL, fontWeight: FontWeight.w700, height: 1.2,
        letterSpacing: -0.5, color: AppColor.kPrimaryDark,
      );

  static TextStyle get titreM => GoogleFonts.sora(
        fontSize: TailleTexte.titreM, fontWeight: FontWeight.w700, height: 1.25,
        color: AppColor.kPrimaryDark,
      );

  static TextStyle get titreS => GoogleFonts.sora(
        fontSize: TailleTexte.titreS, fontWeight: FontWeight.w600, height: 1.3,
        color: AppColor.kPrimaryDark,
      );

  // ─── Texte courant ────────────────────────────────────────────────────────
  static TextStyle get corps => GoogleFonts.dmSans(
        fontSize: TailleTexte.corps, height: 1.55, color: AppColor.kGrayscale60,
      );

  static TextStyle get corpsFort => GoogleFonts.dmSans(
        fontSize: TailleTexte.corps, height: 1.55, fontWeight: FontWeight.w600,
        color: AppColor.kBlack,
      );

  static TextStyle get petit => GoogleFonts.dmSans(
        fontSize: TailleTexte.petit, height: 1.45, color: AppColor.kGrayscale40,
      );

  static TextStyle get minuscule => GoogleFonts.dmSans(
        fontSize: TailleTexte.minuscule, height: 1.35, color: AppColor.kGrayscale40,
      );

  // ─── Éléments d'interface ─────────────────────────────────────────────────
  static TextStyle get bouton => GoogleFonts.sora(
        fontSize: TailleTexte.bouton, fontWeight: FontWeight.w700, color: AppColor.kWhite,
      );

  /// Libellé en capitales — sections, en-têtes de colonnes.
  static TextStyle get etiquette => GoogleFonts.dmSans(
        fontSize: TailleTexte.etiquette, fontWeight: FontWeight.w700, letterSpacing: 0.8,
        color: AppColor.kGrayscale40,
      );

  /// Prix : chiffres alignés, pour que les colonnes de montants tiennent.
  static TextStyle get prix => GoogleFonts.sora(
        fontSize: TailleTexte.prix, fontWeight: FontWeight.w700, color: AppColor.kPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get prixGrand => GoogleFonts.sora(
        fontSize: TailleTexte.prixGrand, fontWeight: FontWeight.w800, color: AppColor.kPrimaryDark,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
