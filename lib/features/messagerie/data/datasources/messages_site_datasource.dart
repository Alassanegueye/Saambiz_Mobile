import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';

/// Message laissé sur la page « Contact » du site de la boutique. Le visiteur
/// n'a pas de compte : on a son nom (s'il l'a donné) et son numéro, c'est là
/// que le vendeur lui répond.
class MessageSite {
  final String id;
  final String? nom;
  final String telephone;
  final String contenu;
  final bool lu;
  final DateTime? date;

  const MessageSite({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.contenu,
    required this.lu,
    required this.date,
  });

  String get auteur => (nom ?? '').trim().isEmpty ? 'Visiteur du site' : nom!.trim();

  MessageSite copieLu() => MessageSite(
        id: id,
        nom: nom,
        telephone: telephone,
        contenu: contenu,
        lu: true,
        date: date,
      );

  factory MessageSite.fromJson(Map<String, dynamic> j) => MessageSite(
        id: j['id']?.toString() ?? '',
        nom: j['nom']?.toString(),
        telephone: j['telephone']?.toString() ?? '',
        contenu: j['contenu']?.toString() ?? '',
        lu: j['lu'] == true,
        date: DateTime.tryParse(
          (j['createdAt'] ?? j['created_at'] ?? '').toString(),
        )?.toLocal(),
      );
}

class MessagesSiteDataSource {
  final Dio dio;
  const MessagesSiteDataSource(this.dio);

  Future<List<MessageSite>> lister() async {
    final res = await dio.get(MessagerieEndpoints.site);
    final data = res.data;
    final liste = data is Map ? data['messages'] : data;
    if (liste is! List) return const [];
    return liste
        .whereType<Map>()
        .map((e) => MessageSite.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> marquerLu(String id) =>
      dio.put(MessagerieEndpoints.siteLu(id));

  Future<void> supprimer(String id) =>
      dio.delete(MessagerieEndpoints.siteMessage(id));
}
