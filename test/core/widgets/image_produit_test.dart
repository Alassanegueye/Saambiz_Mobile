import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/widgets/image_produit.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';

/// Ce que ce fichier protège : la photo d'un produit se présente À
/// L'IDENTIQUE sur tous les écrans. Chaque écran avait son cadrage — vignette
/// écrasée dans « Mes produits », photo flottante dans la vitrine, bandeau
/// débordant dans le formulaire — et personne ne voyait la divergence tant
/// qu'on ne mettait pas les trois côte à côte.
///
/// Un écran qui réintroduirait son propre `BoxFit` ou son propre rapport ne
/// serait pas rattrapé ici : ce qui l'empêche, c'est qu'[ImageProduit] est le
/// seul chemin. Ces tests verrouillent ce que ce chemin unique garantit.
void main() {
  // Pixel transparent : suffit pour vérifier le cadrage, sans fichier.
  final pixel = MemoryImage(
    Uint8List.fromList(<int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82,
    ]),
  );

  setUp(() => ImageReseau.substitut = (_) => pixel);
  tearDown(() => ImageReseau.substitut = null);

  Future<void> monter(WidgetTester tester, Widget enfant) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // Au plus 300 points de large, hauteur libre, comme dans une carte
          // ou une rangée : le widget impose sa forme, il ne la reçoit pas.
          body: SizedBox(
            width: 300,
            child: Align(alignment: Alignment.topLeft, child: enfant),
          ),
        ),
      ),
    );
  }

  testWidgets('la photo distante est carrée et remplit son cadre', (
    tester,
  ) async {
    await monter(tester, const ImageProduit('https://exemple.test/p.jpg'));
    await tester.pump();

    expect(tester.getSize(find.byType(ImageProduit)), const Size(300, 300));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, kFitImageProduit);
  });

  testWidgets('une vignette de taille fixe reste carrée', (tester) async {
    await monter(
      tester,
      const ImageProduit('https://exemple.test/p.jpg', cote: 68),
    );
    await tester.pump();

    expect(tester.getSize(find.byType(ImageProduit)), const Size(68, 68));
    expect(tester.widget<Image>(find.byType(Image)).fit, kFitImageProduit);
  });

  testWidgets('sans photo, l\'icône de remplacement garde le carré', (
    tester,
  ) async {
    await monter(tester, const ImageProduit(''));
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    // Un produit sans photo occupe la même place qu'un produit avec photo :
    // les cartes d'une même rangée restent alignées.
    expect(tester.getSize(find.byType(ImageProduit)), const Size(300, 300));
  });

  testWidgets('une adresse nulle vaut une absence de photo', (tester) async {
    await monter(tester, const ImageProduit(null, cote: 54));
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(tester.getSize(find.byType(ImageProduit)), const Size(54, 54));
  });

  testWidgets('les coins sont arrondis de la même façon partout', (
    tester,
  ) async {
    await monter(tester, const ImageProduit('https://exemple.test/p.jpg'));
    await tester.pump();

    final decoupe = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byType(ImageProduit),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(decoupe.borderRadius, BorderRadius.circular(kRayonImageProduit));
  });

  testWidgets('les badges sont découpés avec la photo', (tester) async {
    await monter(
      tester,
      const ImageProduit(
        'https://exemple.test/p.jpg',
        superpositions: [Positioned(top: 8, left: 8, child: Text('-10 %'))],
      ),
    );
    await tester.pump();

    expect(find.text('-10 %'), findsOneWidget);
    // Le badge est bien DANS le cadre découpé, donc jamais à cheval sur
    // l'arrondi de la carte.
    expect(
      find.descendant(of: find.byType(ClipRRect), matching: find.text('-10 %')),
      findsOneWidget,
    );
  });

  test('le rapport imposé aux photos de produit est le carré', () {
    // Le même rapport est demandé au vendeur au moment du recadrage
    // (rognerPhotoProduit) : si cette constante change, le cadrage en amont
    // suit, sans quoi `cover` recommencerait à rogner.
    expect(kRatioImageProduit, 1);
    expect(kFitImageProduit, BoxFit.cover);
  });
}
