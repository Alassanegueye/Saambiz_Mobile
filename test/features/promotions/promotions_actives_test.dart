import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/promotions/data/models/promotion_model.dart';
import 'package:saambiz/features/promotions/presentation/pages/promotions_actives_page.dart';

void main() {
  group('Une promotion lue au serveur', () {
    test('le produit arrive sous « Produit » (inclus sans alias)', () {
      // C'est la forme réelle de GET /promotions/actives : Sequelize range
      // le produit sous le nom du modèle. Lue sous « produit » seulement,
      // la promotion n'avait ni photo ni nom de produit.
      final p = PromotionModel.fromJson({
        'id': 'pr1',
        'titre': 'Soldes de la Tabaski',
        'prixPromo': 14900,
        'Produit': {
          'id': 'p1',
          'nom': 'Robe wax',
          'prix': 18500,
          'image': 'robe.jpg',
        },
      });
      expect(p.produitNom, 'Robe wax');
      expect(p.produitImage, 'robe.jpg');
      expect(p.produitId, 'p1');
      expect(p.remise, 19);
    });

    test('« produit » en minuscules reste lu', () {
      final p = PromotionModel.fromJson({
        'id': 'pr1',
        'titre': 'Offre',
        'prixPromo': '6400',
        'produit': {'id': 'p18', 'nom': 'Foulard', 'prix': '8000'},
      });
      expect(p.produitNom, 'Foulard');
      expect(p.remise, 20);
    });

    test('sans prix normal, pas de remise inventée', () {
      final p = PromotionModel.fromJson({
        'id': 'pr1',
        'titre': 'Offre',
        'prixPromo': 5000,
      });
      expect(p.remise, isNull);
    });
  });

  group('Ce qu’il reste de temps', () {
    final maintenant = DateTime(2026, 11, 17, 12);

    test('en mots, jusqu’à un mois', () {
      expect(
        libelleFinPromo(
          maintenant.add(const Duration(hours: 5)),
          maintenant: maintenant,
        ),
        'Dernières heures',
      );
      expect(
        libelleFinPromo(
          maintenant.add(const Duration(hours: 30)),
          maintenant: maintenant,
        ),
        'Plus qu’un jour',
      );
      expect(
        libelleFinPromo(
          maintenant.add(const Duration(days: 3, hours: 1)),
          maintenant: maintenant,
        ),
        'Plus que 3 jours',
      );
    });

    test('terminée ou sans fin : rien', () {
      expect(
        libelleFinPromo(
          maintenant.subtract(const Duration(hours: 1)),
          maintenant: maintenant,
        ),
        isNull,
      );
      expect(libelleFinPromo(null, maintenant: maintenant), isNull);
    });
  });
}
