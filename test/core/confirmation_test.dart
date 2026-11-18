import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/widgets/confirmation.dart';

/// La feuille de confirmation, seule porte avant une action importante.
///
/// Ce qu'elle garantit : rien ne part sur le premier appui, « Annuler » ne
/// fait rien, et refermer la feuille d'un glissé vaut refus — pas accord.

/// Un écran minimal qui lance la feuille et retient sa réponse.
Future<bool?> _reponse(WidgetTester t, {bool destructive = true}) async {
  bool? recue;
  await t.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                recue = await confirmerAction(
                  context,
                  icone: Icons.delete_outline_rounded,
                  titre: 'Supprimer cet élément ?',
                  message: 'Cette opération est définitive.',
                  action: 'Confirmer la suppression',
                  destructive: destructive,
                );
              },
              child: const Text('Agir'),
            ),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.text('Agir'));
  await t.pumpAndSettle();
  return recue;
}

void main() {
  testWidgets('le titre, le message et les deux boutons sont là', (t) async {
    await _reponse(t);

    expect(find.text('Supprimer cet élément ?'), findsOneWidget);
    expect(find.text('Cette opération est définitive.'), findsOneWidget);
    expect(find.text('Confirmer la suppression'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
  });

  testWidgets('« Annuler » rend faux', (t) async {
    bool? recue;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  recue = await confirmerAction(
                    context,
                    icone: Icons.delete_outline_rounded,
                    titre: 'Supprimer ?',
                    message: 'Définitif.',
                    action: 'Supprimer',
                  );
                },
                child: const Text('Agir'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Agir'));
    await t.pumpAndSettle();

    await t.tap(find.text('Annuler'));
    await t.pumpAndSettle();

    expect(recue, isFalse);
  });

  testWidgets('le bouton d’action rend vrai', (t) async {
    bool? recue;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  recue = await confirmerAction(
                    context,
                    icone: Icons.delete_outline_rounded,
                    titre: 'Supprimer ?',
                    message: 'Définitif.',
                    action: 'Supprimer',
                  );
                },
                child: const Text('Agir'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Agir'));
    await t.pumpAndSettle();

    await t.tap(find.widgetWithText(ElevatedButton, 'Supprimer'));
    await t.pumpAndSettle();

    expect(recue, isTrue);
  });

  testWidgets('refermer la feuille vaut refus, pas accord', (t) async {
    // Un glissé vers le bas, ou un appui à côté : la réponse est `false`.
    // Si elle valait `null` et qu'un appelant écrivait `!= false`, un geste
    // d'évitement déclencherait l'action.
    bool? recue;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  recue = await confirmerAction(
                    context,
                    icone: Icons.delete_outline_rounded,
                    titre: 'Supprimer ?',
                    message: 'Définitif.',
                    action: 'Supprimer',
                  );
                },
                child: const Text('Agir'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Agir'));
    await t.pumpAndSettle();

    // Appui en dehors de la feuille : Flutter la referme sans valeur.
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();

    expect(recue, isFalse);
  });

  testWidgets('le libellé « Annuler » se remplace', (t) async {
    // « Annuler cette commande ? » avec un bouton « Annuler » en dessous
    // serait illisible : le second veut dire « ne rien faire ».
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => confirmerAction(
                  context,
                  icone: Icons.cancel_outlined,
                  titre: 'Annuler cette commande ?',
                  message: 'Le stock sera rendu.',
                  action: 'Annuler la commande',
                  annuler: 'Retour',
                ),
                child: const Text('Agir'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Agir'));
    await t.pumpAndSettle();

    expect(find.text('Retour'), findsOneWidget);
    expect(find.text('Annuler'), findsNothing);
  });

  testWidgets('les deux niveaux ne se peignent pas pareil', (t) async {
    // Ce qui détruit est rouge ; ce qui engage sans détruire est marine.
    await _reponse(t, destructive: true);
    final rouge = t
        .widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Confirmer la suppression'),
        )
        .style!
        .backgroundColor!
        .resolve({});

    await t.tap(find.text('Annuler'));
    await t.pumpAndSettle();

    await _reponse(t, destructive: false);
    final marine = t
        .widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Confirmer la suppression'),
        )
        .style!
        .backgroundColor!
        .resolve({});

    expect(rouge, isNot(marine));
  });

  testWidgets('une seule poignée, pas deux', (t) async {
    // Le thème en pose une sur toutes les feuilles de l'application
    // (app_theme.dart, `showDragHandle: true`). En dessiner une seconde ici
    // en affichait deux, l'une au-dessus de l'autre.
    await _reponse(t);

    final poignees = find.byWidgetPredicate((w) {
      if (w is! Container) return false;
      final c = w.constraints;
      return c != null && c.maxWidth == 40 && c.maxHeight == 4;
    });
    expect(poignees, findsNothing, reason: 'le thème s’en charge déjà');
  });
}
