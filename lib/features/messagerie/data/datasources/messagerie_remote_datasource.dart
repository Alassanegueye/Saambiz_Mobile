import '../../../../core/widgets/barre_pagination.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/message_model.dart';

/// Une page de conversations : la liste, et où elle se situe.
class PageConversations {
  final List<ConversationModel> conversations;
  final Pagination pagination;
  const PageConversations(this.conversations, this.pagination);
}

abstract class MessagerieRemoteDataSource {
  Future<MessageModel> envoyerMessage({
    required String destinataireId,
    required String contenu,
  });

  /// Une page de conversations.
  Future<PageConversations> conversations({int page});
  Future<List<MessageModel>> historique(String userId);
  Future<void> marquerLu(String messageId);
  Future<int> nombreNonLus();
}

class MessagerieRemoteDataSourceImpl implements MessagerieRemoteDataSource {
  final Dio dio;
  MessagerieRemoteDataSourceImpl(this.dio);

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      for (final k in [
        'conversations',
        'messages',
        'data',
        'items',
        'results',
      ]) {
        if (raw[k] is List) return raw[k] as List;
      }
    }
    return const [];
  }

  @override
  Future<MessageModel> envoyerMessage({
    required String destinataireId,
    required String contenu,
  }) async {
    final res = await dio.post(
      MessagerieEndpoints.messages,
      data: {'destinataireId': destinataireId, 'contenu': contenu},
    );
    final data = res.data;
    final map = (data is Map && data['message'] is Map)
        ? data['message'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return MessageModel.fromJson(map);
  }

  @override
  Future<PageConversations> conversations({int page = 1}) async {
    final res = await dio.get(
      MessagerieEndpoints.conversations,
      queryParameters: {'page': page},
    );
    return PageConversations(
      _extractList(res.data)
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      Pagination.depuis(
        res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null,
      ),
    );
  }

  @override
  Future<List<MessageModel>> historique(String userId) async {
    final res = await dio.get(MessagerieEndpoints.historique(userId));
    return _extractList(
      res.data,
    ).map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> marquerLu(String messageId) async {
    await dio.put(MessagerieEndpoints.marquerLu(messageId));
  }

  @override
  Future<int> nombreNonLus() async {
    final res = await dio.get(MessagerieEndpoints.nonLus);
    final data = res.data;
    if (data is! Map) return 0;
    // La clé lue était `nombre`, que le backend n'envoie pas : il répond
    // `{ nonLus: 4 }`. Le compteur restait donc à zéro en permanence, et
    // l'utilisateur n'était jamais averti d'un message en attente.
    for (final cle in ['nonLus', 'nombre', 'count', 'total']) {
      final valeur = data[cle];
      if (valeur != null) return int.tryParse(valeur.toString()) ?? 0;
    }
    return 0;
  }
}
