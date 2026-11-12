import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/connection/auth_interceptor.dart';
import 'package:saambiz/core/widgets/messages.dart';

/// Les bandeaux de confirmation : un titre, l'explication en dessous, et
/// ils restent visibles quand l'écran qui les a lancés se ferme.
void main() {
  Future<void> ouvrir(WidgetTester tester, void Function(BuildContext) action) {
    return tester.pumpWidget(
      MaterialApp(
        navigatorKey: AuthInterceptor.navigatorKey,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => Scaffold(
                    body: TextButton(
                      onPressed: () {
                        action(ctx);
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ),
              ),
              child: const Text('Modifier'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> declencher(WidgetTester tester) async {
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    // Fermeture de l'écran puis entrée du bandeau.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> laisserFermer(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'succès : « Succès » puis le message, après fermeture de l\'écran',
    (tester) async {
      await ouvrir(
        tester,
        (ctx) => afficherSucces(ctx, 'Votre adresse a été modifiée.'),
      );
      await declencher(tester);
      expect(find.text('Enregistrer'), findsNothing, reason: 'écran fermé');
      expect(find.text('Succès'), findsOneWidget);
      expect(find.text('Votre adresse a été modifiée.'), findsOneWidget);
      await laisserFermer(tester);
    },
  );

  testWidgets('erreur : « Erreur » par défaut, titre personnalisable', (
    tester,
  ) async {
    await ouvrir(
      tester,
      (ctx) => afficherErreur(ctx, 'Réessayez.', titre: 'Envoi impossible'),
    );
    await declencher(tester);
    expect(find.text('Envoi impossible'), findsOneWidget);
    expect(find.text('Réessayez.'), findsOneWidget);
    await laisserFermer(tester);
  });

  testWidgets('un nouveau message remplace le précédent', (tester) async {
    await ouvrir(tester, (ctx) {
      afficherSucces(ctx, 'Premier');
      afficherSucces(ctx, 'Second');
    });
    await declencher(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Premier'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    await laisserFermer(tester);
  });
}
