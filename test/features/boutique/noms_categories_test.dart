import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/boutique/presentation/pages/ma_boutique_page.dart';
import 'package:saambiz/features/categories/data/categorie.dart';

void main() {
  group('Les catégories de la boutique, en noms', () {
    test('slug, id ou nom : le nom du référentiel, dans l’ordre', () {
      expect(nomsCategories(['mode-homme', 'Mode femme'], kCategoriesSecours), [
        'Mode homme',
        'Mode femme',
      ]);
    });

    test('une valeur inconnue s’affiche telle quelle', () {
      expect(nomsCategories(['Pêche'], kCategoriesSecours), ['Pêche']);
    });

    test('aucune catégorie : rien', () {
      expect(nomsCategories(const [], kCategoriesSecours), isEmpty);
    });
  });
}
