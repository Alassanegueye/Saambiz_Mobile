import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saambiz/core/services/comptes_memorises.dart';
import 'package:saambiz/features/auth/presentation/widgets/choix_compte.dart';

/// LA BOUTIQUE SUR L'ÉCRAN DE CHOIX DE COMPTE.
///
/// Deux vendeurs peuvent porter le même nom — deux « Alassane GUEYE » l'un
/// sous l'autre — et on ne les distinguait qu'en lisant deux adresses e-mail
/// presque identiques.
///
/// Ce fichier existe parce que la question « pourquoi la boutique ne
/// s'affiche-t-elle pas ? » a coûté une demi-journée, à chercher dans le code
/// de l'affichage un défaut qui n'y était pas : le serveur jetait la donnée
/// avant de l'envoyer. Ces tests fixent la frontière. Tant qu'ils passent,
/// l'écran fait son travail dès que la donnée arrive, et il faut chercher
/// ailleurs.
void main() {
  CompteMemorise compte({String? boutique, String role = 'Vendeur'}) =>
      CompteMemorise(
        id: 'u1',
        prenom: 'Alassane',
        nom: 'GUEYE',
        email: 'alassanegpro@gmail.com',
        telephone: '+221775929390',
        role: role,
        derniereUtilisation: DateTime(2026, 11, 24),
        boutique: boutique,
      );

  Future<void> poser(WidgetTester t, List<CompteMemorise> comptes) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChoixCompte(
              comptes: comptes,
              onChoisir: (_) {},
              onRetirer: (_) {},
              onAutreCompte: () {},
            ),
          ),
        ),
      ),
    );
    await t.pump();
  }

  testWidgets('affiche le nom de la boutique sous le nom du vendeur', (t) async {
    await poser(t, [compte(boutique: 'Aloushop')]);

    expect(find.text('Aloushop'), findsOneWidget);
    expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
  });

  testWidgets('la boutique passe AVANT l’adresse e-mail', (t) async {
    // L'ordre est le fond de la demande : c'est la boutique qu'un vendeur
    // reconnaît du premier coup d'œil, pas son adresse.
    await poser(t, [compte(boutique: 'Aloushop')]);

    final yBoutique = t.getTopLeft(find.text('Aloushop')).dy;
    final yEmail = t.getTopLeft(find.text('alassanegpro@gmail.com')).dy;
    expect(yBoutique, lessThan(yEmail));
  });

  testWidgets('sans boutique, la ligne reste lisible et sans trou', (t) async {
    // Un vendeur qui n'a pas encore créé sa boutique, ou un compte mémorisé
    // avant que le serveur ne l'envoie : rien ne doit s'afficher à la place.
    await poser(t, [compte()]);

    expect(find.byIcon(Icons.storefront_rounded), findsNothing);
    expect(find.text('GUEYE Alassane'), findsNothing);
    expect(find.text('Alassane GUEYE'), findsOneWidget);
    expect(find.text('Vendeur'), findsOneWidget);
  });

  testWidgets('deux vendeurs du même nom se distinguent par leur boutique', (t) async {
    await poser(t, [
      compte(boutique: 'Aloushop'),
      CompteMemorise(
        id: 'u2',
        prenom: 'Alassane',
        nom: 'GUEYE',
        email: 'alassane.autre@exemple.sn',
        telephone: '+221770000000',
        role: 'Vendeur',
        derniereUtilisation: DateTime(2026, 11, 23),
        boutique: 'Sañse Couture',
      ),
    ]);

    expect(find.text('Alassane GUEYE'), findsNWidgets(2));
    expect(find.text('Aloushop'), findsOneWidget);
    expect(find.text('Sañse Couture'), findsOneWidget);
  });

  testWidgets('un client ne porte pas de boutique', (t) async {
    await poser(t, [compte(role: 'Acheteur')]);

    expect(find.text('Client'), findsOneWidget);
    expect(find.byIcon(Icons.storefront_rounded), findsNothing);
  });
}
