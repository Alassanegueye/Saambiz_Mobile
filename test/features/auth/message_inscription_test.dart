import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/auth/data/datasources/signup_remote_datasource.dart';

/// Ce que l'utilisateur lit quand le code ne part pas.
///
/// Le message compte autant que l'échec : « Impossible d'envoyer le code. »
/// fait corriger une adresse correcte, et laisse croire à un refus du serveur
/// alors que le téléphone n'a parfois rien pu joindre du tout.

/// Adaptateur qui échoue comme on le lui demande, sans réseau.
class _AdaptateurQuiEchoue implements HttpClientAdapter {
  final DioException panne;
  _AdaptateurQuiEchoue(this.panne);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? r, Future<void>? c) async {
    throw panne;
  }

  @override
  void close({bool force = false}) {}
}

/// Adaptateur qui répond le statut et le corps donnés.
class _AdaptateurQuiRepond implements HttpClientAdapter {
  final int statut;
  final Object? corps;
  _AdaptateurQuiRepond(this.statut, this.corps);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? r, Future<void>? c) async {
    return ResponseBody.fromString(
      corps == null ? '' : jsonEncode(corps),
      statut,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

SignupRemoteDataSource _source(HttpClientAdapter adaptateur) => SignupRemoteDataSource(
  Dio(BaseOptions(baseUrl: 'https://exemple.test'))..httpClientAdapter = adaptateur,
);

Future<String> _messageDe(HttpClientAdapter adaptateur) async {
  try {
    await _source(adaptateur).envoyerCode(email: 'a@b.test');
    fail('un échec était attendu');
  } on SignupException catch (e) {
    return e.message;
  }
}

void main() {
  final requete = RequestOptions(path: '/auth/inscription/envoyer-code');

  group('Aucune réponse du serveur', () {
    // Dio compte huit types d'erreur. L'ancienne version n'en énumérait que
    // trois, et tous les autres tombaient sur « Impossible d'envoyer le
    // code. » — en particulier `unknown`, qui enveloppe la plupart des
    // SocketException, et `badCertificate`.
    for (final type in const [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.badCertificate,
      DioExceptionType.unknown,
    ]) {
      test('$type parle du réseau, pas de l’envoi', () async {
        final message = await _messageDe(
          _AdaptateurQuiEchoue(
            DioException(requestOptions: requete, type: type),
          ),
        );
        expect(message, contains('Connexion impossible'));
        expect(message, isNot(contains("Impossible d'envoyer")));
      });
    }
  });

  group('Le serveur a répondu', () {
    test('son message est affiché tel quel', () async {
      // Les messages du backend sont déjà rédigés pour l'utilisateur final.
      final message = await _messageDe(
        _AdaptateurQuiRepond(409, {
          'message': 'Cette adresse est déjà associée à un compte.',
        }),
      );
      expect(message, 'Cette adresse est déjà associée à un compte.');
    });

    test('une panne du service se dit comme telle', () async {
      // 503 : l'envoi des codes est indisponible côté serveur. Le dire plutôt
      // que d'accuser l'adresse saisie.
      final message = await _messageDe(_AdaptateurQuiRepond(503, null));
      expect(message, contains('indisponible'));
    });

    test('le repli ne sert que pour un refus sans explication', () async {
      final message = await _messageDe(_AdaptateurQuiRepond(400, null));
      expect(message, "Impossible d'envoyer le code.");
    });
  });
}
