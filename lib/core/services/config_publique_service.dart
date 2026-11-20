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

  /// Centre d'aide (questions fréquentes et contacts), géré depuis le
  /// dashboard admin. `null` si le serveur est injoignable.
  Future<CentreAide?> centreAide() async {
    try {
      final res = await dio.get(ConfigEndpoints.centreAide);
      final data = res.data;
      if (data is! Map) return null;
      final c = data['contacts'] is Map ? data['contacts'] as Map : const {};
      String? lire(String k) {
        final v = c[k]?.toString().trim() ?? '';
        return v.isEmpty ? null : v;
      }

      final questions = <(String, String)>[
        for (final q
            in (data['questions'] is List
                ? data['questions'] as List
                : const []))
          if (q is Map &&
              (q['question'] ?? '').toString().trim().isNotEmpty &&
              (q['reponse'] ?? '').toString().trim().isNotEmpty)
            (q['question'].toString().trim(), q['reponse'].toString().trim()),
      ];
      return CentreAide(
        whatsapp: lire('whatsapp'),
        email: lire('email'),
        telephone: lire('telephone'),
        questions: questions,
      );
    } on DioException {
      return null;
    }
  }

  /// Dernier état de service connu, pour les écrans qui en ont besoin sans
  /// pouvoir attendre : l'écran de commande doit savoir tout de suite si le
  /// paiement en ligne est ouvert. Rempli au démarrage par `AppBootstrap`.
  static ConfigApp? dernierConnu;

  /// Wave et Orange Money sont-ils ouverts ?
  ///
  /// FERMÉ TANT QU'ON NE SAIT PAS : au premier lancement, hors ligne, ou
  /// face à un serveur plus ancien, l'application ne propose pas un
  /// paiement qui n'aboutirait pas.
  static bool get paiementEnLigneOuvert =>
      dernierConnu?.paiementEnLigneActif ?? false;

  /// État de service de l'application.
  Future<ConfigApp?> configApp() async {
    try {
      final res = await dio.get(ConfigEndpoints.appConfig);
      final data = res.data;
      if (data is! Map) return null;
      final config = ConfigApp(
        minVersionAndroid: data['minVersionAndroid']?.toString(),
        minVersionIos: data['minVersionIos']?.toString(),
        maintenance: data['maintenance'] == true,
        message: data['message']?.toString(),
        paiementEnLigneActif: data['paiementEnLigneActif'] == true,
      );
      dernierConnu = config;
      return config;
    } on DioException {
      // Serveur injoignable : on garde ce qu'on savait, sans l'inventer.
      return null;
    }
  }
}

/// Contenu du centre d'aide rédigé depuis le dashboard admin.
class CentreAide {
  final String? whatsapp;
  final String? email;
  final String? telephone;
  final List<(String, String)> questions;

  const CentreAide({
    this.whatsapp,
    this.email,
    this.telephone,
    this.questions = const [],
  });
}

class ConfigApp {
  final String? minVersionAndroid;
  final String? minVersionIos;
  final bool maintenance;
  final String? message;

  /// Wave et Orange Money sont-ils ouverts ?
  ///
  /// FAUX PAR DÉFAUT, et c'est volontaire : un serveur muet, une réponse
  /// illisible, une version plus ancienne de l'API, et l'application
  /// n'affiche pas un paiement qui n'aboutirait pas. Le jour de
  /// l'ouverture, c'est le serveur qui le dira — aucune mise à jour de
  /// l'application à installer.
  final bool paiementEnLigneActif;

  const ConfigApp({
    this.minVersionAndroid,
    this.minVersionIos,
    required this.maintenance,
    this.message,
    this.paiementEnLigneActif = false,
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
