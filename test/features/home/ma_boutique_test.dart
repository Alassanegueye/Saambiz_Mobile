import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/services/token_service.dart';
import 'package:saambiz/features/home/data/datasources/produit_remote_datasource.dart';
import 'package:saambiz/injection_container.dart';

class _FauxJeton implements TokenService {
  @override
  Future<String?> getToken() async => 'jeton';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Répond comme le back, et retient le chemin appelé.
class _FauxServeur implements HttpClientAdapter {
  final int statut;
  final Map<String, dynamic> corps;
  String? chemin;

  _FauxServeur(this.statut, this.corps);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    chemin = options.path;
    return ResponseBody.fromString(
      jsonEncode(corps),
      statut,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ProduitRemoteDataSourceImpl _source(_FauxServeur serveur) =>
    ProduitRemoteDataSourceImpl(Dio()..httpClientAdapter = serveur);

void main() {
  setUpAll(() => sl.registerSingleton<TokenService>(_FauxJeton()));
  tearDownAll(() => sl.unregister<TokenService>());

  test('lit la boutique du vendeur connecté, pas la liste publique', () async {
    final serveur = _FauxServeur(200, {
      'success': true,
      'boutique': {'id': 'b1', 'nom': 'Test_Shop'},
    });

    final boutique = await _source(serveur).getMaBoutique();

    expect(serveur.chemin, '/vendeur/ma-boutique');
    expect(boutique?.nom, 'Test_Shop');
  });

  test('un vendeur sans boutique : null, jamais celle d\'un autre', () async {
    final serveur = _FauxServeur(404, {'message': 'Boutique introuvable'});

    expect(await _source(serveur).getMaBoutique(), isNull);
  });

  test('une panne du serveur reste une erreur', () async {
    final serveur = _FauxServeur(500, {'message': 'Erreur'});

    expect(_source(serveur).getMaBoutique(), throwsA(isA<DioException>()));
  });
}
