import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/commande/data/models/commande_model.dart';
import 'package:saambiz/features/commande/presentation/widgets/commande_card.dart';

CommandeModel _commande(
  String statut, {
  String modePaiement = 'a_la_livraison',
  String statutPaiement = 'non_paye',
  String? boutiqueNom = 'FootShop',
}) => CommandeModel(
  id: 'c1',
  referenceCommande: 'CMD-2026-N9WEBH',
  acheteurId: 'a1',
  vendeurId: 'v1',
  montantProduits: 9000,
  fraisLivraison: 0,
  montantTotal: 9000,
  statut: statut,
  statutPaiement: statutPaiement,
  modeLivraison: 'livraison',
  modePaiement: modePaiement,
  adresseLivraison: 'Dakar, Sénégal',
  numeroTelephone: null,
  note: null,
  createdAt: DateTime(2026, 11, 12),
  lignes: const [],
  vendeurNom: 'Alassane GUEYE',
  boutiqueNom: boutiqueNom,
);

Future<void> _afficher(WidgetTester tester, CommandeModel commande) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: CommandeCard(commande: commande, onTap: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Carte commande : le statut en français, dans son parcours', () {
    testWidgets('plus de ruban anglais, quel que soit le statut', (
      tester,
    ) async {
      for (final statut in kStatutCommandeLabels.keys) {
        await _afficher(tester, _commande(statut));
        expect(
          find.textContaining(RegExp('PROCESS|TRANSIT|ATTENTE|LIVRÉE')),
          findsNothing,
          reason: statut,
        );
      }
    });

    testWidgets('en préparation : étape 3 sur 6, nom en français', (
      tester,
    ) async {
      await _afficher(tester, _commande('en_preparation'));
      expect(find.text('Étape 3 sur 6'), findsOneWidget);
      expect(find.text('En préparation'), findsOneWidget);
      expect(find.text('Le vendeur prépare votre colis'), findsOneWidget);
      // Les deux étapes passées sont cochées, l'étape en cours est numérotée.
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('paiement en ligne : l’étape « Payée » s’ajoute', (
      tester,
    ) async {
      await _afficher(
        tester,
        _commande('en_attente', modePaiement: 'en_ligne'),
      );
      expect(find.text('Étape 1 sur 7'), findsOneWidget);
      expect(find.text('En attente'), findsOneWidget);
    });

    testWidgets('livrée : toutes les étapes sont cochées', (tester) async {
      await _afficher(tester, _commande('livree'));
      expect(find.text('Étape 6 sur 6'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(6));
    });

    testWidgets('annulée : un bandeau, pas de parcours', (tester) async {
      await _afficher(tester, _commande('annulee'));
      expect(find.text('Commande annulée'), findsOneWidget);
      expect(find.textContaining('Étape'), findsNothing);
      expect(find.byType(FriseSuiviCommande), findsNothing);
    });

    testWidgets('le nom de l’étape avance avec le statut', (tester) async {
      await _afficher(tester, _commande('en_attente'));
      final auDebut = tester.getCenter(find.text('En attente')).dx;

      await _afficher(tester, _commande('en_preparation'));
      final auMilieu = tester.getCenter(find.text('En préparation')).dx;

      await _afficher(tester, _commande('en_livraison'));
      final versLaFin = tester.getCenter(find.text('En livraison')).dx;

      expect(auMilieu, greaterThan(auDebut));
      expect(versLaFin, greaterThan(auMilieu));
    });
  });

  group('Carte commande : qui vend, et sous quel code', () {
    testWidgets('« Code » remplace « ID »', (tester) async {
      await _afficher(tester, _commande('en_attente'));
      expect(find.textContaining('ID'), findsNothing);
      expect(find.textContaining('Code'), findsOneWidget);
      expect(find.textContaining('CMD-2026-N9WEBH'), findsOneWidget);
      expect(find.textContaining('#'), findsNothing);
    });

    testWidgets('la boutique, puis son vendeur', (tester) async {
      await _afficher(tester, _commande('en_preparation'));
      expect(find.text('FootShop'), findsOneWidget);
      // Espace insécable avant « : », comme partout en français.
      expect(find.text('Vendeur\u00A0: Alassane GUEYE'), findsOneWidget);
    });

    testWidgets('sans boutique connue, le vendeur seul', (tester) async {
      await _afficher(tester, _commande('en_preparation', boutiqueNom: null));
      expect(find.text('Alassane GUEYE'), findsOneWidget);
      expect(find.textContaining('Vendeur'), findsNothing);
    });

    testWidgets('l’état du paiement est écrit', (tester) async {
      await _afficher(tester, _commande('livree', statutPaiement: 'paye'));
      expect(find.text('Payée'), findsOneWidget);

      await _afficher(tester, _commande('en_attente'));
      expect(find.text('À la livraison'), findsOneWidget);

      await _afficher(tester, _commande('acceptee', modePaiement: 'en_ligne'));
      expect(find.text('Non payée'), findsOneWidget);
    });
  });
}
