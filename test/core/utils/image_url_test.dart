import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/utils/image_url.dart';

void main() {
  group('imageOptimisee', () {
    const brute =
        'https://res.cloudinary.com/demo/image/upload/v1712/saambiz/abc.jpg';

    test('insère la réduction juste après /image/upload/', () {
      expect(
        imageOptimisee(brute),
        'https://res.cloudinary.com/demo/image/upload/c_limit,w_1080,q_auto/v1712/saambiz/abc.jpg',
      );
    });

    test('respecte la largeur demandée', () {
      expect(imageOptimisee(brute, largeur: 400), contains('c_limit,w_400,q_auto/'));
    });

    test("n'empile pas deux transformations", () {
      final une = imageOptimisee(brute);
      expect(imageOptimisee(une), une);
    });

    test('laisse intacte une adresse hors Cloudinary', () {
      const autre = 'https://exemple.com/image/upload/x.jpg';
      expect(imageOptimisee(autre), autre);
    });
  });
}
