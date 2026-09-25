import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/favoris/domain/entities/boutique_suivie.dart';
import 'package:saambiz/features/favoris/domain/entities/suivi_boutique.dart';

/// Entités du suivi de boutique.
///
/// Le point vérifié ici : suivre une boutique et vouloir ses notifications
/// sont deux choses distinctes. Les confondre revient à réveiller des gens qui
/// n'ont rien demandé.
void main() {
  group('SuiviBoutique', () {
    test('une boutique jamais suivie n\'a pas de cloche', () {
      const suivi = SuiviBoutique.aucun('b1');
      expect(suivi.suivi, isFalse);
      expect(suivi.clocheActive, isFalse);
    });

    test('on peut suivre sans activer la cloche', () {
      const suivi = SuiviBoutique(boutiqueId: 'b1', suivi: true, clocheActive: false);
      expect(suivi.suivi, isTrue);
      expect(suivi.clocheActive, isFalse);
    });

    test('copyWith ne touche qu\'au champ demandé', () {
      const avant = SuiviBoutique(boutiqueId: 'b1', suivi: true, clocheActive: false);
      final apres = avant.copyWith(clocheActive: true);

      expect(apres.suivi, isTrue);
      expect(apres.clocheActive, isTrue);
      expect(apres.boutiqueId, 'b1');
    });

    test('deux états identiques sont égaux', () {
      // L'égalité de valeur évite les reconstructions inutiles de widgets.
      const a = SuiviBoutique(boutiqueId: 'b1', suivi: true, clocheActive: true);
      const b = SuiviBoutique(boutiqueId: 'b1', suivi: true, clocheActive: true);
      expect(a, equals(b));
    });
  });

  group('BoutiqueSuivie', () {
    test('la cloche est désactivée par défaut', () {
      const b = BoutiqueSuivie(id: 'b1', nom: 'Sañse Couture');
      expect(b.clocheActive, isFalse);
    });

    test('la localisation est facultative', () {
      // Toutes les boutiques n'en déclarent pas : l'entité ne doit pas
      // l'exiger, sinon la liste des favoris plante sur la première venue.
      const b = BoutiqueSuivie(id: 'b1', nom: 'Sañse Couture');
      expect(b.localisation, isNull);
    });

    test('copyWith bascule la cloche sans perdre le reste', () {
      const b = BoutiqueSuivie(
        id: 'b1', nom: 'Sañse Couture', logo: 'logo.png', localisation: 'Dakar',
      );
      final apres = b.copyWith(clocheActive: true);

      expect(apres.clocheActive, isTrue);
      expect(apres.nom, 'Sañse Couture');
      expect(apres.logo, 'logo.png');
      expect(apres.localisation, 'Dakar');
    });
  });
}
