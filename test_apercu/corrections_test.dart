// Captures des écrans touchés par les corrections récentes.
//
//   flutter test test_apercu/corrections_test.dart
//
// Images dans test_apercu/captures/corrections_*.png.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/errors/message_erreur.dart';
import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';
import 'package:saambiz/features/auth/presentation/pages/login_page.dart';
import 'package:saambiz/features/auth/presentation/signup/interets_page.dart';
import 'package:saambiz/features/catalogue/data/produit_catalogue.dart';
import 'package:saambiz/features/catalogue/presentation/pages/boutique_publique_page.dart';
import 'package:saambiz/features/commande/data/services/panier_service.dart';
import 'package:saambiz/features/commande/presentation/pages/checkout_page.dart';
import 'package:saambiz/features/commande/presentation/pages/panier_page.dart';
import 'package:saambiz/features/compte/presentation/pages/edit_profil_page.dart';
import 'package:saambiz/features/compte/presentation/pages/reset_password_page.dart';
import 'package:saambiz/features/home/presentation/pages/acheteur/main_client_page.dart';
import 'package:saambiz/features/home/presentation/pages/vendeur/profil_page.dart'
    as vendeur;
import 'package:saambiz/features/messagerie/presentation/pages/conversations_page.dart';
import 'package:saambiz/injection_container.dart' as di;

import 'apercu_test.dart' show onglet, vendeuse;
import 'donnees.dart';
import 'outils.dart';

const balla = User(
  id: 'u-client',
  nom: 'BEYE',
  prenom: 'Balla',
  email: 'balla.beye@exemple.sn',
  mot_de_passe: '',
  adresse: 'Dakar, Sacré-Cœur 3',
  telephone: '+221781112233',
  role: 'Acheteur',
);

/// Affiche un bandeau par-dessus l'écran capturé.
Future<void> Function(WidgetTester) bandeau(
  void Function(BuildContext) afficher, {
  Future<void> Function(WidgetTester)? avant,
}) =>
    (tester) async {
      if (avant != null) await avant(tester);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      // La capture suit ~2 s plus tard : le bandeau (3 s) est encore là.
      afficher(tester.element(find.byType(Scaffold).last));
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(preparer);

  testWidgets('accueil : nom et email, catégories sur deux lignes', (t) async {
    await capturer(t, 'corrections_01_accueil', const MainAcheteurPage(user: balla));
  });

  testWidgets('inscription : Bonjour + prénom et nom', (t) async {
    await capturer(t, 'corrections_02_interets', const InteretsPage(user: balla));
  });

  testWidgets('mot de passe : code en 6 cases', (t) async {
    await capturer(
      t,
      'corrections_03_code_6_chiffres',
      const ResetPasswordPage(email: 'balla.beye@exemple.sn'),
      action: (tester) async {
        await tester.enterText(find.byType(TextField).at(0), '3');
        await tester.enterText(find.byType(TextField).at(1), '9');
        await tester.enterText(find.byType(TextField).at(2), '4');
      },
    );
  });

  testWidgets('explorer : section Boutiques', (t) async {
    await capturer(
      t,
      'corrections_04_explorer_boutiques',
      const MainAcheteurPage(user: balla),
      action: (tester) async {
        await onglet('Explorer')(tester);
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 120));
        }
        await tester.tap(find.text('Boutiques').last);
      },
    );
  });

  testWidgets('favoris : nouvelles cartes', (t) async {
    await capturer(
      t,
      'corrections_05_favoris',
      const MainAcheteurPage(user: balla),
      action: onglet('Favoris'),
    );
  });

  testWidgets('validation de commande : récapitulatif', (t) async {
    di.sl<PanierService>().basculerBoutique('v-b1');
    await capturer(t, 'corrections_06_commande_haut', const CheckoutPage());
  });

  testWidgets('validation de commande : page entière', (t) async {
    if (di.sl<PanierService>().selectionVide) {
      di.sl<PanierService>().basculerBoutique('v-b1');
    }
    await capturer(
      t,
      'corrections_07_commande_entiere',
      const CheckoutPage(),
      hauteur: 1500,
    );
  });

  testWidgets('messages : nom et logo de la boutique', (t) async {
    await capturer(t, 'corrections_08_messages', const ConversationsPage());
  });

  testWidgets('connexion hors ligne : message en français', (t) async {
    await capturer(
      t,
      'corrections_09_hors_ligne',
      const LoginPage(),
      action: bandeau(
        (ctx) => afficherErreur(
          ctx,
          messageErreurReseau(
            DioException.connectionError(
              requestOptions: RequestOptions(path: '/auth/login'),
              reason: "Failed host lookup: 'api.saambiz.com'",
            ),
          ),
          titre: 'Échec de la connexion',
        ),
      ),
    );
  });

  testWidgets('bandeau de succès', (t) async {
    await capturer(
      t,
      'corrections_10_succes',
      const MainAcheteurPage(user: balla),
      action: bandeau(
        (ctx) => afficherSucces(ctx, 'Votre adresse a été modifiée avec succès.'),
        avant: onglet('Compte'),
      ),
    );
  });

  testWidgets('bandeau de succès : favoris', (t) async {
    await capturer(
      t,
      'corrections_11_succes_favoris',
      const MainAcheteurPage(user: balla),
      action: bandeau(
        (ctx) => afficherSucces(
          ctx,
          'Alertes activées : vous serez prévenu des promotions et nouveautés.',
        ),
        avant: onglet('Favoris'),
      ),
    );
  });

  testWidgets('page boutique', (t) async {
    await capturer(
      t,
      'corrections_12_boutique',
      BoutiquePubliquePage(
        boutiqueId: 'b1',
        apercu: BoutiqueResume.fromJson(Donnees.boutiques.first),
      ),
      hauteur: 1400,
    );
  });

  testWidgets('page boutique (Aloushop, sans avis ni bannière)', (t) async {
    await capturer(
      t,
      'corrections_13_boutique_simple',
      BoutiquePubliquePage(
        boutiqueId: 'b2',
        apercu: BoutiqueResume.fromJson(Donnees.boutiques[1]),
      ),
    );
  });

  testWidgets('panier', (t) async {
    final panier = di.sl<PanierService>();
    if (panier.selectionVide) panier.basculerBoutique('v-b1');
    await capturer(t, 'corrections_14_panier', const PanierPage());
  });

  testWidgets('compte', (t) async {
    await capturer(
      t,
      'corrections_15_compte',
      const MainAcheteurPage(user: balla),
      action: onglet('Compte'),
      hauteur: 1500,
    );
  });

  testWidgets('compte vendeur', (t) async {
    await capturer(
      t,
      'corrections_16_compte_vendeur',
      const vendeur.ProfilPage(user: vendeuse),
      profil: 'vendeur',
    );
  });

  testWidgets('modifier le profil', (t) async {
    await capturer(
      t,
      'corrections_17_modifier_profil',
      const EditProfilePage(user: balla),
    );
  });

  testWidgets('accueil sans doublons', (t) async {
    await capturer(
      t,
      'corrections_18_accueil_entier',
      const MainAcheteurPage(user: balla),
      hauteur: 4200,
      action: (tester) async {
        final noms = find
            .byWidgetPredicate(
              (w) => w is Text && (w.data ?? '').isNotEmpty,
              skipOffstage: false,
            )
            .evaluate()
            .map((e) => (e.widget as Text).data!)
            .toList();
        debugPrint('TEXTES ${noms.join(' | ')}');
      },
    );
  });
}
