import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/message_model.dart';

abstract class MessagerieRemoteDataSource {
  Future<MessageModel> envoyerMessage(
      {required String destinataireId, required String contenu});
  Future<List<ConversationModel>> conversations();
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
      for (final k in ['conversations', 'messages', 'data', 'items', 'results']) {
        if (raw[k] is List) return raw[k] as List;
      }
    }
    return const [];
  }

  @override
  Future<MessageModel> envoyerMessage(
      {required String destinataireId, required String contenu}) async {
    final res = await dio.post(MessagerieEndpoints.messages,
        data: {'destinataireId': destinataireId, 'contenu': contenu});
    final data = res.data;
    final map = (data is Map && data['message'] is Map)
        ? data['message'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return MessageModel.fromJson(map);
  }

  @override
  Future<List<ConversationModel>> conversations() async {
    final res = await dio.get(MessagerieEndpoints.conversations);
    return _extractList(res.data)
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MessageModel>> historique(String userId) async {
    final res = await dio.get(MessagerieEndpoints.historique(userId));
    return _extractList(res.data)
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> marquerLu(String messageId) async {
    await dio.put(MessagerieEndpoints.marquerLu(messageId));
  }

  @override
  Future<int> nombreNonLus() async {
    final res = await dio.get(MessagerieEndpoints.nonLus);
    final data = res.data;
    if (data is Map && data['nombre'] != null) {
      return int.tryParse(data['nombre'].toString()) ?? 0;
    }
    return 0;
  }
}
