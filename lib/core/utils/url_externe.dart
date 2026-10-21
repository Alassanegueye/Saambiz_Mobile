import 'package:url_launcher/url_launcher.dart';

/// Ouverture d'URL externes, limitée à quelques schémas sûrs : une URL venue
/// du serveur ne doit pas pouvoir ouvrir n'importe quelle application.
class UrlExterne {
  UrlExterne._();

  static const Set<String> _autorises = {'https', 'http', 'whatsapp', 'tel', 'mailto'};

  static Future<bool> lancer(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !_autorises.contains(uri.scheme.toLowerCase())) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
