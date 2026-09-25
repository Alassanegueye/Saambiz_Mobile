import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../home/data/models/boutique_model.dart';

abstract class FavorisRemoteDataSource {
  Future<void> ajouter(String boutiqueId);
  Future<void> supprimer(String boutiqueId);
  Future<List<BoutiqueModel>> mesFavoris();

  /// 🔔 Active/désactive la cloche. Retourne l'état final (true = activée).
  Future<bool> toggleCloche(String boutiqueId, bool active);

  /// État de suivi d'une boutique : { 'suivi': bool, 'clocheActive': bool }.
  Future<Map<String, bool>> statutSuivi(String boutiqueId);
}

class FavorisRemoteDataSourceImpl implements FavorisRemoteDataSource {
  final Dio dio;
  FavorisRemoteDataSourceImpl(this.dio);

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      for (final k in ['favoris', 'boutiques', 'data', 'items', 'results']) {
        if (raw[k] is List) return raw[k] as List;
      }
    }
    return const [];
  }

  @override
  Future<void> ajouter(String boutiqueId) async {
    await dio.post(FavorisEndpoints.favoris, data: {'boutiqueId': boutiqueId});
  }

  @override
  Future<void> supprimer(String boutiqueId) async {
    await dio.delete(FavorisEndpoints.parId(boutiqueId));
  }

  @override
  Future<List<BoutiqueModel>> mesFavoris() async {
    final res = await dio.get(FavorisEndpoints.favoris);
    return _extractList(res.data).map((e) {
      // Chaque élément est un favori { boutique, clocheActive } ; on fusionne
      // clocheActive dans la map boutique pour le modèle.
      if (e is Map && e['boutique'] is Map) {
        final boutique = Map<String, dynamic>.from(e['boutique'] as Map);
        boutique['clocheActive'] = e['clocheActive'];
        return BoutiqueModel.fromJson(boutique);
      }
      return BoutiqueModel.fromJson(e as Map<String, dynamic>);
    }).toList();
  }

  @override
  Future<bool> toggleCloche(String boutiqueId, bool active) async {
    final res = await dio.patch(
      FavorisEndpoints.cloche(boutiqueId),
      data: {'active': active},
    );
    final data = res.data;
    if (data is Map && data['clocheActive'] != null) {
      return data['clocheActive'] == true;
    }
    return active;
  }

  @override
  Future<Map<String, bool>> statutSuivi(String boutiqueId) async {
    final res = await dio.get(FavorisEndpoints.statut(boutiqueId));
    final data = res.data is Map ? res.data as Map : const {};
    return {
      'suivi': data['suivi'] == true,
      'clocheActive': data['clocheActive'] == true,
    };
  }
}
