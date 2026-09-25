import 'package:dio/dio.dart';
import '../../../../core/routes/app_router.dart';
import '../models/produit_model.dart';
import '../models/boutique_model.dart';
import '../../../../core/services/token_service.dart';
import '../../../../injection_container.dart';
import '../../../../core/connection/auth_interceptor.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/constants/api_endpoints.dart';

abstract class ProduitRemoteDataSource {
  Future<List<ProduitModel>> getProduits();
  Future<List<ProduitModel>> rechercher(String query);
  Future<List<ProduitModel>> filtrerVille(String ville);
  Future<List<BoutiqueModel>> getBoutiques();
  Future<List<ProduitModel>> getProduitsByBoutique(String boutiqueId);
  Future<String> getWhatsappUrl(String produitId);
  Future<Map<String, dynamic>> getAvisBoutique(String boutiqueId);
  Future<Map<String, dynamic>> laisserAvis(String boutiqueId, int note, String? commentaire);
}

class ProduitRemoteDataSourceImpl implements ProduitRemoteDataSource {
  final Dio dio;

  ProduitRemoteDataSourceImpl(this.dio);

  // ─────────────────────────────────────────────
  // 🔐 Gestion centralisée erreur token
  // ─────────────────────────────────────────────
  void _handleAuthError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;

      if (data is Map && data['message'] == 'Token expiré') {
        AuthInterceptor.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRouter.loginRoute,
              (route) => false,
        );
      }

      // Bonus : gérer aussi 401
      if (e.response?.statusCode == 401) {
        AuthInterceptor.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRouter.loginRoute,
              (route) => false,
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  // 📦 Extract list helper
  // ─────────────────────────────────────────────
  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;

    if (raw is Map<String, dynamic>) {
      for (final key in [
        'produits', 'boutiques', 'data', 'content', 'items', 'results', 'list'
      ]) {
        if (raw[key] is List) {
          return raw[key] as List;
        }
      }

      final listEntry = raw.entries.firstWhere(
            (e) => e.value is List,
        orElse: () => const MapEntry('', []),
      );

      if (listEntry.value is List) return listEntry.value as List;
    }

    throw Exception('Impossible d\'extraire une liste');
  }

  // ─────────────────────────────────────────────
  // 🔐 Token
  // ─────────────────────────────────────────────
  Future<String?> _getToken() async {
    return await sl<TokenService>().getToken();
  }

  Future<Options> _getOptions() async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token non disponible');
    }

    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  // ─────────────────────────────────────────────
  // 🛍️ Produits
  // ─────────────────────────────────────────────
  @override
  Future<List<ProduitModel>> getProduits() async {
    try {
      final response = await dio.get(
        ProduitEndpoints.listeProduits,
        options: await _getOptions(),
      );

      final data = _extractList(response.data);

      return data
          .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🏪 Boutiques
  // ─────────────────────────────────────────────
  @override
  Future<List<BoutiqueModel>> getBoutiques() async {
    try {
      final response = await dio.get(
        ProduitEndpoints.listeBoutiques,
        options: await _getOptions(),
      );

      final data = _extractList(response.data);

      return data
          .map((e) => BoutiqueModel.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🔍 Recherche
  // ─────────────────────────────────────────────
  @override
  Future<List<ProduitModel>> rechercher(String query) async {
    try {
      final response = await dio.get(
        ProduitEndpoints.rechercherProduitCategorie,
        queryParameters: {'search': query},
        options: await _getOptions(),
      );

      final data = _extractList(response.data);

      return data
          .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🏙️ Filtrer ville
  // ─────────────────────────────────────────────
  @override
  Future<List<ProduitModel>> filtrerVille(String ville) async {
    try {
      final response = await dio.get(
        ProduitEndpoints.filtrerProduitVille,
        queryParameters: {'ville': ville},
        options: await _getOptions(),
      );

      final data = _extractList(response.data);

      return data
          .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🏪 Produits par boutique
  // ─────────────────────────────────────────────
  @override
  Future<List<ProduitModel>> getProduitsByBoutique(String boutiqueId) async {
    try {
      final response = await dio.get(
        ProduitEndpoints.listeProduitParBoutique(boutiqueId),
        options: await _getOptions(),
      );

      final data = _extractList(
        response.data is Map ? response.data['produits'] ?? response.data : response.data,
      );

      return data
          .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 💬 WhatsApp — contacter vendeur
  // ─────────────────────────────────────────────
  @override
  Future<String> getWhatsappUrl(String produitId) async {
    try {
      final response = await dio.get(
        ProduitEndpoints.contacterVendeurParWhatsapp(produitId),
        options: await _getOptions(),
      );

      final data = response.data;
      logDebug('📩 Réponse brute WhatsApp: $data'); // LOG complet

      if (data is Map<String, dynamic>) {
        final url = data['whatsappUrl']; // ✅ Ici on prend le bon champ
        logDebug('🔗 URL WhatsApp extraite: $url'); // LOG URL

        if (url is String && url.isNotEmpty) {
          return url;
        }
      }

      throw Exception('URL WhatsApp introuvable dans la réponse');
    } catch (e) {
      logDebug('❌ Erreur WhatsApp: $e');
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // ⭐ Avis / notation boutique
  // ─────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> getAvisBoutique(String boutiqueId) async {
    try {
      final response = await dio.get('/avis/boutique/$boutiqueId');
      final data = response.data;
      return data is Map<String, dynamic> ? data : {'moyenne': 0, 'total': 0, 'avis': []};
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> laisserAvis(String boutiqueId, int note, String? commentaire) async {
    try {
      final response = await dio.post(
        '/avis',
        data: {'boutiqueId': boutiqueId, 'note': note, 'commentaire': commentaire},
        options: await _getOptions(),
      );
      final data = response.data;
      return data is Map<String, dynamic> ? data : {};
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }
}