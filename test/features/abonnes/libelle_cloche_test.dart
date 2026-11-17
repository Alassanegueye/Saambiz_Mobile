import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/abonnes/abonnes_page.dart';

void main() {
  group('Qui reçoit les notifications, accordé au nombre', () {
    test('personne : la phrase ne désigne personne', () {
      expect(libelleCloche(0, 2), startsWith('Aucun abonné n’a encore activé'));
    });

    test('un seul abonné, qui a la cloche', () {
      expect(libelleCloche(1, 1), startsWith('Votre abonné a activé'));
    });

    test('tous', () {
      expect(libelleCloche(3, 3), startsWith('Vos 3 abonnés ont activé'));
    });

    test('une partie : singulier puis pluriel', () {
      expect(libelleCloche(1, 4), startsWith('1 abonné sur 4 a activé'));
      expect(libelleCloche(2, 4), startsWith('2 abonnés sur 4 ont activé'));
    });
  });
}
