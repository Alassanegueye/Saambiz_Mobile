import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/commande/data/models/commande_model.dart';
import 'package:saambiz/features/commande/presentation/widgets/sections_detail_commande.dart';

CommandeModel _commande({
  String statut = 'en_attente',
  String modeLivraison = 'livraison',
  DateTime? majLe,
}) => CommandeModel(
  id: 'c1',
  referenceCommande: 'CMD-2026-MZ8H9I',
  acheteurId: 'a1',
  vendeurId: 'v1',
  montantProduits: 4500,
  fraisLivraison: 1000,
  montantTotal: 5500,
  statut: statut,
  statutPaiement: 'non_paye',
  modeLivraison: modeLivraison,
  modePaiement: 'en_ligne',
  adresseLivraison: 'Dakar',
  numeroTelephone: '+221775929390',
  note: null,
  createdAt: DateTime(2026, 11, 15, 10, 42),
  updatedAt: majLe,
  lignes: [
    LigneCommandeModel(
      id: 'l1',
      produitId: 'p1',
      nomProduit: 'Baskets running',
      imageProduit: null,
      prixUnitaire: 4500,
      quantite: 1,
      sousTotal: 4500,
      options: const {'Pointure': '42', 'Couleur': 'Noir'},
    ),
  ],
  vendeurNom: 'Alassane GUEYE',
  vendeurTelephone: '+221775929390',
  boutiqueId: 'b1',
  boutiqueNom: 'FootShop',
);

Future<void> _afficher(WidgetTester tester, Widget section) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: section,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Détails de la commande', () {
    testWidgets('code, date et heure, statut en français', (tester) async {
      await _afficher(tester, CarteDetailsCommande(commande: _commande()));
      expect(find.text('Code de commande'), findsOneWidget);
      expect(find.text('CMD-2026-MZ8H9I'), findsOneWidget);
      expect(find.byTooltip('Copier le code'), findsOneWidget);
      expect(find.text('15 novembre 2026 à 10 h 42'), findsOneWidget);
      expect(find.text('En attente'), findsOneWidget);
      // Pas de mise à jour connue : pas de ligne vide.
      expect(find.text('Dernière mise à jour'), findsNothing);
    });

    testWidgets('la dernière mise à jour quand il y en a une', (tester) async {
      await _afficher(
        tester,
        CarteDetailsCommande(
          commande: _commande(
            statut: 'en_preparation',
            majLe: DateTime(2026, 11, 16, 9, 5),
          ),
        ),
      );
      expect(find.text('Dernière mise à jour'), findsOneWidget);
      expect(find.text('16 novembre 2026 à 9 h 05'), findsOneWidget);
    });
  });

  group('Articles', () {
    testWidgets('prix unitaire × quantité, options, montants', (tester) async {
      await _afficher(tester, CarteArticlesCommande(commande: _commande()));
      expect(find.text('1 article'), findsOneWidget);
      expect(find.text('Baskets running'), findsOneWidget);
      expect(find.text('4 500 FCFA × 1'), findsOneWidget);
      expect(find.text('Pointure : 42'), findsOneWidget);
      expect(find.text('Couleur : Noir'), findsOneWidget);
      expect(find.text('Sous-total'), findsOneWidget);
      expect(find.text('1 000 FCFA'), findsOneWidget);
      expect(find.text('5 500 FCFA'), findsOneWidget);
      // L'article mène à la fiche du produit.
      expect(find.text('Voir'), findsOneWidget);
    });

    testWidgets('retrait en boutique : pas de frais de livraison', (
      tester,
    ) async {
      await _afficher(
        tester,
        CarteArticlesCommande(commande: _commande(modeLivraison: 'retrait')),
      );
      expect(find.text('Retrait en boutique'), findsOneWidget);
    });
  });

  group('Boutique et vendeur', () {
    testWidgets('la fiche de la boutique complète ce que sait la commande', (
      tester,
    ) async {
      await _afficher(
        tester,
        CarteBoutiqueCommande(
          boutiqueId: 'b1',
          boutiqueNom: 'FootShop',
          boutiqueLogo: null,
          vendeurId: 'v1',
          vendeurNom: 'Alassane GUEYE',
          vendeurTelephone: '+221775929390',
          chargerBoutique: (id) async => {
            'id': id,
            'nom': 'FootShop',
            'verifiee': true,
            'categorie': 'Mode homme',
            'localisation': 'Dakar, Médina',
            'note': 4.5,
            'nombreAvis': 12,
            'whatsapp': '775929390',
          },
        ),
      );
      expect(find.text('Boutique et vendeur'), findsOneWidget);
      expect(find.text('FootShop'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(find.text('Mode homme'), findsOneWidget);
      expect(find.text('4,5 (12 avis)'), findsOneWidget);
      expect(find.text('Dakar, Médina'), findsOneWidget);
      expect(find.text('Alassane GUEYE'), findsOneWidget);
      for (final action in ['Boutique', 'Appeler', 'WhatsApp', 'Message']) {
        expect(find.text(action), findsOneWidget, reason: action);
      }
    });

    testWidgets('sans boutique connue : le vendeur seul', (tester) async {
      await _afficher(
        tester,
        const CarteBoutiqueCommande(
          boutiqueId: null,
          boutiqueNom: null,
          boutiqueLogo: null,
          vendeurId: 'v1',
          vendeurNom: 'Alassane GUEYE',
          vendeurTelephone: '+221775929390',
        ),
      );
      expect(find.text('Vendeur'), findsNWidgets(2));
      expect(find.text('Alassane GUEYE'), findsOneWidget);
      expect(find.text('Boutique'), findsNothing);
      expect(find.text('Appeler'), findsOneWidget);
    });

    testWidgets('la fiche injoignable n’efface rien', (tester) async {
      await _afficher(
        tester,
        CarteBoutiqueCommande(
          boutiqueId: 'b1',
          boutiqueNom: 'FootShop',
          boutiqueLogo: null,
          vendeurId: 'v1',
          vendeurNom: 'Alassane GUEYE',
          vendeurTelephone: '+221775929390',
          chargerBoutique: (_) async => throw Exception('hors ligne'),
        ),
      );
      expect(find.text('FootShop'), findsOneWidget);
      expect(find.text('Boutique'), findsOneWidget);
    });
  });
}
