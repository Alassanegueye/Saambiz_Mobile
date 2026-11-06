import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';

/// Réglages que le backend sert sans authentification.
///
/// Les deux routes existaient depuis le début côté serveur et n'étaient
/// appelées par personne. Conséquences concrètes :
///
/// * le prix de l'abonnement n'était connu que du serveur, si bien que l'écran
///   de renouvellement envoyait `montant: 0` dès que la fiche d'abonnement
///   n'était pas encore chargée — le backend répondait « Le montant doit être
///   positif » et le vendeur ne pouvait pas payer ;
/// * une mise en maintenance ou une version minimale exigée n'atteignaient
///   jamais l'application, qui continuait d'appeler une API arrêtée.
class ConfigPubliqueService {
  final Dio dio;
  ConfigPubliqueService(this.dio);

  /// Prix de l'abonnement vendeur, en FCFA. `null` si le serveur est
  /// injoignable : l'appelant décide quoi faire, plutôt que de recevoir un
  /// zéro qui ressemble à un prix.
  Future<num?> prixAbonnement() async {
    try {
      final res = await dio.get(ConfigEndpoints.prixAbonnement);
      final data = res.data;
      final prix = data is Map ? data['prix'] : null;
      if (prix is num && prix > 0) return prix;
      if (prix is String) {
        final analyse = num.tryParse(prix);
        if (analyse != null && analyse > 0) return analyse;
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// État de service de l'application.
  Future<ConfigApp?> configApp() async {
    try {
      final res = await dio.get(ConfigEndpoints.appConfig);
      final data = res.data;
      if (data is! Map) return null;
      return ConfigApp(
        minVersionAndroid: data['minVersionAndroid']?.toString(),
        minVersionIos: data['minVersionIos']?.toString(),
        maintenance: data['maintenance'] == true,
        message: data['message']?.toString(),
      );
    } on DioException {
      return null;
    }
  }
}

class ConfigApp {
  final String? minVersionAndroid;
  final String? minVersionIos;
  final bool maintenance;
  final String? message;

  const ConfigApp({
    this.minVersionAndroid,
    this.minVersionIos,
    required this.maintenance,
    this.message,
  });

  /// Vrai si [version] est strictement antérieure à la version minimale
  /// exigée pour [ios].
  ///
  /// Comparaison segment par segment : `1.10.0` est postérieure à `1.9.0`,
  /// ce qu'une comparaison de chaînes aurait inversé.
  bool miseAJourExigee(String version, {required bool ios}) {
    final minimale = ios ? minVersionIos : minVersionAndroid;
    if (minimale == null || minimale.isEmpty) return false;
    return _comparer(version, minimale) < 0;
  }

  static int _comparer(String a, String b) {
    final sa = a.split('+').first.split('.');
    final sb = b.split('+').first.split('.');
    for (var i = 0; i < (sa.length > sb.length ? sa.length : sb.length); i++) {
      final na = i < sa.length ? int.tryParse(sa[i]) ?? 0 : 0;
      final nb = i < sb.length ? int.tryParse(sb[i]) ?? 0 : 0;
      if (na != nb) return na.compareTo(nb);
    }
    return 0;
  }
}
