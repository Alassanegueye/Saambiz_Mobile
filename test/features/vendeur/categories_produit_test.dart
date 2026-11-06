import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/vendeur/data/datasources/vendeur_produit_datasource.dart';

class _FauxServeur implements HttpClientAdapter {
  final Map<String, dynamic> corps;
  _FauxServeur(this.corps);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(corps),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  test('lit les catégories telles que le serveur les renvoie', () async {
    final dio = Dio()
      ..httpClientAdapter = _FauxServeur({
        'success': true,
        'categories': [
          {'id': '1', 'nom': 'Mode homme'},
        ],
      });

    final categories = await VendeurProduitDataSource(dio).categories();

    expect(categories.single.nom, 'Mode homme');
  });
}
