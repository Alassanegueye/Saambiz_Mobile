import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  final FlutterSecureStorage secureStorage;
  final StreamController<bool> _authController =
  StreamController<bool>.broadcast();

  TokenService({required this.secureStorage});

  Stream<bool> get authChanges => _authController.stream;

  Future<bool> get isAuthenticated async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    return await secureStorage.read(key: 'jwt_token');
  }

  Future<void> setToken(String? token) async {
    if (token == null || token.isEmpty) {
      await secureStorage.delete(key: 'jwt_token');
    } else {
      await secureStorage.write(key: 'jwt_token', value: token);
    }
    final auth = await isAuthenticated;
    _authController.add(auth);
  }

  Future<void> clearToken() async {
    await secureStorage.delete(key: 'jwt_token');
    _authController.add(false);
  }

  void dispose() {
    _authController.close();
  }
}