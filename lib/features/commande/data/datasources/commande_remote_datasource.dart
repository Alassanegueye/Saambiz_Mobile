import 'package:dio/dio.dart';
import '../models/commande_model.dart';
import '../../../../core/constants/api_endpoints.dart';

abstract class CommandeRemoteDataSource {
  Future<CommandeModel> creerCommande(Map<String, dynamic> body);
  Future<List<CommandeModel>> mesCommandes({String? statut});
  Future<CommandeModel> getCommande(String id);
  Future<CommandeModel> annuler(String id);
  // Retourne l'URL de paiement (ou null pour Wave/à compléter)
  Future<String?> payer(String id, {required String methode, String? numeroTelephone});
  // Vendeur
  Future<List<CommandeModel>> commandesVendeur({String? statut});
  Future<CommandeModel> changerStatut(String id, String statut);
  // Retour (acheteur) — uniquement si la commande est au statut 'livree'
  Future<void> demandeRetour(String id, {required String raison});
}

class CommandeRemoteDataSourceImpl implements CommandeRemoteDataSource {
  final Dio dio;
  CommandeRemoteDataSourceImpl(this.dio);

  List<CommandeModel> _parseListe(dynamic data) {
    final raw = (data is Map && data['commandes'] is List)
        ? data['commandes'] as List
        : (data is List ? data : <dynamic>[]);
    return raw
        .map((e) => CommandeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  CommandeModel _parseUne(dynamic data) {
    final map = (data is Map && data['commande'] is Map)
        ? data['commande'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return CommandeModel.fromJson(map);
  }

  @override
  Future<CommandeModel> creerCommande(Map<String, dynamic> body) async {
    final res = await dio.post(CommandeEndpoints.commandes, data: body);
    return _parseUne(res.data);
  }

  @override
  Future<List<CommandeModel>> mesCommandes({String? statut}) async {
    final res = await dio.get(CommandeEndpoints.commandes,
        queryParameters: statut != null ? {'statut': statut} : null);
    return _parseListe(res.data);
  }

  @override
  Future<CommandeModel> getCommande(String id) async {
    final res = await dio.get(CommandeEndpoints.commande(id));
    return _parseUne(res.data);
  }

  @override
  Future<CommandeModel> annuler(String id) async {
    final res = await dio.put(CommandeEndpoints.annuler(id));
    return _parseUne(res.data);
  }

  @override
  Future<String?> payer(String id,
      {required String methode, String? numeroTelephone}) async {
    final res = await dio.post(CommandeEndpoints.payer(id), data: {
      'methode': methode,
      if (numeroTelephone != null) 'numeroTelephone': numeroTelephone,
    });
    final data = res.data;
    if (data is Map && data['paymentUrl'] != null) {
      return data['paymentUrl'].toString();
    }
    return null;
  }

  @override
  Future<List<CommandeModel>> commandesVendeur({String? statut}) async {
    final res = await dio.get(CommandeEndpoints.commandesVendeur,
        queryParameters: statut != null ? {'statut': statut} : null);
    return _parseListe(res.data);
  }

  @override
  Future<CommandeModel> changerStatut(String id, String statut) async {
    final res = await dio.patch(CommandeEndpoints.statut(id), data: {'statut': statut});
    return _parseUne(res.data);
  }

  @override
  Future<void> demandeRetour(String id, {required String raison}) async {
    await dio.post(CommandeEndpoints.demandeRetour(id), data: {'raison': raison});
  }
}
