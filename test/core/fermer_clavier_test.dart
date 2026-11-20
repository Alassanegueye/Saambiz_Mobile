import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/widgets/fermer_clavier.dart';

/// Toucher à côté d'un champ ferme le clavier.
///
/// Il fallait faire glisser la liste vers le bas, un geste que peu de gens
/// connaissent : on restait à taper avec la moitié de l'écran prise par le
/// clavier, sans savoir comment le renvoyer.
///
/// Le point délicat est de ne RIEN casser au passage : un bouton, une case,
/// un autre champ doivent continuer à répondre. D'où `translucent` — le
/// toucher est vu au passage, puis continue sa route.

void main() {
  testWidgets('un toucher dans le vide retire le focus du champ', (t) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);

    await t.pumpWidget(
      MaterialApp(
        home: FermerClavierAuToucher(
          child: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focus),
                // Une zone pleine, comme sur un vrai écran : un
                // `SizedBox` vide ne reçoit aucun toucher.
                Expanded(child: Container(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );

    await t.tap(find.byType(TextField));
    await t.pump();
    expect(focus.hasFocus, isTrue);

    // Le vide, sous le champ. (La fenêtre de test fait 800 × 600 : un
    // toucher à y = 600 tomberait hors de l'écran.)
    await t.tapAt(const Offset(400, 400));
    await t.pumpAndSettle();

    expect(focus.hasFocus, isFalse);
  });

  testWidgets('un bouton répond toujours', (t) async {
    // Le piège : un `opaque` aurait avalé le toucher avant le bouton.
    var presse = false;

    await t.pumpWidget(
      MaterialApp(
        home: FermerClavierAuToucher(
          child: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => presse = true,
                child: const Text('Valider'),
              ),
            ),
          ),
        ),
      ),
    );

    await t.tap(find.text('Valider'));
    await t.pumpAndSettle();

    expect(presse, isTrue);
  });

  testWidgets('toucher un autre champ lui donne le focus', (t) async {
    final premier = FocusNode();
    final second = FocusNode();
    addTearDown(premier.dispose);
    addTearDown(second.dispose);

    await t.pumpWidget(
      MaterialApp(
        home: FermerClavierAuToucher(
          child: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: premier),
                TextField(focusNode: second),
              ],
            ),
          ),
        ),
      ),
    );

    await t.tap(find.byType(TextField).first);
    await t.pump();
    await t.tap(find.byType(TextField).last);
    await t.pumpAndSettle();

    expect(premier.hasFocus, isFalse);
    expect(second.hasFocus, isTrue);
  });

  testWidgets('sans champ actif, un toucher ne fait rien', (t) async {
    // Posé sur quarante-deux écrans, dont beaucoup sans saisie : il ne doit
    // rien coûter ni rien changer là où il n'y a rien à fermer.
    await t.pumpWidget(
      const MaterialApp(
        home: FermerClavierAuToucher(
          child: Scaffold(body: Center(child: Text('Rien à saisir'))),
        ),
      ),
    );

    await t.tapAt(const Offset(400, 300));
    await t.pumpAndSettle();

    expect(find.text('Rien à saisir'), findsOneWidget);
  });
}
