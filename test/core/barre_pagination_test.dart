import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/widgets/barre_pagination.dart';

/// « Précédent · Page 2 sur 7 · Suivant », sous une liste.
///
/// Les listes rendaient tout d'un bloc ; le serveur en rend dix à la fois.
/// Sans cette barre, les éléments au-delà du dixième seraient simplement
/// inaccessibles.

Future<int?> _poser(
  WidgetTester t,
  Pagination pagination, {
  bool enChargement = false,
}) async {
  int? demandee;
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BarrePagination(
          pagination: pagination,
          onPage: enChargement ? null : (p) => demandee = p,
        ),
      ),
    ),
  );
  return demandee;
}

void main() {
  group('Ce que la barre montre', () {
    testWidgets('la page courante et le total', (t) async {
      await _poser(t, const Pagination(page: 2, pages: 7, total: 68));

      expect(find.text('Page 2 sur 7'), findsOneWidget);
      expect(find.text('68 au total'), findsOneWidget);
      expect(find.text('Précédent'), findsOneWidget);
      expect(find.text('Suivant'), findsOneWidget);
    });

    testWidgets('rien du tout quand il n’y a qu’une page', (t) async {
      // Une liste courte ne doit pas s'encombrer d'une barre inutile.
      await _poser(t, const Pagination(page: 1, pages: 1, total: 4));

      expect(find.text('Précédent'), findsNothing);
      expect(find.text('Suivant'), findsNothing);
    });
  });

  group('Ce que la barre fait', () {
    testWidgets('« Suivant » demande la page d’après', (t) async {
      int? demandee;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarrePagination(
              pagination: const Pagination(page: 2, pages: 7),
              onPage: (p) => demandee = p,
            ),
          ),
        ),
      );
      await t.tap(find.text('Suivant'));
      expect(demandee, 3);
    });

    testWidgets('« Précédent » demande celle d’avant', (t) async {
      int? demandee;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarrePagination(
              pagination: const Pagination(page: 2, pages: 7),
              onPage: (p) => demandee = p,
            ),
          ),
        ),
      );
      await t.tap(find.text('Précédent'));
      expect(demandee, 1);
    });

    testWidgets('sur la première page, « Précédent » est inerte', (t) async {
      await _poser(t, const Pagination(page: 1, pages: 7));

      final bouton = t.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Précédent'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(bouton.onPressed, isNull);
    });

    testWidgets('sur la dernière, « Suivant » l’est aussi', (t) async {
      await _poser(t, const Pagination(page: 7, pages: 7));

      final bouton = t.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Suivant'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(bouton.onPressed, isNull);
    });

    testWidgets('pendant un chargement, les deux sont inertes', (t) async {
      // Sinon deux appuis rapides lancent deux requêtes, et la seconde page
      // affichée n'est pas forcément la dernière demandée.
      await _poser(t, const Pagination(page: 3, pages: 7), enChargement: true);

      for (final libelle in ['Précédent', 'Suivant']) {
        final bouton = t.widget<OutlinedButton>(
          find.ancestor(
            of: find.text(libelle),
            matching: find.byType(OutlinedButton),
          ),
        );
        expect(bouton.onPressed, isNull, reason: '$libelle doit être inerte');
      }
    });
  });

  group('Lecture de la réponse du serveur', () {
    test('les trois champs sont repris', () {
      final p = Pagination.depuis({'page': 3, 'pages': 9, 'total': 87});
      expect([p.page, p.pages, p.total], [3, 9, 87]);
      expect(p.aPrecedent, isTrue);
      expect(p.aSuivant, isTrue);
    });

    test('une réponse sans pagination donne une page unique', () {
      // Un endpoint pas encore paginé, ou une réponse en liste nue : la
      // barre se replie au lieu de mentir.
      for (final json in [null, <String, dynamic>{}]) {
        expect(Pagination.depuis(json).inutile, isTrue);
      }
    });

    test('des valeurs en texte sont acceptées', () {
      // Certaines API rendent les nombres en chaînes de caractères.
      final p = Pagination.depuis({'page': '2', 'pages': '5', 'total': '41'});
      expect([p.page, p.pages, p.total], [2, 5, 41]);
    });
  });
}
