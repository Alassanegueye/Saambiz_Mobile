import 'package:flutter/material.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/core/theme/police.dart';

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
      return const Color(
        0xFFE65100,
      ); // Orange chaud vif comme TRANSIT sur la maquette
    case 'acceptee':
    case 'confirmee':
    case 'en_preparation':
      return const Color(
        0xFF263238,
      ); // Anthracite PROCESS comme sur la maquette
    case 'en_attente':
      return AppColor.kSecondaryDark;
    default:
      return AppColor.kGrayscale40;
  }
}

String libelleRubanStatut(String statut) {
  switch (statut) {
    case 'livree':
      return 'LIVRÉE';
    case 'annulee':
    case 'rejetee':
      return 'ANNULÉE';
    case 'prete':
    case 'en_livraison':
      return 'TRANSIT';
    case 'acceptee':
    case 'confirmee':
    case 'en_preparation':
      return 'PROCESS';
    case 'en_attente':
      return 'ATTENTE';
    default:
      return (kStatutCommandeLabels[statut] ?? statut).toUpperCase();
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

/// Ruban d'angle diagonal en haut à droite comme sur la maquette de référence.
class _RubanCoinStatut extends StatelessWidget {
  final String label;
  final Color couleur;

  const _RubanCoinStatut({required this.label, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 14,
      right: -32,
      child: Transform.rotate(
        angle: 0.785398, // 45 degrés
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 3.5),
          decoration: BoxDecoration(
            color: couleur,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte d'une commande selon la maquette de référence (My Shipping) :
/// ruban diagonal de statut, vignette produit réelle (pas d'illustration carton),
/// identifiant, suivi d'expédition avec ligne pointillée et camion,
/// et adresses De / À.
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

    final statutCouleur = couleurStatutCommande(commande.statut);
    final statutRuban = libelleRubanStatut(commande.statut);

    // Détermination de l'étape de livraison pour la ligne temporelle
    final estLivree = commande.statut == 'livree';
    final estEnLivraison =
        commande.statut == 'en_livraison' || commande.statut == 'prete';
    final estEnPreparation =
        commande.statut == 'en_preparation' ||
        commande.statut == 'confirmee' ||
        commande.statut == 'acceptee';

    String libelleEtape;
    if (estLivree) {
      libelleEtape = 'Colis livré avec succès';
    } else if (estEnLivraison) {
      libelleEtape = 'En cours d’acheminement';
    } else if (estEnPreparation) {
      libelleEtape = 'En préparation chez le vendeur';
    } else if (commande.statut == 'annulee' || commande.statut == 'rejetee') {
      libelleEtape = 'Commande annulée';
    } else {
      libelleEtape = 'En attente de confirmation';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: AppColor.kWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColor.kLine, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Ruban diagonal de statut en haut à droite — côté client
              // seulement : dans les commandes reçues, le vendeur lit déjà
              // l'étape sous l'en-tête, le ruban faisait doublon.
              if (!isVendeur)
                _RubanCoinStatut(label: statutRuban, couleur: statutCouleur),
              // Contenu principal
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne supérieure : Image produit réelle + ID + Nom du produit
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isVendeur)
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColor.kPrimaryLight,
                            child: Text(
                              nomClient.isEmpty ? '?' : initialesDe(nomClient),
                              style: const TextStyle(
                                fontFamily: kPolice,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColor.kPrimary,
                              ),
                            ),
                          )
                        else
                          _VignetteProduit(image: image),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            // Espace pour le ruban, quand il est affiché.
                            padding: EdgeInsets.only(right: isVendeur ? 0 : 48),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ID: #${commande.referenceCommande}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: kPolice,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.kGrayscaleDark100,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  titre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: kPolice,
                                    fontSize: 12.5,
                                    color: AppColor.kGrayscale40,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Ligne de suivi avec camion et timeline à points (Image 2)
                    Center(
                      child: Column(
                        children: [
                          Text(
                            libelleEtape,
                            style: TextStyle(
                              fontFamily: kPolice,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: statutCouleur,
                            ),
                          ),
                          const SizedBox(height: 7),
                          _LigneSuiviColis(
                            estEnPreparation: estEnPreparation,
                            estEnLivraison: estEnLivraison,
                            estLivree: estLivree,
                            couleur: statutCouleur,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColor.kLine),
                    const SizedBox(height: 10),

                    // Ligne inférieure : DE (Vendeur) / À (Destination) et Prix
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Origine
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DE',
                                style: TextStyle(
                                  fontFamily: kPolice,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.kGrayscale40,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                commande.vendeurNom?.isNotEmpty == true
                                    ? commande.vendeurNom!
                                    : 'Boutique SaamBiz',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: kPolice,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.kGrayscaleDark100,
                                ),
                              ),
                              Text(
                                _date(commande.createdAt),
                                style: const TextStyle(
                                  fontFamily: kPolice,
                                  fontSize: 11,
                                  color: AppColor.kGrayscale40,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Destination et Prix
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'À',
                                style: TextStyle(
                                  fontFamily: kPolice,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.kGrayscale40,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (commande.adresseLivraison?.isNotEmpty == true)
                                    ? commande.adresseLivraison!
                                    : (commande.acheteurNom?.isNotEmpty == true
                                          ? commande.acheteurNom!
                                          : 'Dakar, Sénégal'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: kPolice,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.kGrayscaleDark100,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    montantFcfa(commande.montantTotal),
                                    style: const TextStyle(
                                      fontFamily: kPolice,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColor.kPrimary,
                                    ),
                                  ),
                                  if (paye) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 13,
                                      color: AppColor.kSucces,
                                    ),
                                  ],
                                ],
                              ),
                            ],
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
      ),
    );
  }
}

/// Ligne de suivi graphique avec départ, camion et arrivée (comme sur l'image).
class _LigneSuiviColis extends StatelessWidget {
  final bool estEnPreparation;
  final bool estEnLivraison;
  final bool estLivree;
  final Color couleur;

  const _LigneSuiviColis({
    required this.estEnPreparation,
    required this.estEnLivraison,
    required this.estLivree,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    const actif1 = true;
    final actif2 = estEnLivraison || estLivree;
    final actif3 = estLivree;

    return Row(
      children: [
        // Étape 1 : Préparé
        _PastilleEtape(
          active: actif1,
          couleur: couleur,
          icone: Icons.check_rounded,
        ),
        // Ligne pointillée 1
        Expanded(
          child: _SeparateurPoints(actif: actif2, couleur: couleur),
        ),
        // Étape 2 : Camion
        _PastilleCamion(active: actif2, couleur: couleur),
        // Ligne pointillée 2
        Expanded(
          child: _SeparateurPoints(actif: actif3, couleur: couleur),
        ),
        // Étape 3 : Arrivée
        _PastilleEtape(
          active: actif3,
          couleur: couleur,
          icone: actif3
              ? Icons.check_rounded
              : Icons.radio_button_unchecked_rounded,
        ),
      ],
    );
  }
}

class _PastilleEtape extends StatelessWidget {
  final bool active;
  final Color couleur;
  final IconData icone;

  const _PastilleEtape({
    required this.active,
    required this.couleur,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: active ? couleur : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? couleur : AppColor.kLine,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          icone,
          size: 13,
          color: active ? Colors.white : AppColor.kGrayscale40,
        ),
      ),
    );
  }
}

