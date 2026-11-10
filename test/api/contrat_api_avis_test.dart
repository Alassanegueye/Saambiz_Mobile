import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/avis/data/avis_remote_datasource.dart';

import '../helpers/dio_espion.dart';

/// Contrat HTTP des avis.
///
/// Les quatre routes existaient côté backend sans qu'aucun écran ne les
/// appelle. Ces tests figent ce que le mobile envoie et ce qu'il sait relire,
/// en écrivant les réponses telles que le backend les forme.
void main() {
  late DioEspion espion;
  late Dio dio;
  late AvisRemoteDataSource source;

  setUp(() {
    espion = DioEspion();
    dio = dioDeTest(espion);
    source = AvisRemoteDataSource(dio);
  });

  group('Lecture publique', () {
    test('la liste porte la moyenne, le total et les avis', () async {
      espion.repond({
        'moyenne': 4.5,
        'total': 2,
        'avis': [
          {
            'id': 'a1',
            'note': 5,
            'commentaire': 'Très bonne boutique',
            'createdAt': '2026-11-01T10:00:00.000Z',
            'acheteur': {'prenom': 'Awa', 'nom': 'Diop', 'photoProfil': null},
          },
          {'id': 'a2', 'note': 4, 'commentaire': '', 'acheteur': null},
        ],
      });

      final res = await source.avisBoutique('b1');

      expect(espion.appel, 'GET /avis/boutique/b1');
      expect(res.moyenne, 4.5);
      expect(res.total, 2);
      expect(res.avis.first.auteur, 'Awa Diop');
      expect(res.avis.first.note, 5);
    });

    test('un auteur absent ne fait pas tomber la liste', () async {
      // Le compte peut avoir été supprimé depuis : l'avis reste, pas l'auteur.
      espion.repond({
        'moyenne': 4,
        'total': 1,
        'avis': [
          {'id': 'a1', 'note': 4, 'commentaire': 'ok', 'acheteur': null},
        ],
      });

      final res = await source.avisBoutique('b1');

      expect(res.avis.single.auteur, 'Client SaamBiz');
    });

    test(
      'une boutique sans avis rend une liste vide, pas une erreur',
      () async {
        espion.repond({'moyenne': 0, 'total': 0, 'avis': []});

        final res = await source.avisBoutique('b1');

        expect(res.total, 0);
        expect(res.avis, isEmpty);
      },
    );
  });

  group('Mon avis', () {
    test('est lu sous la clé `avis`', () async {
      espion.repond({
        'avis': {'id': 'a1', 'note': 3, 'commentaire': 'Correct'},
      });

      final mien = await source.monAvis('b1');

      expect(espion.appel, 'GET /avis/boutique/b1/mon-avis');
      expect(mien!.note, 3);
      expect(mien.commentaire, 'Correct');
    });

    test('vaut null quand aucun avis n’a été laissé', () async {
      // Le backend répond `avis: null` : ce n'est pas une erreur, c'est un
      // client qui n'a encore rien écrit.
      espion.repond({'avis': null});

      expect(await source.monAvis('b1'), isNull);
    });
  });

  group('Publication', () {
    test('envoie la boutique, la note et le commentaire', () async {
      espion.repond({'success': true, 'moyenne': 4.2, 'total': 6});

      final stats = await source.laisser(
        boutiqueId: 'b1',
        note: 5,
        commentaire: '  Parfait  ',
      );

      expect(espion.appel, 'POST /avis');
      expect(espion.corpsEnvoye['boutiqueId'], 'b1');
      expect(espion.corpsEnvoye['note'], 5);
      // Espaces retirés : le backend plafonne la longueur, autant ne pas la
      // consommer avec du vide.
      expect(espion.corpsEnvoye['commentaire'], 'Parfait');
      // Les statistiques reviennent à jour : pas besoin de redemander.
      expect(stats.moyenne, 4.2);
      expect(stats.total, 6);
    });

    test('un commentaire vide n’est pas envoyé du tout', () async {
      espion.repond({'success': true, 'moyenne': 5, 'total': 1});

      await source.laisser(boutiqueId: 'b1', note: 5, commentaire: '   ');

      expect(espion.corpsEnvoye.containsKey('commentaire'), isFalse);
    });

    test('le refus du backend remonte tel quel', () async {
      // Note hors bornes : le message métier doit atteindre l'écran.
      espion.repondErreur(
        400,
        corps: {'message': 'La note doit être un entier entre 1 et 5.'},
      );

      await expectLater(
        source.laisser(boutiqueId: 'b1', note: 9),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('Retrait', () {
    test('passe par DELETE sur la boutique', () async {
      espion.repond({'success': true});

      await source.supprimer('b1');

      expect(espion.appel, 'DELETE /avis/boutique/b1');
    });
  });
}
