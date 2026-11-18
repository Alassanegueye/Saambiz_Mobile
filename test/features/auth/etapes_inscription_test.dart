import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/auth/presentation/signup/creer_boutique_page.dart';
import 'package:saambiz/features/auth/presentation/signup/signup_kit.dart';

void main() {
  group('Les étapes de l’inscription', () {
    test('les libellés ont leurs accents', () {
      expect(const SbEtapes(courante: 1).etapes, [
        'Vous',
        'Contact',
        'Sécurité',
        'Vérification',
        'Centres d’intérêt',
      ]);
      expect(
        const SbEtapes(courante: 1, vendeur: true).etapes.last,
        'Votre boutique',
      );
    });

    testWidgets('la boutique se crée en trois temps nommés, pas en « pages »', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SousEtapesBoutique(courante: 1)),
        ),
      );
      expect(find.text('Nom'), findsOneWidget);
      expect(find.text('Catégories'), findsOneWidget);
      expect(find.text('Adresse'), findsOneWidget);
      // Le premier temps est fait : coché.
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.textContaining('sur 3'), findsNothing);
    });
  });
}
