import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/theme/app_dimensions.dart';
import 'package:saambiz/core/theme/app_typo.dart';

/// Ce fichier contenait le test « Counter increments » généré par
/// `flutter create` — il vérifiait un compteur qui n'a jamais existé dans
/// cette application et échouait donc à chaque exécution. Un test rouge en
/// permanence finit par être ignoré, et emporte les vrais avec lui.
///
/// Il est remplacé par des contrôles sur le thème centralisé, dépendance
/// commune à toutes les pages.
///
/// On vérifie les **valeurs** de l'échelle, pas les `TextStyle` construits :
/// ces derniers passent par GoogleFonts, qui va chercher ses fichiers sur le
/// réseau. Un test qui dépend du réseau échoue en intégration continue et sur
/// un poste hors ligne.
void main() {
  group('Échelle typographique', () {
    test('les titres décroissent régulièrement', () {
      expect(TailleTexte.titreXL, greaterThan(TailleTexte.titreL));
      expect(TailleTexte.titreL, greaterThan(TailleTexte.titreM));
      expect(TailleTexte.titreM, greaterThan(TailleTexte.titreS));
    });

    test('le texte courant est plus grand que les mentions secondaires', () {
      expect(TailleTexte.corps, greaterThan(TailleTexte.petit));
      expect(TailleTexte.petit, greaterThan(TailleTexte.minuscule));
    });

    test('aucune taille ne descend sous le seuil de lisibilité', () {
      // 11 pt est le plancher raisonnable sur mobile ; en dessous, le texte
      // devient illisible pour une partie des utilisateurs.
      final toutes = [
        TailleTexte.titreXL, TailleTexte.titreL, TailleTexte.titreM,
        TailleTexte.titreS, TailleTexte.corps, TailleTexte.petit,
        TailleTexte.minuscule, TailleTexte.bouton, TailleTexte.etiquette,
        TailleTexte.prix, TailleTexte.prixGrand,
      ];
      for (final t in toutes) {
        expect(t, greaterThanOrEqualTo(11));
      }
    });

    test('un prix se lit plus gros que le texte courant', () {
      expect(TailleTexte.prix, greaterThan(TailleTexte.corps));
      expect(TailleTexte.prixGrand, greaterThan(TailleTexte.prix));
    });
  });

  group('Échelle d\'espacement', () {
    test('la progression est strictement croissante', () {
      expect(AppDim.xs, lessThan(AppDim.sm));
      expect(AppDim.sm, lessThan(AppDim.md));
      expect(AppDim.md, lessThan(AppDim.lg));
      expect(AppDim.lg, lessThan(AppDim.xl));
      expect(AppDim.xl, lessThan(AppDim.xxl));
    });

    test('les cibles tactiles respectent le minimum des plateformes', () {
      // 48 dp : en dessous, le bouton devient difficile à atteindre au pouce.
      expect(AppDim.hauteurBouton, greaterThanOrEqualTo(AppDim.cibleTactileMin));
      expect(AppDim.hauteurChamp, greaterThanOrEqualTo(AppDim.cibleTactileMin));
    });

    test('les rayons suivent une progression croissante', () {
      expect(AppDim.rayonPetit, lessThan(AppDim.rayonMoyen));
      expect(AppDim.rayonMoyen, lessThan(AppDim.rayonGrand));
      expect(AppDim.rayonGrand, lessThan(AppDim.rayonCarte));
    });
  });

  group('Charte graphique', () {
    test('la palette expose un primaire et un accent distincts', () {
      // Bleu marine et or : les mêmes valeurs que le site vitrine et les deux
      // interfaces web. Un écart ici se voit sur les captures des stores.
      expect(AppColor.kPrimary, isA<Color>());
      expect(AppColor.kAccent, isA<Color>());
      expect(AppColor.kPrimary, isNot(equals(AppColor.kAccent)));
    });

    test('les nuances de gris sont ordonnées du foncé au clair', () {
      expect(AppColor.kGrayscale80.computeLuminance(),
          lessThan(AppColor.kGrayscale40.computeLuminance()));
      expect(AppColor.kGrayscale40.computeLuminance(),
          lessThan(AppColor.kGrayscale20.computeLuminance()));
    });

    test('le texte fort contraste suffisamment avec le fond', () {
      // Repère WCAG AA pour du texte courant : rapport de 4,5:1.
      final clair = AppColor.kBackground.computeLuminance() + 0.05;
      final fonce = AppColor.kBlack.computeLuminance() + 0.05;
      expect(clair / fonce, greaterThan(4.5));
    });
  });
}
