// Captures d'écran de l'application avec des données fictives.
//
// Lancer depuis Android Studio (configuration « Aperçu design ») ou :
//   flutter test test_apercu/apercu_test.dart
// Les images arrivent dans test_apercu/captures/, avec journal.txt (requêtes
// sans données prévues, erreurs de mise en page).
//
// Ce dossier est hors de test/ : `flutter test` seul ne le lance pas.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/widgets/barre_navigation_verre.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';
import 'package:saambiz/features/auth/presentation/pages/login_page.dart';
import 'package:saambiz/features/catalogue/data/produit_catalogue.dart';
import 'package:saambiz/features/catalogue/presentation/pages/boutique_publique_page.dart';
import 'package:saambiz/features/catalogue/presentation/pages/produit_detail_page.dart';
import 'package:saambiz/features/catalogue/presentation/pages/produits_page.dart';
import 'package:saambiz/features/categories/data/categorie.dart';
import 'package:saambiz/features/commande/data/models/commande_model.dart';
import 'package:saambiz/features/commande/presentation/pages/commande_detail_page.dart';
import 'package:saambiz/features/commande/presentation/pages/panier_page.dart';
import 'package:saambiz/features/home/presentation/pages/acheteur/main_client_page.dart';
import 'package:saambiz/features/home/presentation/pages/vendeur/main_vendeur_page.dart';
import 'package:saambiz/features/home/presentation/pages/vendeur/profil_page.dart'
    as vendeur;
import 'package:saambiz/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:saambiz/features/vendeur/presentation/pages/produit_form_page.dart';

import 'donnees.dart';
import 'outils.dart';

const client = User(
  id: 'u-client',
  nom: 'Diop',
  prenom: 'Moussa',
  email: 'moussa.diop@exemple.sn',
  mot_de_passe: '',
  adresse: 'Dakar, Sacré-Cœur 3',
  telephone: '+221781112233',
  role: 'Acheteur',
);

const vendeuse = User(
  id: 'u-vendeur',
  nom: 'Ndiaye',
  prenom: 'Awa',
  email: 'awa.ndiaye@exemple.sn',
  mot_de_passe: '',
  adresse: 'Dakar, Plateau',
  telephone: '+221771234567',
  role: 'Vendeur',
);

/// Ouvre l'onglet [libelle] de la barre de navigation du bas.
Future<void> Function(WidgetTester) onglet(String libelle) => (tester) async {
  await tester.tap(
    find
        .descendant(
          of: find.byType(BarreNavigationVerre),
          matching: find.text(libelle),
        )
        .first,
  );
};

