import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/widgets/libelle_obligatoire.dart';

void main() {
  testWidgets('le texte est suivi d\'un astérisque rouge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LibelleObligatoire('Nom du produit')),
    );

    final rich = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
    expect(rich.text, 'Nom du produit');
    final etoile = rich.children!.single as TextSpan;
    expect(etoile.text, ' *');
    expect(etoile.style!.color, AppColor.kErreur);
  });

  testWidgets('un lecteur d\'écran annonce « obligatoire »', (tester) async {
    final semantique = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: LibelleObligatoire('Prix')),
    );
    expect(find.bySemanticsLabel('Prix, obligatoire'), findsOneWidget);
    semantique.dispose();
  });
}
