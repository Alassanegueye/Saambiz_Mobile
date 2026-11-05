import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/widgets/onglets_conserves.dart';

class _Page extends StatefulWidget {
  final String nom;
  final Map<String, int> chargements;
  final Map<String, int> retours;

  const _Page(this.nom, this.chargements, this.retours);

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> with RetourSurOnglet {
  @override
  void initState() {
    super.initState();
    widget.chargements.update(widget.nom, (n) => n + 1, ifAbsent: () => 1);
  }

  @override
  void surRetourOnglet() =>
      widget.retours.update(widget.nom, (n) => n + 1, ifAbsent: () => 1);

  @override
  Widget build(BuildContext context) =>
      TextField(key: ValueKey('champ-${widget.nom}'));
}

void main() {
  late Map<String, int> chargements;
  late Map<String, int> retours;

  Future<void> afficher(WidgetTester tester, int index) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OngletsConserves(
            index: index,
            pages: [
              _Page('a', chargements, retours),
              _Page('b', chargements, retours),
              _Page('c', chargements, retours),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() {
    chargements = {};
    retours = {};
  });

  testWidgets('un onglet ne se construit qu\'à sa première visite', (
    tester,
  ) async {
    await afficher(tester, 0);
    expect(chargements, {'a': 1});

    await afficher(tester, 1);
    expect(chargements, {'a': 1, 'b': 1});
  });

  testWidgets('revenir sur un onglet ne le reconstruit pas et l\'actualise', (
    tester,
  ) async {
    await afficher(tester, 0);
    await afficher(tester, 1);
    expect(retours, isEmpty, reason: 'une première visite charge déjà');

    await afficher(tester, 0);
    expect(chargements, {'a': 1, 'b': 1});
    expect(retours, {'a': 1});
  });

  testWidgets('seul l\'onglet actif est visible', (tester) async {
    await afficher(tester, 0);
    await afficher(tester, 1);
    expect(find.byKey(const ValueKey('champ-a')), findsNothing);
    expect(find.byKey(const ValueKey('champ-b')), findsOneWidget);
  });

  testWidgets('changer d\'onglet ferme le clavier', (tester) async {
    await afficher(tester, 0);
    await tester.tap(find.byKey(const ValueKey('champ-a')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await afficher(tester, 1);
    expect(tester.testTextInput.isVisible, isFalse);
  });
}
