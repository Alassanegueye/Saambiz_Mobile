import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/utils/image_url.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/texte.dart';
import '../../data/models/commande_model.dart';

/// Couleur d’un statut de commande, selon la charte SaamBiz :
/// or foncé quand une action est attendue, bleu pour une étape en
/// cours, vert pour la livraison, rouge pour une annulation.
Color couleurStatutCommande(String statut) {
  switch (statut) {
    case 'livree':
      return AppColor.kSucces;
    case 'annulee':
    case 'rejetee':
      return AppColor.kErreur;
    case 'payee':
      return AppColor.kSucces;
    case 'prete':
    case 'en_livraison':
      return AppColor.kPrimary;
    case 'acceptee':
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
    case 'rejetee':
      return Icons.cancel_rounded;
    case 'acceptee':
    case 'payee':
      return Icons.check_circle_outline_rounded;
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
  if (d == null) return 'Date inconnue';
  const mois = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  final l = d.toLocal();
  return '${l.day} ${mois[l.month - 1]} ${l.year}';
}

/// « 15 000 FCFA ».
String montantFcfa(double v) {
  final s = v.toStringAsFixed(0);
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b FCFA';
}

/// Statut : pastille claire, texte de la couleur du statut.
class _BadgeStatut extends StatelessWidget {
  final String statut;
  const _BadgeStatut(this.statut);

  @override
  Widget build(BuildContext context) {
    final couleur = couleurStatutCommande(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        kStatutCommandeLabels[statut] ?? statut,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: couleur,
        ),
      ),
    );
  }
}

/// Carte d'une commande : qui, quand, combien, où elle en est.
/// Côté vendeur, elle présente le client ; côté client, le premier article.
class CommandeCard extends StatelessWidget {
  final CommandeModel commande;
  final VoidCallback onTap;
  final bool isVendeur;
  const CommandeCard({
    super.key,
    required this.commande,
    required this.onTap,
    this.isVendeur = false,
  });

  @override
  Widget build(BuildContext context) {
    final nbArticles = commande.lignes.fold<int>(0, (s, l) => s + l.quantite);
    final image = commande.lignes.isNotEmpty
        ? commande.lignes.first.imageProduit
        : null;
    final premier = commande.lignes.isNotEmpty
        ? commande.lignes.first.nomProduit
        : 'Commande';
    final nomClient = (commande.acheteurNom ?? '').trim();
    final titre = isVendeur
        ? (nomClient.isEmpty ? 'Client' : nomClient)
        : (nbArticles > 1 ? '$premier +${nbArticles - 1}' : premier);
    final paye = commande.statutPaiement == 'paye';

    return Material(
      color: AppColor.kWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColor.kLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (isVendeur)
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColor.kPrimaryLight,
                  child: Text(
                    nomClient.isEmpty ? '?' : initialesDe(nomClient),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColor.kPrimary,
                    ),
                  ),
                )
              else
                _Vignette(image: image),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColor.kGrayscaleDark100,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _BadgeStatut(commande.statut),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        _date(commande.createdAt),
                        // Le client reconnaît sa boutique ; le vendeur, le numéro.
                        if (isVendeur)
                          '#${commande.referenceCommande}'
                        else if ((commande.vendeurNom ?? '').isNotEmpty)
                          commande.vendeurNom!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            montantFcfa(commande.montantTotal),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColor.kPrimary,
                            ),
                          ),
                        ),
                        if (paye) ...[
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: AppColor.kSucces,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Payé',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColor.kSucces,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vignette extends StatelessWidget {
  final String? image;
  const _Vignette({this.image});

  @override
  Widget build(BuildContext context) {
    const defaut = ColoredBox(
      color: AppColor.kPrimaryLight,
      child: Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 22,
          color: AppColor.kPrimary,
        ),
      ),
    );
    final img = image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: img != null && img.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageOptimisee(img, largeur: 160),
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => defaut,
              )
            : defaut,
      ),
    );
  }
}
