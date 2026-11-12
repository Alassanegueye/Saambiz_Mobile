import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/paiement/paiement_simule.dart';

void main() {
  group('Numéro mobile', () {
    test('retire espaces et indicatif', () {
      expect(normaliserNumero('+221 77 000 00 01'), '770000001');
      expect(normaliserNumero('00221770000001'), '770000001');
      expect(normaliserNumero('77 000 00 01'), '770000001');
    });

    test('9 chiffres commençant par 7', () {
      expect(numeroValide('77 123 45 67'), isTrue);
      expect(numeroValide('+221781234567'), isTrue);
      expect(numeroValide('12345'), isFalse);
      expect(numeroValide('671234567'), isFalse);
    });
  });

  group('Paiement simulé', () {
    test('chaque numéro de test donne son issue', () async {
      final ok = await simulerPaiement(
        numero: '77 000 00 01',
        methode: 'wave',
        montant: 5000,
      );
      expect(ok.reussi, isTrue);
      expect(ok.reference, startsWith('TEST-WV-'));

      for (final n in ['770000002', '770000003', '771234567']) {
        final r = await simulerPaiement(
          numero: n,
          methode: 'orange_money',
          montant: 5000,
        );
        expect(r.reussi, isFalse, reason: n);
      }
    });
  });
}
