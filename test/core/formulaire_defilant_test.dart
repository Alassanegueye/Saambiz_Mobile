import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/widgets/formulaire_defilant.dart';

/// Le formulaire dont le bouton n'est pas collé en bas.
///
/// Collé, il remontait au-dessus du clavier et ne laissait aux champs qu'une
/// bande étroite ; un champ à plusieurs lignes y était coupé. Ici tout
/// défile d'un seul tenant, et la hauteur restante revient au champ.
///
/// Ce qui est vérifié : clavier fermé, RIEN NE CHANGE — le bouton reste en
/// bas de l'écran. Clavier ouvert, il quitte l'écran au lieu de voler la
/// place.

Future<void> _poser(
  WidgetTester t, {
  required int champs,
  double clavier = 0,
}) async {
  await t.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: clavier)),
        child: Scaffold(
          body: FormulaireDefilant(
            enfants: [
              for (var i = 0; i < champs; i++)
                SizedBox(height: 120, child: Text('Champ $i')),
            ],
            bouton: const SizedBox(
              height: 52,
              child: Center(child: Text('Envoyer')),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('formulaire court : le bouton reste en bas de l’écran', (
    t,
  ) async {
    // Le cas de tous les jours, clavier fermé : l'utilisateur ne doit voir
    // aucune différence avec avant.
    await _poser(t, champs: 1);

    final ecran = t.getSize(find.byType(Scaffold)).height;
    final bas = t.getRect(find.text('Envoyer')).bottom;

    expect(bas, greaterThan(ecran - 80));
    expect(bas, lessThanOrEqualTo(ecran));
  });

  testWidgets('formulaire long : le bouton descend sous le contenu', (t) async {
    // Il n'est plus épinglé : on le rejoint en faisant défiler, comme sur
    // l'écran de connexion.
    await _poser(t, champs: 12);

    expect(find.text('Envoyer'), findsOneWidget);
    expect(
      t.getRect(find.text('Envoyer')).top,
      greaterThan(t.getSize(find.byType(Scaffold)).height),
    );
  });

  testWidgets('tout le contenu reste atteignable en défilant', (t) async {
    await _poser(t, champs: 12);

    await t.drag(find.byType(SingleChildScrollView), const Offset(0, -2000));
    await t.pumpAndSettle();

    expect(find.text('Envoyer'), findsOneWidget);
    expect(
      t.getRect(find.text('Envoyer')).bottom,
      lessThanOrEqualTo(t.getSize(find.byType(Scaffold)).height + 1),
    );
  });

  testWidgets('un glissé ferme le clavier', (t) async {
    await _poser(t, champs: 12);

    final vue = t.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(
      vue.keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );
  });
}
