import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/services/config_publique_service.dart';
import 'package:saambiz/core/widgets/confirmation.dart';

/// La feuille qui explique, sans rien demander.
///
/// Le client appuie sur « Payer maintenant » d'une commande créée avant la
/// fermeture du paiement en ligne. Il n'y a pas de choix à lui proposer :
/// Wave et Orange Money ne sont pas branchés. On lui dit pourquoi et quoi
/// faire à la place — un seul bouton, parce qu'il n'y a rien à confirmer.

Future<void> _poser(WidgetTester t) async {
  await t.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => informerAction(
                context,
                icone: Icons.phonelink_off_rounded,
                titre: 'Paiement en ligne indisponible',
                message:
                    'Réglez votre commande directement avec la boutique. '
                    'Le vendeur confirmera le paiement de son côté.',
              ),
              child: const Text('Payer maintenant'),
            ),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.text('Payer maintenant'));
  await t.pumpAndSettle();
}

void main() {
  group('La feuille d’information', () {
    testWidgets('montre le titre, l’explication et un seul bouton', (t) async {
      await _poser(t);

      expect(find.text('Paiement en ligne indisponible'), findsOneWidget);
      expect(
        find.textContaining('directement avec la boutique'),
        findsOneWidget,
      );
      expect(find.text('J’ai compris'), findsOneWidget);
    });

    testWidgets('n’offre aucun choix : pas d’« Annuler »', (t) async {
      // Ce n'est pas une confirmation. Proposer « Annuler » laisserait
      // croire qu'un autre chemin existe.
      await _poser(t);

      expect(find.text('Annuler'), findsNothing);
      // Un seul bouton DANS LA FEUILLE — celui de l'écran dessous ne compte
      // pas.
      expect(
        find.widgetWithText(ElevatedButton, 'J’ai compris'),
        findsOneWidget,
      );
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('le bouton la referme', (t) async {
      await _poser(t);

      await t.tap(find.text('J’ai compris'));
      await t.pumpAndSettle();

      expect(find.text('Paiement en ligne indisponible'), findsNothing);
    });

    testWidgets('une seule poignée, comme les autres feuilles', (t) async {
      // Le thème en pose une sur toutes les feuilles ; en dessiner une
      // seconde en afficherait deux, l'une au-dessus de l'autre.
      await _poser(t);

      final poignees = find.byWidgetPredicate((w) {
        if (w is! Container) return false;
        final c = w.constraints;
        return c != null && c.maxWidth == 40 && c.maxHeight == 4;
      });
      expect(poignees, findsNothing);
    });
  });

  group('L’état du paiement en ligne', () {
    setUp(() => ConfigPubliqueService.dernierConnu = null);

    test('fermé tant qu’on ne sait pas', () {
      // Premier lancement, hors ligne, serveur plus ancien : l'application
      // ne propose pas un paiement qui n'aboutirait pas.
      expect(ConfigPubliqueService.paiementEnLigneOuvert, isFalse);
    });

    test('fermé quand le serveur le dit', () {
      ConfigPubliqueService.dernierConnu = const ConfigApp(maintenance: false);
      expect(ConfigPubliqueService.paiementEnLigneOuvert, isFalse);
    });

    test('ouvert le jour où le serveur l’ouvre, sans mise à jour', () {
      // C'est tout l'intérêt de le lire du serveur : les téléphones
      // suivront sans rien installer.
      ConfigPubliqueService.dernierConnu = const ConfigApp(
        maintenance: false,
        paiementEnLigneActif: true,
      );
      expect(ConfigPubliqueService.paiementEnLigneOuvert, isTrue);
    });
  });
}
