import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/promotion_model.dart';

abstract class PromotionsRemoteDataSource {
  Future<List<PromotionModel>> promotionsActives();
  Future<List<PromotionModel>> mesPromotions();
  Future<PromotionModel> creerPromotion({
    required String titre,
    required String description,
    required num prixPromo,
    required String dateDebut,
    required String dateFin,
    required String produitId,
  });
  Future<PromotionModel> modifierPromotion(
    String id, {
    String? titre,
    String? description,
    num? prixPromo,
    String? dateDebut,
    String? dateFin,
  });
  Future<void> supprimerPromotion(String id);
}

class PromotionsRemoteDataSourceImpl implements PromotionsRemoteDataSource {
  final Dio dio;
  PromotionsRemoteDataSourceImpl(this.dio);

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      for (final k in ['promotions', 'data', 'items', 'results']) {
        if (raw[k] is List) return raw[k] as List;
      }
    }
    return const [];
  }

  PromotionModel _parseUne(dynamic data) {
    final map = (data is Map && data['promotion'] is Map)
        ? data['promotion'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return PromotionModel.fromJson(map);
  }

  @override
  Future<List<PromotionModel>> promotionsActives() async {
    final res = await dio.get(PromotionsEndpoints.actives);
    return _extractList(res.data)
        .map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PromotionModel>> mesPromotions() async {
    final res = await dio.get(PromotionsEndpoints.promotions);
    return _extractList(res.data)
        .map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PromotionModel> creerPromotion({
    required String titre,
    required String description,
    required num prixPromo,
    required String dateDebut,
    required String dateFin,
    required String produitId,
  }) async {
    final res = await dio.post(PromotionsEndpoints.promotions, data: {
      'titre': titre,
      'description': description,
      'prixPromo': prixPromo,
      'dateDebut': dateDebut,
      'dateFin': dateFin,
      'produitId': produitId,
    });
    return _parseUne(res.data);
  }

  @override
  Future<PromotionModel> modifierPromotion(
    String id, {
    String? titre,
    String? description,
    num? prixPromo,
    String? dateDebut,
    String? dateFin,
  }) async {
    final res = await dio.put(PromotionsEndpoints.parId(id), data: {
      if (titre != null) 'titre': titre,
      if (description != null) 'description': description,
      if (prixPromo != null) 'prixPromo': prixPromo,
      if (dateDebut != null) 'dateDebut': dateDebut,
      if (dateFin != null) 'dateFin': dateFin,
    });
    return _parseUne(res.data);
  }

  @override
  Future<void> supprimerPromotion(String id) async {
    await dio.delete(PromotionsEndpoints.parId(id));
  }
}
