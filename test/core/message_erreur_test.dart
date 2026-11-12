import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/errors/message_erreur.dart';
import 'package:saambiz/core/services/config_publique_service.dart';

DioException _erreur({
  DioExceptionType type = DioExceptionType.badResponse,
  int? code,
  dynamic corps,
}) {
  final requete = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requete,
    type: type,
    response: code == null
        ? null
        : Response(requestOptions: requete, statusCode: code, data: corps),
  );
}

void main() {
  group('messageErreurReseau', () {
    test('le message du backend passe avant tout', () {
      // C'est le seul qui connaisse la raison métier.
      final m = messageErreurReseau(
        _erreur(code: 400, corps: {'message': 'Le montant doit être positif'}),
      );
      expect(m, 'Le montant doit être positif');
    });

    test('les erreurs de validation en tableau sont lues', () {
      final m = messageErreurReseau(
        _erreur(
          code: 422,
          corps: {
            'errors': [
              {'message': 'Le téléphone est invalide'},
            ],
          },
        ),
      );
      expect(m, 'Le téléphone est invalide');
    });

    test('une coupure signalée en « unknown » par le système aussi', () {
      final requete = RequestOptions(path: '/test');
      final m = messageErreurReseau(
        DioException(
          requestOptions: requete,
          type: DioExceptionType.unknown,
          error: const SocketException("Failed host lookup: 'api.saambiz.com'"),
        ),
      );
      expect(m, contains("n'êtes pas connecté à internet"));
    });

    test('une coupure réseau parle français', () {
      // Avant, l'utilisateur lisait le texte anglais de Dio.
      final m = messageErreurReseau(
        _erreur(type: DioExceptionType.connectionError),
      );
      expect(m, contains("n'êtes pas connecté à internet"));
      expect(m.toLowerCase(), isNot(contains('host lookup')));
    });

    test('un dépassement de délai parle français', () {
      final m = messageErreurReseau(
        _erreur(type: DioExceptionType.receiveTimeout),
      );
      expect(m, contains('trop de temps'));
    });

    test('chaque code HTTP sans corps a sa phrase', () {
      expect(messageErreurReseau(_erreur(code: 401)), contains('session'));
      expect(messageErreurReseau(_erreur(code: 403)), contains('droits'));
      expect(messageErreurReseau(_erreur(code: 404)), contains('introuvable'));
      expect(messageErreurReseau(_erreur(code: 429)), contains('tentatives'));
      expect(messageErreurReseau(_erreur(code: 500)), contains('serveur'));
    });

    test('une réponse vide ou en HTML retombe sur le code', () {
      // Une page d'erreur de Nginx ne doit pas être affichée telle quelle.
      final m = messageErreurReseau(
        _erreur(code: 502, corps: '<html><body>Bad Gateway</body></html>'),
      );
      expect(m, contains('serveur'));
      expect(m, isNot(contains('html')));
    });

    test('un message vide côté backend ne masque pas le code', () {
      final m = messageErreurReseau(
        _erreur(code: 404, corps: {'message': '  '}),
      );
      expect(m, contains('introuvable'));
    });
  });

  group('ConfigApp.miseAJourExigee', () {
    const config = ConfigApp(
      minVersionAndroid: '1.2.0',
      minVersionIos: '1.2.0',
      maintenance: false,
    );

    test('une version antérieure exige la mise à jour', () {
      expect(config.miseAJourExigee('1.1.9', ios: true), isTrue);
    });

    test('la version minimale elle-même suffit', () {
      expect(config.miseAJourExigee('1.2.0', ios: true), isFalse);
    });

    test('la comparaison est numérique, pas alphabétique', () {
      // '1.10.0' < '1.2.0' en comparant des chaînes : le piège classique.
      expect(config.miseAJourExigee('1.10.0', ios: true), isFalse);
    });

    test('le numéro de build est ignoré', () {
      expect(config.miseAJourExigee('1.2.0+8', ios: true), isFalse);
    });

    test('sans version minimale, rien n’est exigé', () {
      const vide = ConfigApp(maintenance: false);
      expect(vide.miseAJourExigee('0.1.0', ios: true), isFalse);
    });
  });
}