/// Page lue avec des arguments de route (détail de commande).
Widget avecArguments(Widget page, Object arguments) => Navigator(
  onGenerateRoute: (_) => MaterialPageRoute(
    settings: RouteSettings(arguments: arguments),
    builder: (_) => page,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(preparer);

  // ─── Espace client ──────────────────────────────────────────────────────
  testWidgets('client accueil', (t) async {
    await capturer(t, 'client_01_accueil', const MainAcheteurPage(user: client));
  });
  testWidgets('client accueil (page entière)', (t) async {
    await capturer(
      t,
      'client_01b_accueil_entier',
      const MainAcheteurPage(user: client),
      hauteur: 2600,
    );
  });
  testWidgets('client categories', (t) async {
    await capturer(
      t,
      'client_02_categories',
      const MainAcheteurPage(user: client),
      action: onglet('Catégories'),
    );
  });
  testWidgets('client favoris', (t) async {
    await capturer(
      t,
      'client_03_favoris',
      const MainAcheteurPage(user: client),
      action: onglet('Favoris'),
    );
  });
  testWidgets('client commandes', (t) async {
    await capturer(
      t,
      'client_04_commandes',
      const MainAcheteurPage(user: client),
      action: onglet('Commandes'),
    );
  });
  testWidgets('client compte', (t) async {
    await capturer(
      t,
      'client_05_compte',
      const MainAcheteurPage(user: client),
      action: onglet('Compte'),
    );
  });
  testWidgets('client fiche produit', (t) async {
    await capturer(
      t,
      'client_06_fiche_produit',
      ProduitDetailPage(produit: ProduitCatalogue.fromJson(Donnees.produit('p1'))),
    );
  });
  testWidgets('client fiche produit (page entière)', (t) async {
    await capturer(
      t,
      'client_06b_fiche_produit_entiere',
      ProduitDetailPage(produit: ProduitCatalogue.fromJson(Donnees.produit('p1'))),
      hauteur: 1700,
    );
  });
  testWidgets('client boutique', (t) async {
    await capturer(
      t,
      'client_07_boutique',
      BoutiquePubliquePage(
        boutiqueId: 'b1',
        apercu: BoutiqueResume.fromJson(Donnees.boutiques.first),
      ),
      hauteur: 1400,
    );
  });
  testWidgets('client categorie', (t) async {
    await capturer(
      t,
      'client_08_resultats_categorie',
      ProduitsPage(
        titre: 'Mode femme',
        categorie: Categorie.fromJson(Donnees.categories.first),
      ),
    );
  });
  testWidgets('client panier', (t) async {
    await capturer(t, 'client_09_panier', const PanierPage());
  });
  testWidgets('client detail commande', (t) async {
    await capturer(
      t,
      'client_10_detail_commande',
      avecArguments(
        const CommandeDetailPage(),
        CommandeDetailArgs(CommandeModel.fromJson(Donnees.commandesClient.first)),
      ),
      hauteur: 1300,
    );
  });
  testWidgets('connexion', (t) async {
    await capturer(t, 'client_11_connexion', const LoginPage());
  });
  testWidgets('bienvenue', (t) async {
    await capturer(t, 'client_12_bienvenue', const OnboardingPage());
  });

  // ─── Espace vendeur ─────────────────────────────────────────────────────
  testWidgets('vendeur accueil', (t) async {
    await capturer(
      t,
      'vendeur_01_accueil',
      const MainVendeurPage(user: vendeuse),
      profil: 'vendeur',
    );
  });
  testWidgets('vendeur commandes', (t) async {
    await capturer(
      t,
      'vendeur_02_commandes',
      const MainVendeurPage(user: vendeuse),
      action: onglet('Commandes'),
      profil: 'vendeur',
    );
  });
  testWidgets('vendeur boutique', (t) async {
    await capturer(
      t,
      'vendeur_03_boutique',
      const MainVendeurPage(user: vendeuse),
      action: onglet('Boutique'),
      profil: 'vendeur',
    );
  });
  testWidgets('vendeur produits', (t) async {
    await capturer(
      t,
      'vendeur_04_produits',
      const MainVendeurPage(user: vendeuse),
      action: onglet('Produits'),
      profil: 'vendeur',
    );
  });
  testWidgets('vendeur promotions', (t) async {
    await capturer(
      t,
      'vendeur_05_promotions',
      const MainVendeurPage(user: vendeuse),
      action: onglet('Promos'),
      profil: 'vendeur',
    );
  });
  testWidgets('vendeur compte', (t) async {
    await capturer(
      t,
      'vendeur_06_compte',
      const vendeur.ProfilPage(user: vendeuse),
      profil: 'vendeur',
    );
  });
  testWidgets('vendeur detail commande', (t) async {
    await capturer(
      t,
      'vendeur_07_detail_commande',
      avecArguments(
        const CommandeDetailPage(),
        CommandeDetailArgs(
          CommandeModel.fromJson(Donnees.commandesVendeur.first),
          isVendeur: true,
        ),
      ),
      profil: 'vendeur',
      hauteur: 1300,
    );
  });
  testWidgets('vendeur ajout produit', (t) async {
    await capturer(
      t,
      'vendeur_08_ajout_produit',
      const ProduitFormPage(),
      profil: 'vendeur',
    );
  });
}
