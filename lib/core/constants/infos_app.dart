import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Informations publiques de l'application.
///
/// La version reprend celle du pubspec (à mettre à jour ensemble). Les
/// coordonnées du service client peuvent être surchargées dans `.env` ; à
/// défaut, ce sont celles du site saambiz.com.
class InfosApp {
  InfosApp._();

  static const String nom = 'SaamBiz';
  static const String version = '1.0.0';
  static const String site = 'https://www.saambiz.com';

  /// Fiche Play Store (identifiant Android de l'application).
  static const String lienPlayStore =
      'https://play.google.com/store/apps/details?id=com.saambiz.app';

  static String _env(String cle, String defaut) {
    try {
      final v = (dotenv.env[cle] ?? '').trim();
      return v.isEmpty ? defaut : v;
    } catch (_) {
      return defaut;
    }
  }

  /// Numéro WhatsApp du service client, au format international (221…).
  static String get supportWhatsapp => _env('SUPPORT_WHATSAPP', '221775929390');
  static String get supportEmail => _env('SUPPORT_EMAIL', 'contact@saambiz.com');
  static String get supportTelephone => _env('SUPPORT_TELEPHONE', '+221775929390');
}
