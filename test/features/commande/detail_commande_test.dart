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
  group('statutSuivantPourVendeur', () {
    test('acceptée et réglée à la réception : préparation possible', () {
      expect(
        statutSuivantPourVendeur('acceptee', modePaiement: 'a_la_livraison'),
        'en_preparation',
      );
      expect(
        statutSuivantPourVendeur('acceptee', modePaiement: 'retrait'),
        'en_preparation',
      );
    });

    test('acceptée mais à régler en ligne : rien tant qu’elle n’est pas payée', () {
      // Le serveur refuse la transition dans ce cas (commande.service.js) :
      // proposer le bouton serait promettre une action qui échouerait.
      expect(
        statutSuivantPourVendeur('acceptee', modePaiement: 'en_ligne'),
        isNull,
      );
    });

    test('la suite du parcours ne change pas', () {
      expect(
        statutSuivantPourVendeur('payee', modePaiement: 'en_ligne'),
        'en_preparation',
      );
      expect(
        statutSuivantPourVendeur('en_preparation', modePaiement: 'retrait'),
        'prete',
      );
      expect(
        statutSuivantPourVendeur('prete', modePaiement: 'retrait'),
        'en_livraison',
      );
      expect(
        statutSuivantPourVendeur('en_livraison', modePaiement: 'retrait'),
        'livree',
      );
    });

    test('une commande terminée ou annulée n’avance plus', () {
      for (final statut in const ['livree', 'annulee', 'rejetee']) {
        expect(
          statutSuivantPourVendeur(statut, modePaiement: 'retrait'),
          isNull,
          reason: '$statut ne doit mener nulle part',
        );
      }
    });
  });
}
