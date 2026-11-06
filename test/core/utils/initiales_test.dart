import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/utils/texte.dart';

void main() {
  test('les deux premiers mots donnent les initiales', () {
    expect(initialesDe('Teranga Style'), 'TS');
    expect(initialesDe('Boutique de la gare'), 'BD');
  });

  test('un seul mot donne une seule initiale', () {
    expect(initialesDe('awa'), 'A');
  });

  test('espaces en trop et nom vide', () {
    expect(initialesDe('  Abou   DEMO '), 'AD');
    expect(initialesDe('   '), '');
  });

  test('un emoji ne casse pas le texte', () {
    expect(initialesDe('😀 Awa'), '😀A');
  });
}
