import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/utils/image_url.dart';

import '../../../../core/theme/app_color.dart';
import '../../data/models/commande_model.dart';

/// Couleur d'un statut de commande, selon la charte (reprise de Yobante
/// Boutique) : or foncé quand une action est attendue, bleu pour une étape en
/// cours, vert pour la livraison, rouge pour une annulation.
Color couleurStatutCommande(String statut) {
  switch (statut) {
    case 'livree':
      return AppColor.kSucces;
    case 'annulee':
      return AppColor.kErreur;
    case 'prete':
    case 'en_livraison':
      return AppColor.kPrimary;
    case 'confirmee':
    case 'en_preparation':
      return AppColor.kPrimaryMedium;
    case 'en_attente':
      return AppColor.kSecondaryDark;
    default:
      return AppColor.kGrayscale40;
  }
}

IconData iconeStatutCommande(String statut) {
  switch (statut) {
    case 'livree':
      return Icons.check_circle_rounded;
    case 'annulee':
      return Icons.cancel_rounded;
    case 'en_livraison':
      return Icons.local_shipping_rounded;
    case 'prete':
      return Icons.inventory_2_rounded;
    case 'confirmee':
    case 'en_preparation':
      return Icons.autorenew_rounded;
    default:
      return Icons.schedule_rounded;
  }
}

String _date(DateTime? d) {
  if (d == null) return '—';
  const mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
  final l = d.toLocal();
  return '${l.day} ${mois[l.month - 1]} ${l.year}';
}

String _montant(double v) {
  final s = v.toStringAsFixed(0);
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b FCFA';
}

/// Badge de statut : pastille pleine, point blanc, libellé.
class _BadgeStatut extends StatelessWidget {
  final String statut;
  const _BadgeStatut(this.statut);

  @override
  Widget build(BuildContext context) {
    final couleur = couleurStatutCommande(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: couleur.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColor.kWhite, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            kStatutCommandeLabels[statut] ?? statut,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.kWhite),
          ),
        ],
      ),
    );
  }
}

/// Carte d'une commande, dans le style de Yobante Boutique : photo du
/// premier article avec le statut en surimpression, puis référence, date,
/// total et état du paiement.
class CommandeCard extends StatelessWidget {
  final CommandeModel commande;
  final VoidCallback onTap;
  const CommandeCard({super.key, required this.commande, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nbArticles = commande.lignes.fold<int>(0, (s, l) => s + l.quantite);
    final premiereImage = commande.lignes.isNotEmpty ? commande.lignes.first.imageProduit : null;
    final aUneImage = premiereImage != null && premiereImage.isNotEmpty;
    final paye = commande.statutPaiement == 'paye';
    final libellePaiement = paye
        ? 'Payé'
        : commande.statutPaiement == 'rembourse'
            ? 'Remboursé'
            : 'En attente';
    final interlocuteur = commande.vendeurNom;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            // Photo du premier article, statut en haut à droite.
            if (aUneImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      memCacheWidth: 800,
                      imageUrl: imageOptimisee(premiereImage!, largeur: 800),
                      height: 160,
                      width: double.infinity,
                      // Photo entière, centrée sur fond blanc : pas de zoom.
                      fit: BoxFit.contain,
                      color: AppColor.kWhite,
                      colorBlendMode: BlendMode.dstOver,
                      placeholder: (_, __) => Container(
                        height: 160,
                        color: AppColor.kBackground,
                        child: const Center(
                          child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 160,
                        color: AppColor.kBackground,
                        child: const Icon(Icons.image_not_supported, color: AppColor.kGrayscale40, size: 32),
                      ),
                    ),
                    Positioned(top: 12, right: 12, child: _BadgeStatut(commande.statut)),
                    if (nbArticles > 1)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColor.kGrayscaleDark100.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${nbArticles - 1}',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.kWhite),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Référence, date (et boutique) — nombre d'articles.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${commande.referenceCommande}',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                _date(commande.createdAt),
                                if (interlocuteur != null && interlocuteur.isNotEmpty) interlocuteur,
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!aUneImage)
                        _BadgeStatut(commande.statut)
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColor.kBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$nbArticles article${nbArticles > 1 ? 's' : ''}',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.kGrayscale40),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
                      Text(
                        _montant(commande.montantTotal),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.kPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Paiement', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: paye ? AppColor.kSuccesLight : AppColor.kSecondaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          libellePaiement,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: paye ? AppColor.kSucces : AppColor.kSecondaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
