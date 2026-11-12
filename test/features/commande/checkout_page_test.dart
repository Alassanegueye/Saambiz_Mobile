import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/commande/data/datasources/commande_remote_datasource.dart';
import 'package:saambiz/features/commande/data/models/commande_model.dart';
import 'package:saambiz/features/commande/data/models/panier_item.dart';
import 'package:saambiz/features/commande/data/repositories/commande_repository.dart';
import 'package:saambiz/features/commande/data/services/panier_service.dart';
import 'package:saambiz/features/commande/presentation/bloc/commande_bloc.dart';
import 'package:saambiz/features/commande/presentation/pages/checkout_page.dart';
import 'package:saambiz/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Source distante factice : enregistre le corps envoyé à POST /commandes.
class _FausseSource implements CommandeRemoteDataSource {
  Map<String, dynamic>? corps;

  @override
  Future<CommandeModel> creerCommande(Map<String, dynamic> body) async {
    corps = body;
    return CommandeModel.fromJson({
      'id': 'c1',
      'referenceCommande': 'CMD-1',
      'montantProduits': 10000,
      'montantTotal': 10000,
      'statut': 'en_attente',
      'modePaiement': body['modePaiement'],
      'modeLivraison': body['modeLivraison'],
    });
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late _FausseSource source;
  late PanierService panier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    panier = PanierService(prefs: prefs);
    await panier.ajouter(
      PanierItem(
        produitId: 'p1',
        nom: 'Chemise wax',
        prix: 5000,
        image: '',
        vendeurId: 'v1',
        vendeurNom: 'Aloushop',
        quantite: 2,
      ),
    );
    panier.basculer(panier.items.first.cle);
    source = _FausseSource();
    await sl.reset();
    sl.registerSingleton<PanierService>(panier);
    sl.registerFactory<CommandeBloc>(
      () => CommandeBloc(CommandeRepository(source)),
    );
  });

  tearDown(() => sl.reset());

  /// Le champ dont le libellé (« Téléphone * », texte enrichi) commence par
  /// [libelle].
  Finder champ(String libelle) => find
      .ancestor(
        of: find.textContaining(libelle, findRichText: true),
        matching: find.byType(TextFormField),
      )
      .first;

  Future<void> ouvrir(WidgetTester tester) async {
    // Écran haut : tout le formulaire tient sans défilement, la ListView
    // construit donc chaque champ.
    tester.view.physicalSize = const Size(1179, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: const CheckoutPage(),
        onGenerateRoute: (s) => MaterialPageRoute(
          builder: (_) => Scaffold(body: Text('route:${s.name}')),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('la page affiche tout le formulaire, sans erreur de mise en page',
      (tester) async {
    await ouvrir(tester);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Confirmer'), findsOneWidget);
    expect(find.text('Mode de réception'), findsOneWidget);
    expect(find.text('Livraison'), findsOneWidget);
    expect(find.text('Retrait'), findsOneWidget);
    expect(find.text('Paiement'), findsOneWidget);
    expect(find.text('Wave ou Orange Money'), findsOneWidget);
    expect(find.text('À la réception'), findsOneWidget);
  });

  testWidgets('le récapitulatif liste les produits cochés et le total',
      (tester) async {
    await ouvrir(tester);
    expect(find.text('Récapitulatif'), findsOneWidget);
    expect(find.text('Chemise wax'), findsOneWidget);
    expect(find.text('Aloushop'), findsWidgets);
  });

  testWidgets('une commande en retrait, payée à la réception, part au serveur',
      (tester) async {
    await ouvrir(tester);
    await tester.tap(find.text('Retrait'));
    await tester.pump();
    await tester.tap(find.text('À la réception'));
    await tester.pump();
    await tester.enterText(
      champ('Téléphone'),
      '771234567',
    );
    final bouton = find.textContaining('Confirmer');
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();

    expect(source.corps, isNotNull, reason: 'aucune commande envoyée');
    expect(source.corps!['modeLivraison'], 'retrait');
    expect(source.corps!['modePaiement'], 'a_la_livraison');
    expect(source.corps!['adresseLivraison'], isNull);
    expect((source.corps!['items'] as List).single['quantite'], 2);
    expect(panier.estVide, isTrue, reason: 'le produit commandé quitte le panier');
  });

  testWidgets('une livraison exige une adresse puis part au serveur',
      (tester) async {
    await ouvrir(tester);
    await tester.enterText(
      champ('Téléphone'),
      '771234567',
    );
    final bouton = find.textContaining('Confirmer');
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pump();
    expect(source.corps, isNull);
    expect(find.text('Adresse requise'), findsOneWidget);

    await tester.enterText(
      champ('Adresse de livraison'),
      'Sacré-Cœur 3, Dakar',
    );
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(source.corps!['modeLivraison'], 'livraison');
    expect(source.corps!['modePaiement'], 'en_ligne');
    expect(source.corps!['adresseLivraison'], 'Sacré-Cœur 3, Dakar');
  });
}
