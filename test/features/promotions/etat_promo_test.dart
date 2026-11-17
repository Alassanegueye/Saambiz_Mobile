import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/promotions/data/models/promotion_model.dart';
import 'package:saambiz/features/promotions/presentation/pages/mes_promotions_page.dart';

final _maintenant = DateTime(2026, 11, 17, 10);

PromotionModel _promo({Duration? debut, Duration? fin}) => PromotionModel(
  id: 'pr1',
  titre: 'Soldes',
  description: '',
  prixPromo: 14900,
  produitId: 'p1',
  dateDebut: debut == null ? null : _maintenant.add(debut),
  dateFin: fin == null ? null : _maintenant.add(fin),
);

void main() {
  group('L’état d’une promotion, côté vendeur', () {
    test('terminée : la date de fin est passée', () {
      final (etat, libelle) = etatPromo(
        _promo(debut: const Duration(days: -20), fin: const Duration(days: -6)),
        maintenant: _maintenant,
      );
      expect(etat, EtatPromo.terminee);
      expect(libelle, 'Terminée le 11/11/2026');
    });

    test('à venir : elle n’a pas encore commencé', () {
      final (etat, libelle) = etatPromo(
        _promo(debut: const Duration(days: 3), fin: const Duration(days: 10)),
        maintenant: _maintenant,
      );
      expect(etat, EtatPromo.aVenir);
      expect(libelle, 'Commence le 20/11/2026');
    });

    test('en cours : le temps qui reste, en minuscules après le point', () {
      final (etat, libelle) = etatPromo(
        _promo(debut: const Duration(days: -2), fin: const Duration(days: 5)),
        maintenant: _maintenant,
      );
      expect(etat, EtatPromo.enCours);
      expect(libelle, 'En cours · plus que 5 jours');
    });

    test('bientôt finie à moins de deux jours de la fin', () {
      final (etat, libelle) = etatPromo(
        _promo(fin: const Duration(hours: 30)),
        maintenant: _maintenant,
      );
      expect(etat, EtatPromo.bientotFinie);
      expect(libelle, 'En cours · plus qu’un jour');
    });

    test('sans dates, elle est simplement en cours', () {
      expect(etatPromo(_promo(), maintenant: _maintenant), (
        EtatPromo.enCours,
        'En cours',
      ));
    });
  });
}
