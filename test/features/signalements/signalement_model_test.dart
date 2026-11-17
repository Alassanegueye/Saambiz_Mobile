import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/signalements/data/models/signalement_model.dart';

/// Ce que la page « Mes signalements » a besoin de savoir.
///
/// Elle affichait la RAISON SAISIE en gros titre — « dww » — et la valeur
/// brute du statut en base — « en_attente », soulignés compris. Rien ne
/// disait quelle boutique ni quel produit avait été signalé : la liste ne
/// portait qu'un identifiant.
void main() {
  group('Ce qui a été signalé', () {
    test('la boutique est nommée', () {
      final s = SignalementModel.fromJson({
        'id': 's1',
        'type': 'boutique',
        'cibleId': 'b1',
        'raison': 'Produits contrefaits',
        'cible': {'id': 'b1', 'nom': 'Maison Ndiaye Couture', 'image': null},
      });
      expect(s.cible!.nom, 'Maison Ndiaye Couture');
      expect(s.libelleType, 'Boutique');
    });

    test('le produit aussi, avec son image', () {
      final s = SignalementModel.fromJson({
        'id': 's2',
        'type': 'produit',
        'cible': {'id': 'p1', 'nom': 'Robe wax', 'image': 'https://x/p.jpg'},
      });
      expect(s.cible!.nom, 'Robe wax');
      expect(s.cible!.image, 'https://x/p.jpg');
      expect(s.libelleType, 'Produit');
    });

    test('une cible disparue ne devient pas une cible vide', () {
      // Boutique fermée, produit retiré : le serveur rend `null`, et l'écran
      // le dit (« Boutique supprimée ») au lieu d'afficher autre chose à sa
      // place.
      for (final json in [
        {'id': 's3'},
        {'id': 's3', 'cible': null},
        {'id': 's3', 'cible': {'id': 'b9', 'nom': '   '}},
        {'id': 's3', 'cible': 'pas un objet'},
      ]) {
        expect(SignalementModel.fromJson(json).cible, isNull);
      }
    });

    test('une image vide vaut pas d’image', () {
      final s = SignalementModel.fromJson({
        'id': 's4',
        'cible': {'id': 'b1', 'nom': 'Aloushop', 'image': '  '},
      });
      expect(s.cible!.nom, 'Aloushop');
      expect(s.cible!.image, isNull);
    });
  });

  group('Le statut se lit', () {
    test('les trois états ont leur libellé', () {
      String libelle(String statut) =>
          SignalementModel.fromJson({'id': 'x', 'statut': statut})
              .libelleStatut;

      expect(libelle('en_attente'), 'En attente');
      expect(libelle('traite'), 'Traité');
      expect(libelle('rejete'), 'Rejeté');
    });

    test('un statut inconnu s’affiche tel quel, sans planter', () {
      expect(
        SignalementModel.fromJson({'id': 'x', 'statut': 'inedit'})
            .libelleStatut,
        'inedit',
      );
    });

    test('« en attente » se reconnaît, pour le compte du bandeau', () {
      expect(
        SignalementModel.fromJson({'id': 'x', 'statut': 'en_attente'})
            .enAttente,
        isTrue,
      );
      expect(
        SignalementModel.fromJson({'id': 'x', 'statut': 'traite'}).enAttente,
        isFalse,
      );
    });

    test('sans statut, un signalement est en attente', () {
      expect(SignalementModel.fromJson({'id': 'x'}).enAttente, isTrue);
    });
  });
}
