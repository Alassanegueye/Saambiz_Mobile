import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/promotions/data/models/promotion_model.dart';
import 'package:saambiz/features/promotions/presentation/pages/promotion_form_page.dart';

void main() {
  group('Modifier une promotion', () {
    test('le prix se relit sans « .0 »', () {
      expect(prixSaisi(14900), '14900');
      expect(prixSaisi(14900.5), '14900.5');
    });

    test('la durée compte le premier et le dernier jour', () {
      expect(
        joursDePromo(DateTime(2026, 11, 18, 15), DateTime(2026, 11, 25, 9)),
        8,
      );
    });

    test('la remise : arrondie, nulle sans baisse ou sans prix normal', () {
      expect(remiseEnPourcent(18500, 14900), 19);
      expect(remiseEnPourcent(18500, 18500), isNull);
      expect(remiseEnPourcent(18500, 20000), isNull);
      expect(remiseEnPourcent(null, 14900), isNull);
      expect(remiseEnPourcent(18500, null), isNull);
    });
  });
}