class _PastilleCamion extends StatelessWidget {
  final bool active;
  final Color couleur;

  const _PastilleCamion({required this.active, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: active ? couleur : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? couleur : AppColor.kLine,
          width: 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: couleur.withValues(alpha: 0.28),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.local_shipping_rounded,
        size: 14,
        color: active ? Colors.white : AppColor.kGrayscale40,
      ),
    );
  }
}

class _SeparateurPoints extends StatelessWidget {
  final bool actif;
  final Color couleur;

  const _SeparateurPoints({required this.actif, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 7).floor().clamp(2, 12);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            count,
            (i) => Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: actif ? couleur : AppColor.kLine,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Vignette affichant la photo réelle du produit (pas de boîte carton 3D).
class _VignetteProduit extends StatelessWidget {
  final String? image;
  const _VignetteProduit({this.image});

  @override
  Widget build(BuildContext context) {
    const defaut = ColoredBox(
      color: AppColor.kPrimaryLight,
      child: Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 24,
          color: AppColor.kPrimary,
        ),
      ),
    );
    final img = image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 54,
        height: 54,
        color: AppColor.kPrimaryLight,
        child: img != null && img.isNotEmpty
            ? ImageReseau(
                img,
                largeurServeur: 160,
                fit: BoxFit.cover,
                repli: defaut,
              )
            : defaut,
      ),
    );
  }
}
