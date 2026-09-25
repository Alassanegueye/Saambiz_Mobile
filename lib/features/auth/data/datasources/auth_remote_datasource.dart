import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/utils/app_logger.dart';

/// Connexion uniquement.
///
/// L'inscription a son propre parcours — `SignupRemoteDataSource` — parce
/// qu'elle se fait en deux temps : l'adresse est vérifiée par code AVANT que
/// le compte n'existe. Une seconde implémentation ici signifierait deux
/// comportements à tenir alignés, et une mise en production où l'on ne sait
/// plus lequel est joué.
abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String identifiant, String motDePasse);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final String _loginPath;

  AuthRemoteDataSourceImpl({required this.dio})
      : _loginPath = _normalisePath(
    dotenv.get(
      'AUTH_LOGIN_PATH',
      fallback: '/auth/login',
    ),
  );

  static String _normalisePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw StateError('AUTH_LOGIN_PATH ne peut pas être vide.');
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  @override
  Future<AuthResponseModel> login(
      String identifiant,
      String motDePasse,
      ) async {
    try {
      final isEmail = RegExp(r'\S+@\S+\.\S+').hasMatch(identifiant);

      final Map<String, dynamic> data;

      if (isEmail) {
        data = {
          'email': identifiant,
          'mot_de_passe': motDePasse,
        };
      } else {
        data = {
          'telephone': identifiant,
          'mot_de_passe': motDePasse,
        };
      }

      logDebug('📤 DATA ENVOYÉE: $data');

      final response = await dio.post(
        _loginPath,
        data: data,
      );

      return AuthResponseModel.fromJson(response.data);

    } on DioException catch (e) {
      logDebug('❌ ERROR: ${e.response?.data}');
      rethrow;
    }
  }
}
