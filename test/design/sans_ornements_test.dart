import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les surfaces pleines doivent le rester.
///
/// Les dégradés diagonaux et les formes translucides posées dans un angle
/// sont revenus plusieurs fois, d'une refonte visuelle à l'autre : ils ne
/// cassent rien, aucun test d'interface ne les voit, et sur un vrai écran ils
/// se lisent comme des taches — un coin de carte plus clair que le reste,
/// sans raison apparente.
///
/// D'où ces lectures de fichiers. Elles ne jugent pas du goût : elles figent
/// une décision prise en regardant l'application sur un téléphone.
/// Le code d'un fichier, commentaires retirés.
///
/// Sans ça, le commentaire qui explique ce qu'on a enlevé — et qui cite la
/// ligne d'origine — fait échouer le test censé vérifier son absence.
String codeSeul(String chemin) => File(chemin)
    .readAsLinesSync()
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  /// Fichiers dont les grandes surfaces doivent être en aplat.
  const surfacesPleines = <String, String>{
    'lib/core/widgets/profil_kit.dart': 'la carte « Mon compte »',
    'lib/core/widgets/logo_boutique.dart': 'la pastille de logo par défaut',
    'lib/features/home/presentation/pages/acheteur/accueil_boutiques_page.dart':
        'le bandeau d’en-tête de l’accueil',
  };

  group('Aucun dégradé décoratif', () {
    surfacesPleines.forEach((chemin, quoi) {
      test('$quoi est en aplat', () {
        final code = codeSeul(chemin);
        expect(
          code,
          isNot(contains('LinearGradient')),
          reason: '$quoi a retrouvé un dégradé',
        );
      });
    });
  });

  group('Aucune forme décorative dans les angles', () {
    test('la bannière promo n’a plus de cercle hors cadre', () {
      // C'était un cercle doré de 110 px à 15 % d'opacité, calé en
      // `right: -20, top: -25` et rogné par le coin de la bannière.
      final code = codeSeul(
        'lib/features/home/presentation/pages/acheteur/home_page.dart',
      );
      expect(code, isNot(contains('top: -25')));
      expect(code, isNot(contains('right: -20')));
    });

    test('la couverture de boutique n’a plus de sac en filigrane', () {
      // Un `Icons.shopping_bag_rounded` de 150 px à 7 % de blanc.
      final code = codeSeul(
        'lib/features/catalogue/presentation/pages/boutique_publique_page.dart',
      );
      expect(code, isNot(contains('size: 150')));
      expect(code, isNot(contains('alpha: 0.07')));
    });
  });

  group('Ce qui doit rester', () {
    test('le voile sombre des pastilles sur une photo de couverture', () {
      // Celui-ci n'est pas un ornement : sans lui, les pastilles blanches
      // posées en haut de la couverture deviennent illisibles dès que la
      // boutique met une bannière claire.
      final code = File(
        'lib/features/catalogue/presentation/pages/boutique_publique_page.dart',
      ).readAsStringSync();
      expect(code, contains('Color(0x55000000)'));
    });

    test('le balayage des squelettes de chargement', () {
      // Un dégradé animé, pas une tache : il se déplace et signale que
      // l'écran attend des données.
      for (final chemin in const [
        'lib/core/widgets/shimmer_list.dart',
        'lib/core/widgets/animations.dart',
      ]) {
        expect(File(chemin).readAsStringSync(), contains('LinearGradient'));
      }
    });
  });
}
