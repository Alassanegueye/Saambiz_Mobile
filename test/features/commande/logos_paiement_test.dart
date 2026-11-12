import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Les logos des opérateurs affichés au choix du mode de paiement.
///
/// `_LogoOperateur` pose un `errorBuilder` : un chemin erroné ne fait donc
/// PAS planter l'écran, il retombe sur l'icône générique. C'est voulu — mieux
/// qu'une croix rouge par-dessus le formulaire de commande — mais ça rend la
/// panne silencieuse : on croit avoir mis les logos, l'application affiche
/// l'ancienne icône, et rien ne le signale.
///
/// Deux causes possibles, toutes deux couvertes ici : le fichier manque (ou
/// n'est pas une image lisible), ou il n'est pas déclaré dans la section
/// `assets:` du pubspec — présent sur le disque, absent de l'application.
///
/// `rootBundle` ne sert à rien pour ça : sous `flutter test` il lit le
/// système de fichiers, pas le bundle réellement construit. On vérifie donc
/// le fichier d'un côté, sa déclaration de l'autre.
const _pageCheckout = 'lib/features/commande/presentation/pages/checkout_page.dart';

/// Les entrées `assets:` du pubspec. Une entrée qui finit par `/` couvre tout
/// son dossier, comme le fait Flutter à la construction.
List<String> _assetsDeclares() {
  final lignes = File('pubspec.yaml').readAsLinesSync();
  final debut = lignes.indexWhere((l) => l.trimRight().endsWith('assets:'));
  expect(debut, isNot(-1), reason: 'pubspec.yaml n\'a pas de section assets:.');

  final declares = <String>[];
  for (final ligne in lignes.skip(debut + 1)) {
    final t = ligne.trim();
    if (t.startsWith('- ')) {
      declares.add(t.substring(2).trim());
    } else if (t.isNotEmpty && !t.startsWith('#')) {
      break; // Fin de la liste : on est passé à une autre clé.
    }
  }
  return declares;
}

bool _estCouvert(String chemin, List<String> declares) => declares.any(
      (d) => d.endsWith('/') ? chemin.startsWith(d) : d == chemin,
    );

void main() {
  // Les chemins tels qu'ils sont écrits dans checkout_page.dart.
  const logos = {
    'Wave': 'assets/images/wave.jpg',
    'Orange Money': 'assets/images/OM.png',
  };

  group('Logos des opérateurs de paiement', () {
    for (final entree in logos.entries) {
      test('${entree.key} : le fichier est une image lisible', () async {
        final fichier = File(entree.value);
        expect(
          fichier.existsSync(),
          isTrue,
          reason: '${entree.value} est absent du dépôt.',
        );

        final codec = await ui.instantiateImageCodec(
          await fichier.readAsBytes(),
        );
        final image = (await codec.getNextFrame()).image;

        expect(image.width, greaterThan(0));
        expect(image.height, greaterThan(0));
      });

      test('${entree.key} : le pubspec l\'embarque', () {
        expect(
          _estCouvert(entree.value, _assetsDeclares()),
          isTrue,
          reason: '${entree.value} existe mais aucune entrée assets: du '
              'pubspec ne le couvre : il ne partira pas dans l\'application.',
        );
      });
    }

    test('les logos cités par l\'écran de commande existent tous', () {
      // Garde-fou contre une faute de frappe introduite plus tard : on relit
      // la source et on vérifie chaque asset qu'elle nomme.
      final cites = RegExp(r"'(assets/[^']+)'")
          .allMatches(File(_pageCheckout).readAsStringSync())
          .map((m) => m.group(1)!)
          .toSet();

      expect(
        cites,
        containsAll(logos.values),
        reason: 'checkout_page.dart ne cite plus les deux logos.',
      );

      final declares = _assetsDeclares();
      for (final chemin in cites) {
        expect(File(chemin).existsSync(), isTrue, reason: '$chemin : absent.');
        expect(_estCouvert(chemin, declares), isTrue, reason: '$chemin : non déclaré.');
      }
    });
  });
}
