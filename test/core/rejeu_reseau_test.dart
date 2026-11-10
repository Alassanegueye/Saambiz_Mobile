import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/connection/rejeu_reseau.dart';

import '../helpers/dio_espion.dart';

/// Le rejeu doit absorber les micro-coupures SANS jamais rejouer une écriture :
/// une commande envoyée dont la réponse s'est perdue a peut-être été
/// enregistrée, et la rejouer en créerait une seconde.
void main() {
  late DioEspion espion;
  late Dio dio;

  setUp(() {
    espion = DioEspion();
    dio = dioDeTest(espion);
    dio.interceptors.add(
      RejeuReseau(
        dio,
        // Pas d'attente réelle dans les tests, et pas d'aléa : on mesure le
        // nombre de tentatives, pas la durée.
        attenteInitiale: Duration.zero,
        alea: Random(1),
      ),
    );
  });

  group('Ce qui est rejoué', () {
    test('un GET interrompu est retenté puis aboutit', () async {
      espion.repondErreur(503);
      espion.repond({'success': true, 'produits': []});

      final res = await dio.get<dynamic>('/catalogue/produits');

      expect(res.statusCode, 200);
      expect(espion.requetes.length, 2, reason: 'un seul rejeu a suffi');
    });

    test('un GET qui échoue toujours s’arrête après deux rejeux', () async {
      espion.repondErreur(503);

      await expectLater(
        dio.get<dynamic>('/catalogue/produits'),
        throwsA(isA<DioException>()),
      );
      // Tentative initiale + 2 rejeux : le téléphone n'insiste pas davantage.
      expect(espion.requetes.length, 3);
    });

    test('502, 503 et 504 sont rejoués', () async {
      for (final code in [502, 503, 504]) {
        espion = DioEspion();
        dio = dioDeTest(espion);
        dio.interceptors.add(
          RejeuReseau(dio, attenteInitiale: Duration.zero, alea: Random(1)),
        );
        espion.repondErreur(code);
        espion.repond({'ok': true});

        await dio.get<dynamic>('/categories');
        expect(espion.requetes.length, 2, reason: 'code $code');
      }
    });
  });

  group('Ce qui ne doit jamais être rejoué', () {
    test('un POST n’est pas rejoué, même sur une coupure', () async {
      // Le cœur de la règle : une écriture rejouée peut faire doublon.
      espion.repondErreur(503);

      await expectLater(
        dio.post<dynamic>('/commandes', data: {'items': []}),
        throwsA(isA<DioException>()),
      );
      expect(espion.requetes.length, 1);
    });

    test('un PUT, un PATCH et un DELETE non plus', () async {
      for (final envoi in [
        () => dio.put<dynamic>('/commandes/1/annuler'),
        () => dio.patch<dynamic>('/commandes/1/statut'),
        () => dio.delete<dynamic>('/favoris/1'),
      ]) {
        espion = DioEspion();
        dio = dioDeTest(espion);
        dio.interceptors.add(
          RejeuReseau(dio, attenteInitiale: Duration.zero, alea: Random(1)),
        );
        espion.repondErreur(503);

        await expectLater(envoi(), throwsA(isA<DioException>()));
        expect(espion.requetes.length, 1);
      }
    });

    test('un refus du serveur est rendu tout de suite', () async {
      // 400, 401, 404 sont des réponses : insister ne changerait rien et
      // retarderait le message affiché à l'utilisateur.
      for (final code in [400, 401, 403, 404, 422]) {
        espion = DioEspion();
        dio = dioDeTest(espion);
        dio.interceptors.add(
          RejeuReseau(dio, attenteInitiale: Duration.zero, alea: Random(1)),
        );
        espion.repondErreur(code, corps: {'message': 'non'});

        await expectLater(
          dio.get<dynamic>('/vendeur/dashboard'),
          throwsA(isA<DioException>()),
        );
        expect(espion.requetes.length, 1, reason: 'code $code');
      }
    });

    test('une requête marquée sans rejeu est laissée telle quelle', () async {
      espion.repondErreur(503);

      await expectLater(
        dio.get<dynamic>(
          '/categories',
          options: Options(extra: {RejeuReseau.cleDesactiver: true}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(espion.requetes.length, 1);
    });
  });
}
