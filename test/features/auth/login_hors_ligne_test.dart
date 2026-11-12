import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:saambiz/features/auth/data/models/user_model.dart';
import 'package:saambiz/features/auth/data/repositories/auth_repository_impl.dart';

/// Source distante qui échoue comme sur un téléphone hors ligne : Dio ne
/// trouve pas l'adresse du serveur.
class _SourceHorsLigne implements AuthRemoteDataSource {
  @override
  Future<AuthResponseModel> login(String identifiant, String motDePasse) =>
      Future.error(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/auth/login'),
          reason: "Failed host lookup: 'api.saambiz.com'",
          error: const SocketException("Failed host lookup: 'api.saambiz.com'"),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test(
    'hors ligne, la connexion dit en français que le réseau manque',
    () async {
      final repo = AuthRepositoryImpl(remoteDataSource: _SourceHorsLigne());
      final res = await repo.login('client@exemple.com', 'motdepasse');
      final message = res.fold((f) => f.errorMessage, (_) => 'succès');
      expect(message, contains("n'êtes pas connecté à internet"));
      expect(message, isNot(contains('Failed host lookup')));
      expect(message, isNot(contains('connection errored')));
    },
  );
}
