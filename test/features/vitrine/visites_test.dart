import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/services/identifiant_visiteur.dart';
import 'package:saambiz/features/vitrine/data/models/vitrine_model.dart';
import 'package:saambiz/features/vitrine/presentation/lien_apercu.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Identifiant anonyme de l’appareil', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('créé une fois, puis toujours le même', () async {
      final prefs = await SharedPreferences.getInstance();
      final premier = IdentifiantVisiteur.lire(prefs, hasard: Random(1));
      expect(premier, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(IdentifiantVisiteur.lire(prefs, hasard: Random(2)), premier);
    });

    test('une valeur abîmée est remplacée', () async {
      SharedPreferences.setMockInitialValues({
        IdentifiantVisiteur.cle: 'pas-un-identifiant',
      });
      final prefs = await SharedPreferences.getInstance();
      expect(
        IdentifiantVisiteur.lire(prefs),
        matches(RegExp(r'^[0-9a-f]{32}$')),
      );
    });
  });

  group('Le site ouvert par son vendeur', () {
    test('est marqué « apercu » : ses passages ne comptent pas', () {
      expect(
        lienApercu('https://saambiz.com/b/footshop-1'),
        'https://saambiz.com/b/footshop-1?apercu=1',
      );
    });

    test('garde les paramètres existants', () {
      expect(
        lienApercu('https://saambiz.com/b/footshop-1?promo=1'),
        'https://saambiz.com/b/footshop-1?promo=1&apercu=1',
      );
    });

    test('une adresse incomplète reste telle quelle', () {
      expect(lienApercu('saambiz'), 'saambiz');
    });
  });

  group('Visites lues par Ma boutique', () {
    test('le total et la semaine', () {
      final v = VitrineModel.fromJson(const {
        'vitrine': {
          'slug': 'footshop-1',
          'vues': 9,
          'visitesRecentes': {
            'aujourdHui': 1,
            'septJours': 3,
            'trenteJours': 9,
          },
        },
      });
      expect(v.vues, 9);
      expect(v.visitesSemaine, 3);
    });

    test('un serveur pas encore à jour : la semaine vaut 0', () {
      final v = VitrineModel.fromJson(const {
        'vitrine': {'slug': 'footshop-1', 'vues': 9},
      });
      expect(v.vues, 9);
      expect(v.visitesSemaine, 0);
    });
  });
}
