import 'package:flutter/material.dart';
import 'app_color.dart';
import 'police.dart';

/// Échelle typographique de l'application.
///
/// Chaque page redéfinissait ses propres `TextStyle` : une même information,
/// un titre de section, un prix, n'avait pas la même taille d'un écran à
/// l'autre, et un changement de charte se faisait page par page.
///
/// Une seule famille, Plus Jakarta Sans (celle du design d'origine et de
/// Yobante Boutique), embarquée dans l'application : titres en gras serré,
/// texte courant en regular aéré. L'échelle elle-même, en nombres.
///
/// Séparée des `TextStyle` : les tailles sont la décision de design, la
/// police n'est que le rendu. Les isoler permet de les vérifier par un test
/// sans charger la moindre ressource.
class TailleTexte {
  TailleTexte._();

  static const double titreXL = 28;
  static const double titreL = 22;
  static const double titreM = 18;
  static const double titreS = 15.5;
  static const double corps = 14.5;
  static const double petit = 12.5;
  static const double minuscule = 11;
  static const double bouton = 15;
  static const double etiquette = 11.5;
  static const double prix = 15.5;
  static const double prixGrand = 22;
}

class AppTypo {
  AppTypo._();

  /// Famille de toute l'application.
  static const String famille = kPolice;

  /// Chiffres de même largeur : les montants d'une colonne s'alignent.
  static const List<FontFeature> chiffres = [FontFeature.tabularFigures()];

  // Titres
  static const TextStyle titreXL = TextStyle(
    fontFamily: kPolice,
    fontSize: TailleTexte.titreXL,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.8,
    color: AppColor.kGrayscaleDark100,
  );

  static const TextStyle titreL = TextStyle(
    fontFamily: kPolice,
    fontSize: TailleTexte.titreL,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColor.kGrayscaleDark100,
  );

  static const TextStyle titreM = TextStyle(
    fontFamily: kPolice,
    fontSize: TailleTexte.titreM,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
    color: AppColor.kGrayscaleDark100,
  );

  static const TextStyle titreS = TextStyle(
    fontFamily: kPolice,
    fontSize: TailleTexte.titreS,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColor.kGrayscaleDark100,
  );

  // Texte courant
  static const TextStyle corps = TextStyle(
    fontFamily: kPolice,
    fontSize: TailleTexte.corps,
    height: 1.5,
    color: AppColor.kGrayscale60,
  );

  static const TextStyle corpsFort = TextStyle(
    fontFamily: kPolice,
    fontSize: TailleTexte.corps,
    height: 1.45,
    fontWeight: FontWeight.w600,
    color: AppColor.kGrayscaleDark100,
  );

  static const TextStyle petit = TextStyle(
    fontFamily: kPolice,
    fontSize: TailleTexte.petit,
    height: 1.4,
    color: AppColor.kGrayscale40,
  );

  static const TextStyle minuscule = TextStyle(
    fontFamily: kPolice,
    fontSize: TailleTexte.minuscule,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: AppColor.kGrayscale40,
  );

  // Éléments d'interface
  static const TextStyle bouton = TextStyle(
    fontFamily: kPolice,
    fontSize: TailleTexte.bouton,
    fontWeight: FontWeight.w700,
    color: AppColor.kWhite,
  );

  /// Libellé court au-dessus d'un champ ou d'un groupe.
  static const TextStyle etiquette = TextStyle(
    fontFamily: kPolice,
    fontSize: TailleTexte.etiquette,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColor.kGrayscale40,
  );

  /// Prix : chiffres alignés, pour que les colonnes de montants tiennent.
  static const TextStyle prix = TextStyle(
    fontFamily: kPolice,
    fontSize: TailleTexte.prix,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColor.kPrimary,
    fontFeatures: chiffres,
  );

  static const TextStyle prixGrand = TextStyle(
    fontFamily: kPolice,
    fontSize: TailleTexte.prixGrand,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColor.kPrimary,
    fontFeatures: chiffres,
  );
}
