import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../home/domain/entities/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> notifications();
  Future<int> nombreNonLues();
  Future<void> marquerToutesLues();
  Future<void> marquerLue(String id);

  /// Device token FCM — la couche d'appel REST est prête, le token pourra
  /// être branché sur firebase_messaging plus tard (non présent au pubspec).
  Future<void> registerDeviceToken({required String token, required String platform});
  Future<void> unregisterDeviceToken(String token);
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final Dio dio;
  NotificationsRemoteDataSourceImpl(this.dio);

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      for (final k in ['notifications', 'data', 'items', 'results']) {
        if (raw[k] is List) return raw[k] as List;
      }
    }
    return const [];
  }

  @override
  Future<List<NotificationModel>> notifications() async {
    final res = await dio.get(NotificationsEndpoints.notifications);
    return _extractList(res.data)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> nombreNonLues() async {
    final res = await dio.get(NotificationsEndpoints.nonLues);
    final data = res.data;
    if (data is Map && data['nombre'] != null) {
      return int.tryParse(data['nombre'].toString()) ?? 0;
    }
    return 0;
  }

  @override
  Future<void> marquerToutesLues() async {
    await dio.put(NotificationsEndpoints.toutesLues);
  }

  @override
  Future<void> marquerLue(String id) async {
    await dio.put(NotificationsEndpoints.marquerLue(id));
  }

  @override
  Future<void> registerDeviceToken(
      {required String token, required String platform}) async {
    await dio.post(NotificationsEndpoints.registerDeviceToken,
        data: {'token': token, 'platform': platform});
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    await dio.delete(NotificationsEndpoints.unregisterDeviceToken,
        data: {'token': token});
  }
}
