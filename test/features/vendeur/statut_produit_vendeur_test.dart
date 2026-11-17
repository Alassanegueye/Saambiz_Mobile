import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/features/home/data/models/produit_model.dart';
import 'package:saambiz/features/vendeur/presentation/pages/mes_produits_page.dart';

ProduitModel _produit({
  int quantite = 14,
  bool disponible = true,
  String? statut,
}) => ProduitModel.fromJson({
  'id': 'p1',
  'nom': 'Robe wax',
  'prix': 18500,
  'quantite': quantite,
  'disponible': disponible,
  'statut': ?statut,
});

void main() {
  group('Le statut d’un produit, côté vendeur', () {
    test('sans statut du serveur, le produit est approuvé', () {
      expect(_produit().statut, 'approuve');
    });

    test('la modération passe avant l’interrupteur et le stock', () {
      expect(statutProduitVendeur(_produit(statut: 'rejete')), (
        'Refusé par la modération',
        AppColor.kErreur,
      ));
      expect(
        statutProduitVendeur(_produit(statut: 'en_attente', disponible: false)),
        ('En attente de validation', AppColor.kSecondaryDark),
      );
    });

    test('hors ligne, invisible pour les clients', () {
      expect(
        statutProduitVendeur(_produit(disponible: false)).$1,
        'Hors ligne · invisible pour vos clients',
      );
    });

    test('le stock : rupture en rouge, 3 ou moins en or, sinon en vert', () {
      expect(statutProduitVendeur(_produit(quantite: 0)), (
        'Rupture de stock',
        AppColor.kErreur,
      ));
      expect(statutProduitVendeur(_produit(quantite: 3)), (
        'Plus que 3 en stock',
        AppColor.kSecondaryDark,
      ));
      expect(statutProduitVendeur(_produit(quantite: 4)), (
        'En ligne · 4 en stock',
        AppColor.kSucces,
      ));
    });

    test('la bascule en ligne garde la décision de la modération', () {
      final refuse = _produit(statut: 'rejete');
      expect(refuse.avecDisponible(false).statut, 'rejete');
    });
  });
}
