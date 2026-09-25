import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/abonnement_model.dart';
import '../models/paiement_model.dart';

abstract class AbonnementRemoteDataSource {
  Future<AbonnementModel> monAbonnement();
  Future<String> initierRenouvellement({num? montant});
  Future<List<PaiementModel>> historiquePaiementsAbonnement();

  Future<Map<String, String?>> payer({
    required num montant,
    required String numeroTelephone,
    required String methode,
  });
  Future<PaiementModel> getPaiement(String id);
  Future<List<PaiementModel>> historiquePaiementGeneral();
}

class AbonnementRemoteDataSourceImpl implements AbonnementRemoteDataSource {
  final Dio dio;
  AbonnementRemoteDataSourceImpl(this.dio);

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      for (final k in ['paiements', 'data', 'items', 'results', 'historique']) {
        if (raw[k] is List) return raw[k] as List;
      }
    }
    return const [];
  }

  @override
  Future<AbonnementModel> monAbonnement() async {
    final res = await dio.get(AbonnementEndpoints.monAbonnement);
    return AbonnementModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<String> initierRenouvellement({num? montant}) async {
    final res = await dio.post(AbonnementEndpoints.initierRenouvellement,
        data: montant != null ? {'montant': montant} : null);
    final data = res.data;
    if (data is Map && data['paiementId'] != null) {
      return data['paiementId'].toString();
    }
    return '';
  }

  @override
  Future<List<PaiementModel>> historiquePaiementsAbonnement() async {
    final res = await dio.get(AbonnementEndpoints.historiquePaiements);
    return _extractList(res.data)
        .map((e) => PaiementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, String?>> payer({
    required num montant,
    required String numeroTelephone,
    required String methode,
  }) async {
    final res = await dio.post(PaiementEndpoints.payer, data: {
      'montant': montant,
      'numeroTelephone': numeroTelephone,
      'methode': methode,
    });
    final data = res.data;
    return {
      'paymentUrl': data is Map ? data['paymentUrl']?.toString() : null,
      'transactionId': data is Map ? data['transactionId']?.toString() : null,
    };
  }

  @override
  Future<PaiementModel> getPaiement(String id) async {
    final res = await dio.get(PaiementEndpoints.paiement(id));
    return PaiementModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<PaiementModel>> historiquePaiementGeneral() async {
    final res = await dio.get(PaiementEndpoints.historique);
    return _extractList(res.data)
        .map((e) => PaiementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
