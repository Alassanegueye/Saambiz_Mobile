import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/abonnement_model.dart';
import '../models/paiement_model.dart';
import 'package:saambiz/core/widgets/barre_pagination.dart';

/// Une page de l'historique des paiements : la liste, et ou elle se situe.
class PagePaiements {
  final List<PaiementModel> paiements;
  final Pagination pagination;
  const PagePaiements(this.paiements, this.pagination);
}

abstract class AbonnementRemoteDataSource {
  Future<AbonnementModel> monAbonnement();
  Future<String> initierRenouvellement({num? montant});

  /// Une page de l'historique des paiements — dix, comme le serveur.
  Future<PagePaiements> historiquePaiementsAbonnement({int page});

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
    final res = await dio.post(
      AbonnementEndpoints.initierRenouvellement,
      data: montant != null ? {'montant': montant} : null,
    );
    final data = res.data;
    if (data is Map && data['paiementId'] != null) {
      return data['paiementId'].toString();
    }
    return '';
  }

  @override
  Future<PagePaiements> historiquePaiementsAbonnement({int page = 1}) async {
    final res = await dio.get(
      AbonnementEndpoints.historiquePaiements,
      queryParameters: {'page': page},
    );
    final liste = _extractList(
      res.data,
    ).map((e) => PaiementModel.fromJson(e as Map<String, dynamic>)).toList();
    return PagePaiements(
      liste,
      Pagination.depuis(
        res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null,
      ),
    );
  }

  @override
  Future<Map<String, String?>> payer({
    required num montant,
    required String numeroTelephone,
    required String methode,
  }) async {
    final res = await dio.post(
      PaiementEndpoints.payer,
      data: {
        'montant': montant,
        'numeroTelephone': numeroTelephone,
        'methode': methode,
      },
    );
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
    return _extractList(
      res.data,
    ).map((e) => PaiementModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
