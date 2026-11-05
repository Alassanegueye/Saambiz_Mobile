import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/services/session_service.dart';
import 'package:saambiz/core/services/token_service.dart';

class _FauxServeur implements HttpClientAdapter {
  final int statut;
  final bool panneReseau;
  int appels = 0;

  _FauxServeur(this.statut, {this.panneReseau = false});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    appels++;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (panneReseau) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'hors ligne',
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'token': 'nouveau', 'refreshToken': 'nouveau-refresh'}),
      statut,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TokenService jetons;

  SessionService session(_FauxServeur serveur) =>
      SessionService(jetons: jetons, dio: Dio()..httpClientAdapter = serveur);

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'jwt_token': 'ancien',
      'refresh_token': 'ancien-refresh',
    });
    jetons = TokenService(secureStorage: const FlutterSecureStorage());
  });

  test('enregistre les nouveaux jetons', () async {
    final r = await session(_FauxServeur(200)).renouveler();

    expect(r, ResultatRenouvellement.renouvele);
    expect(await jetons.getToken(), 'nouveau');
    expect(await jetons.getRefreshToken(), 'nouveau-refresh');
  });

  test('des appels simultanés ne déclenchent qu\'un renouvellement', () async {
    final serveur = _FauxServeur(200);
    final s = session(serveur);

    await Future.wait([s.renouveler(), s.renouveler(), s.renouveler()]);

    expect(serveur.appels, 1);
  });

  test('session refusée : les jetons sont effacés', () async {
    final r = await session(_FauxServeur(401)).renouveler();

    expect(r, ResultatRenouvellement.refuse);
    expect(await jetons.getToken(), isNull);
    expect(await jetons.getRefreshToken(), isNull);
  });

  test('hors ligne : la session est conservée', () async {
    final r = await session(_FauxServeur(200, panneReseau: true)).renouveler();

    expect(r, ResultatRenouvellement.injoignable);
    expect(await jetons.getRefreshToken(), 'ancien-refresh');
  });

  test('panne du serveur : la session est conservée', () async {
    final r = await session(_FauxServeur(500)).renouveler();

    expect(r, ResultatRenouvellement.injoignable);
    expect(await jetons.getToken(), 'ancien');
  });

  test('visiteur sans session : rien à faire, aucun appel', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final serveur = _FauxServeur(200);

    final r = await session(serveur).renouveler();

    expect(r, ResultatRenouvellement.aucune);
    expect(serveur.appels, 0);
  });
}
