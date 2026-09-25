import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<void> openWhatsApp(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('❌ Impossible d’ouvrir WhatsApp avec ce lien: $url');
      throw 'Impossible d’ouvrir WhatsApp';
    }
  }
}