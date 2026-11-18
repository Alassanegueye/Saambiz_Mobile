import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/utils/remplir_ecran.dart';

/// Les grilles du catalogue chargent la suite au défilement. Ce déclencheur
/// est un geste : il n'arrive jamais si le contenu tient dans l'écran.
///
/// Le serveur rend dix articles par page au lieu de quinze ; sur un grand
/// écran, dix fiches ne débordent pas toujours. La grille s'arrêtait alors à
/// dix articles, avec deux cents disponibles et aucun moyen de les
/// atteindre.

/// Pose une liste de [combien] éléments de 100 pixels et rend le nombre
/// d'appels à « charger la suite ».
Future<int> _appels(WidgetTester t, int combien) async {
  final defilement = ScrollController();
  addTearDown(defilement.dispose);
  var appels = 0;

  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          controller: defilement,
          itemCount: combien,
          itemBuilder: (_, __) => const SizedBox(height: 100),
        ),
      ),
    ),
  );

  remplirEcran(defilement, () => appels += 1);
  await t.pumpAndSettle();
  return appels;
}

void main() {
  testWidgets('une liste trop courte redemande la suite', (t) async {
    // Deux éléments de 100 pixels dans un écran de 600 : rien à défiler,
    // donc aucun geste ne viendra jamais déclencher le chargement.
    expect(await _appels(t, 2), 1);
  });

  testWidgets('une liste qui déborde ne redemande rien', (t) async {
    // Le défilement suffit : laisser le geste faire son travail évite de
    // charger des pages que personne n'a demandées.
    expect(await _appels(t, 40), 0);
  });

  testWidgets('sans liste posée, rien ne se passe', (t) async {
    // Appelée après une erreur, la liste peut n'avoir jamais été construite.
    final defilement = ScrollController();
    addTearDown(defilement.dispose);
    var appels = 0;

    await t.pumpWidget(const MaterialApp(home: Scaffold(body: Text('vide'))));
    remplirEcran(defilement, () => appels += 1);
    await t.pumpAndSettle();

    expect(appels, 0);
  });
}
