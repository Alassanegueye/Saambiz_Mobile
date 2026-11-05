import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/widgets/fermeture_clavier.dart';

void main() {
  final champA = FocusNode();
  final champB = FocusNode();
  var boutonTouche = false;

  Future<void> monter(WidgetTester tester) async {
    boutonTouche = false;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => FermetureClavier(child: child!),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                TextField(key: const Key('a'), focusNode: champA),
                TextField(key: const Key('b'), focusNode: champB),
                IconButton(
                  key: const Key('bouton'),
                  icon: const Icon(Icons.visibility),
                  onPressed: () => boutonTouche = true,
                ),
                const SizedBox(key: Key('vide'), height: 1500),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('a')));
    await tester.pump();
    expect(champA.hasFocus, isTrue);
  }

  testWidgets('toucher une zone vide ferme le clavier', (tester) async {
    await monter(tester);
    await tester.tapAt(const Offset(400, 500));
    await tester.pump();
    expect(champA.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('toucher un autre champ garde le clavier', (tester) async {
    await monter(tester);
    await tester.tap(find.byKey(const Key('b')));
    await tester.pump();
    expect(champB.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('toucher un bouton garde le clavier', (tester) async {
    await monter(tester);
    await tester.tap(find.byKey(const Key('bouton')));
    await tester.pump();
    expect(boutonTouche, isTrue);
    expect(champA.hasFocus, isTrue);
  });

  testWidgets('faire défiler garde le clavier', (tester) async {
    await monter(tester);
    await tester.dragFrom(const Offset(400, 500), const Offset(0, -200));
    await tester.pump();
    expect(champA.hasFocus, isTrue);
  });
}
