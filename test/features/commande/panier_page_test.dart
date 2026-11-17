import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/commande/data/models/panier_item.dart';
import 'package:saambiz/features/commande/data/services/panier_service.dart';
import 'package:saambiz/features/commande/presentation/pages/panier_page.dart';
import 'package:saambiz/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

PanierItem _article(String id, String vendeur) => PanierItem(
  produitId: id,
  nom: 'Produit $id',
  prix: 1000,
  image: '',
  vendeurId: vendeur,
  vendeurNom: 'Boutique $vendeur',
);

void main() {
  late PanierService panier;

  Future<void> remplir(List<PanierItem> articles) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    panier = PanierService(prefs: prefs);
    for (final a in articles) {
      await panier.ajouter(a);
    }
    await sl.reset();
    sl.registerSingleton<PanierService>(panier);
  }

  Future<void> ouvrir(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PanierPage()));
    await tester.pump();
  }

  group('Le panier à l’ouverture', () {
    testWidgets('une seule boutique : tout est coché d’office', (tester) async {
      await remplir([_article('p1', 'v1'), _article('p2', 'v1')]);
      await ouvrir(tester);

      expect(panier.nombreSelectionnes, 2);
      // La règle « une commande, une boutique » n'a pas à être rappelée.
      expect(find.textContaining('Une commande, une boutique'), findsNothing);
    });

    testWidgets('plusieurs boutiques : le client choisit, la règle est dite', (
      tester,
    ) async {
      await remplir([_article('p1', 'v1'), _article('p2', 'v2')]);
      await ouvrir(tester);

      expect(panier.selectionVide, isTrue);
      expect(find.textContaining('Une commande, une boutique'), findsOneWidget);
    });

    testWidgets('une sélection déjà faite est respectée', (tester) async {
      await remplir([_article('p1', 'v1'), _article('p2', 'v1')]);
      panier.basculer(panier.items.first.cle);
      await ouvrir(tester);

      expect(panier.nombreSelectionnes, 1);
    });
  });
}
