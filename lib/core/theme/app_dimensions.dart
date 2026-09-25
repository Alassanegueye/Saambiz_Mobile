import 'package:flutter/material.dart';

/// Espacements, rayons et tailles.
///
/// Une échelle plutôt que des valeurs libres : sans elle, on trouve dans le
/// même écran des marges de 14, 15 et 16 pixels, et le désalignement se voit
/// sans qu'on sache d'où il vient.
class AppDim {
  AppDim._();

  // ─── Espacements — progression x1,5 environ ───────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Marge latérale des écrans. Toutes les pages s'alignent dessus.
  static const double margeEcran = 20;

  // ─── Rayons ───────────────────────────────────────────────────────────────
  static const double rayonPetit = 8;
  static const double rayonMoyen = 12;
  static const double rayonGrand = 16;
  static const double rayonCarte = 18;
  static const double rayonPastille = 999;

  static BorderRadius get brPetit => BorderRadius.circular(rayonPetit);
  static BorderRadius get brMoyen => BorderRadius.circular(rayonMoyen);
  static BorderRadius get brGrand => BorderRadius.circular(rayonGrand);
  static BorderRadius get brCarte => BorderRadius.circular(rayonCarte);

  // ─── Tailles d'éléments ───────────────────────────────────────────────────
  static const double hauteurBouton = 52;
  static const double hauteurChamp = 52;
  static const double hauteurBarreNav = 64;
  static const double tailleIcone = 22;
  static const double tailleIconePetite = 18;
  static const double tailleAvatar = 44;

  /// Cible tactile minimale recommandée par les deux plateformes.
  static const double cibleTactileMin = 48;

  // ─── Ombres ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get ombreCarte => [
        BoxShadow(
          color: const Color(0xFF0D1B3D).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get ombreFlottante => [
        BoxShadow(
          color: const Color(0xFF0D1B3D).withValues(alpha: 0.16),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];
}
