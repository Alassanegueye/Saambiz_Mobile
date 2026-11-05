import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/commande/presentation/pages/commande_detail_page.dart';

void main() {
  group('etapesSuiviCommande', () {
    test('paiement en ligne : l\'étape « Payée » existe', () {
      final etapes = etapesSuiviCommande(
        'en_attente',
        modePaiement: 'en_ligne',
      );
      expect(etapes, contains('payee'));
      expect(etapes, isNot(contains('confirmee')));
    });

    test('à la réception : pas d\'étape « Payée »', () {
      expect(
        etapesSuiviCommande('acceptee', modePaiement: 'a_la_livraison'),
        isNot(contains('payee')),
      );
    });

    test('ancienne commande : son statut figure dans le suivi', () {
      final etapes = etapesSuiviCommande(
        'confirmee',
        modePaiement: 'a_la_livraison',
      );
      expect(etapes, contains('confirmee'));
      expect(etapes, isNot(contains('acceptee')));
    });
  });

  group('messageStatutCommande', () {
    test('le vendeur et le client lisent chacun leur message', () {
      expect(
        messageStatutCommande(
          'en_attente',
          modePaiement: 'en_ligne',
          isVendeur: true,
        ),
        contains('acceptez ou rejetez'),
      );
      expect(
        messageStatutCommande(
          'en_attente',
          modePaiement: 'en_ligne',
          isVendeur: false,
        ),
        contains('doit encore accepter'),
      );
    });

    test('commande acceptée : le message suit le mode de paiement', () {
      expect(
        messageStatutCommande(
          'acceptee',
          modePaiement: 'en_ligne',
          isVendeur: false,
        ),
        contains('payer'),
      );
      expect(
        messageStatutCommande(
          'acceptee',
          modePaiement: 'a_la_livraison',
          isVendeur: false,
        ),
        contains('à la réception'),
      );
    });
  });
}
