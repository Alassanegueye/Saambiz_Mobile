import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/signalement_model.dart';

abstract class SignalementsRemoteDataSource {
  Future<SignalementModel> creerSignalement({
    required String type,
    required String raison,
    required String description,
    required String cibleId,
  });
  Future<List<SignalementModel>> mesSignalements();
}

class SignalementsRemoteDataSourceImpl implements SignalementsRemoteDataSource {
  final Dio dio;
  SignalementsRemoteDataSourceImpl(this.dio);

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      for (final k in ['signalements', 'data', 'items', 'results']) {
        if (raw[k] is List) return raw[k] as List;
      }
    }
    return const [];
  }

  @override
  Future<SignalementModel> creerSignalement({
    required String type,
    required String raison,
    required String description,
    required String cibleId,
  }) async {
    final res = await dio.post(SignalementsEndpoints.signalements, data: {
      'type': type,
      'raison': raison,
      'description': description,
      'cibleId': cibleId,
    });
    final data = res.data;
    final map = (data is Map && data['signalement'] is Map)
        ? data['signalement'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return SignalementModel.fromJson(map);
  }

  @override
  Future<List<SignalementModel>> mesSignalements() async {
    final res = await dio.get(SignalementsEndpoints.mesSignalements);
    return _extractList(res.data)
        .map((e) => SignalementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
