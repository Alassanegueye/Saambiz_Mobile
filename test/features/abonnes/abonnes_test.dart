import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/utils/texte.dart';
import 'package:saambiz/features/abonnes/abonne_detail_page.dart';
import 'package:saambiz/features/abonnes/abonnes_page.dart';

void main() {
  test('la date se lit en français', () {
    expect(dateLongue(DateTime(2024, 5, 12)), '12 mai 2024');
  });

  test('coordonnées vides : absentes, pas de ligne blanche', () {
    final a = Abonne.fromJson({'id': '1', 'prenom': 'Awa', 'telephone': ''});
    expect(a.email, isNull);
    expect(a.telephone, isNull);
  });

  test('la fiche lit activité et fidélité', () {
    final f = FicheAbonne.fromJson({
      'activite': {
        'commandes': 3,
        'produitsCommandes': 7,
        'derniereCommande': '2026-11-01T10:00:00.000Z',
      },
      'fidelite': 'fidele',
    });
    expect(f.commandes, 3);
    expect(f.produitsCommandes, 7);
    expect(f.derniereCommande, isNotNull);
    expect(f.fidele, isTrue);
  });

  test('sans commande : nouveau client, aucune date', () {
    final f = FicheAbonne.fromJson({
      'activite': {
        'commandes': 0,
        'produitsCommandes': 0,
        'derniereCommande': null,
      },
      'fidelite': 'nouveau',
    });
    expect(f.derniereCommande, isNull);
    expect(f.fidele, isFalse);
  });
}
