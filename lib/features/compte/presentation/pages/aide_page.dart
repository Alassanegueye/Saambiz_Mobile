import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/infos_app.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/url_externe.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/profil_kit.dart';

/// Centre d'aide : questions fréquentes et moyens de contacter SaamBiz.
/// [contactSeulement] ouvre directement sur les moyens de contact.
class AidePage extends StatelessWidget {
  final bool contactSeulement;
  const AidePage({super.key, this.contactSeulement = false});

  static const _faq = <(String, String)>[
    (
      'SaamBiz est-il gratuit ?',
      "Oui. Ouvrir une boutique, publier des produits et recevoir des commandes ne coûte rien, et SaamBiz ne prélève aucune commission sur vos ventes.",
    ),
    (
      'Comment créer ma boutique ?',
      "Créez un compte vendeur depuis l'écran de connexion (« Créer un compte », puis « Vendeur »), confirmez votre e-mail avec le code reçu, puis renseignez le nom, le logo et les catégories de votre boutique.",
    ),
    (
      'Où trouver le lien de ma boutique ?',
      "Dans Compte → Mon site web. Votre boutique a sa propre adresse, saambiz.com/b/votre-boutique : partagez-la sur WhatsApp ou Instagram, vos clients commandent sans installer l'application.",
    ),
    (
      'Je n\'ai pas reçu le code de confirmation',
      "Vérifiez vos courriers indésirables, puis touchez « Renvoyer le code » sur l'écran de vérification. Le code est valable quelques minutes.",
    ),
    (
      'Quels moyens de paiement sont acceptés ?',
      'Wave, Orange Money, Free Money et les cartes bancaires.',
    ),
    (
      'Comment suivre une commande ?',
      'Ouvrez l\'onglet Commandes : chaque commande indique son statut (en attente, confirmée, expédiée, livrée) et se met à jour en temps réel.',
    ),
    (
      'Comment supprimer mon compte ?',
      'Compte → Sécurité → Supprimer mon compte. La suppression est définitive.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppAppBar(title: contactSeulement ? 'Nous contacter' : 'Centre d\'aide'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (!contactSeulement) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Questions fréquentes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ),
            Material(
              color: AppColor.kWhite,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < _faq.length; i++) ...[
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        iconColor: AppColor.kPrimary,
                        collapsedIconColor: AppColor.kGrayscale30,
                        title: Text(
                          _faq[i].$1,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColor.kGrayscaleDark100,
                          ),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _faq[i].$2,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                height: 1.55,
                                color: AppColor.kGrayscale40,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < _faq.length - 1) const Divider(height: 1, indent: 16, endIndent: 16, color: AppColor.kLine),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          SectionProfil(
            titre: 'Nous contacter',
            entrees: [
              LigneProfil(
                icone: Icons.chat_outlined,
                libelle: 'WhatsApp',
                sousTitre: 'Réponse rapide, 7j/7',
                onTap: () => _ouvrir(context, 'https://wa.me/${InfosApp.supportWhatsapp}'),
              ),
              LigneProfil(
                icone: Icons.email_outlined,
                libelle: InfosApp.supportEmail,
                sousTitre: 'Par e-mail',
                onTap: () => _ouvrir(context, 'mailto:${InfosApp.supportEmail}'),
              ),
              LigneProfil(
                icone: Icons.phone_outlined,
                libelle: InfosApp.supportTelephone,
                sousTitre: 'Par téléphone',
                onTap: () => _ouvrir(context, 'tel:${InfosApp.supportTelephone}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _ouvrir(BuildContext context, String url) async {
    final ok = await UrlExterne.lancer(url);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir ce lien sur cet appareil.')),
      );
    }
  }
}
