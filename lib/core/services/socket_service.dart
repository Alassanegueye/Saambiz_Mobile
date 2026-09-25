import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../utils/app_logger.dart';
import 'token_service.dart';

/// Wrapper autour de socket_io_client pour la messagerie et les notifications
/// temps réel. Se (re)connecte/déconnecte automatiquement en suivant le
/// `Stream<bool>` d'authentification exposé par [TokenService].
class SocketService {
  final TokenService tokenService;

  io.Socket? _socket;
  StreamSubscription<bool>? _authSub;

  final StreamController<Map<String, dynamic>> _onNewMessageCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _onNewNotificationCtrl =
      StreamController<Map<String, dynamic>>.broadcast();

  SocketService({required this.tokenService}) {
    _authSub = tokenService.authChanges.listen(_onAuthChanged);
    // Se connecter immédiatement si déjà authentifié au démarrage.
    tokenService.isAuthenticated.then((authenticated) {
      if (authenticated) _onAuthChanged(true);
    });
  }

  /// Flux des nouveaux messages reçus (événement socket `message:new`).
  Stream<Map<String, dynamic>> get onNewMessage => _onNewMessageCtrl.stream;

  /// Flux des nouvelles notifications reçues (événement socket `notification:new`).
  Stream<Map<String, dynamic>> get onNewNotification =>
      _onNewNotificationCtrl.stream;

  Future<void> _onAuthChanged(bool authenticated) async {
    if (authenticated) {
      await _connect();
    } else {
      _disconnect();
    }
  }

  /// Origine du serveur socket.io (racine, sans le suffixe de chemin de l'API).
  String _socketOrigin() {
    final baseUrl = dotenv.maybeGet('API_BASE_URL')?.trim() ?? '';
    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return baseUrl;
    return uri.replace(path: '', query: '').toString();
  }

  Future<void> _connect() async {
    _disconnect();

    final token = await tokenService.getToken();
    if (token == null || token.isEmpty) return;

    final origin = _socketOrigin();
    if (origin.isEmpty) return;

    _socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!
      ..onConnect((_) => logDebug('🔌 Socket connecté'))
      ..onDisconnect((_) => logDebug('🔌 Socket déconnecté'))
      ..onConnectError((e) => logDebug('⚠️ Socket erreur connexion: $e'))
      ..onError((e) => logDebug('⚠️ Socket erreur: $e'))
      ..on('message:new', (data) {
        if (data is Map) {
          _onNewMessageCtrl.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('notification:new', (data) {
        if (data is Map) {
          _onNewNotificationCtrl.add(Map<String, dynamic>.from(data));
        }
      })
      ..connect();
  }

  void _disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    _authSub?.cancel();
    _disconnect();
    _onNewMessageCtrl.close();
    _onNewNotificationCtrl.close();
  }
}
