import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:saambiz/core/utils/image_url.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../injection_container.dart';
import '../../../commande/data/models/panier_item.dart';
import '../../../commande/data/services/panier_service.dart';
import '../../../commande/presentation/pages/panier_page.dart';
import '../../data/favoris_produits.dart';
import '../../data/produit_catalogue.dart';
import '../pages/produit_detail_page.dart';
import 'compte_a_rebours.dart';

/// Prix en francs avec séparateur de milliers : « 83 297 FCFA ».
final _francs = NumberFormat.decimalPattern('fr_FR');
String formaterPrix(double montant) => '${_francs.format(montant.round())} FCFA';

/// Rapport largeur/hauteur d'une [ProduitCard] (grille et carrousels).
const double ratioCarteProduit = 0.62;

/// Grille de produits adaptée à la largeur de l'écran.
SliverGridDelegate grilleProduits(BuildContext context) {
  final largeur = MediaQuery.sizeOf(context).width;
  final colonnes = largeur >= 900 ? 4 : largeur >= 600 ? 3 : 2;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: colonnes,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: ratioCarteProduit,
  );
}

/// Pastille « -11% » : orange sur fond pêche.
class PastilleReduction extends StatelessWidget {
  final int pourcentage;
  final double taille;
  const PastilleReduction({super.key, required this.pourcentage, this.taille = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: taille * 0.6, vertical: taille * 0.3),
      decoration: BoxDecoration(color: kPromoFond, borderRadius: BorderRadius.circular(taille * 0.5)),
      child: Text(
        '-$pourcentage%',
        style: GoogleFonts.plusJakartaSans(fontSize: taille, fontWeight: FontWeight.w700, color: kPromoEncre),
      ),
    );
  }
}

/// Mention « Rupture de stock », identique partout.
class BadgeRupture extends StatelessWidget {
  final bool compact;
  const BadgeRupture({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(color: AppColor.kErreur, borderRadius: BorderRadius.circular(20)),
      child: Text(
        'Rupture de stock',
        style: GoogleFonts.plusJakartaSans(
          fontSize: compact ? 9 : 11.5,
          fontWeight: FontWeight.w700,
          color: AppColor.kWhite,
        ),
      ),
    );
  }
}

/// Carte produit : visuel, nom, prix (et prix barré), bouton panier rond.
/// Un produit en promotion affiche sa remise et un compte à rebours.
class ProduitCard extends StatelessWidget {
  final ProduitCatalogue produit;
  const ProduitCard({super.key, required this.produit});

  @override
  Widget build(BuildContext context) {
    final p = produit;
    return GestureDetector(
      onTap: () => ouvrirFicheProduit(context, p),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.kLine.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(color: AppColor.kPrimary.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                child: ClipRRect(borderRadius: BorderRadius.circular(12), child: _visuel()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    // Deux lignes réservées : les cartes d'une rangée gardent
                    // la même hauteur, nom court ou long.
                    height: 32,
                    child: Text(
                      p.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColor.kGrayscaleDark100,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (p.boutique != null)
                    Text(
                      p.boutique!.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColor.kGrayscale30),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 14,
                              child: p.prixBarre == null
                                  ? null
                                  : Text(
                                      formaterPrix(p.prixBarre!),
                                      maxLines: 1,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        color: AppColor.kGrayscale30,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formaterPrix(p.prixPaye),
                                maxLines: 1,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.kPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      _boutonPanier(context),
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

  Widget _visuel() {
    final p = produit;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: AppColor.kSurface),
        if (p.image.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(4),
            child: CachedNetworkImage(
              memCacheWidth: 500,
              imageUrl: imageOptimisee(p.image, largeur: 400),
              fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox.expand(),
              errorWidget: (_, __, ___) =>
                  const Center(child: Icon(Icons.image_outlined, color: AppColor.kGrayscale30)),
            ),
          )
        else
          const Center(child: Icon(Icons.image_outlined, color: AppColor.kGrayscale30, size: 30)),
        if (p.remise > 0)
          Positioned(top: 6, right: 6, child: PastilleReduction(pourcentage: p.remise)),
        if (p.remise == 0 && p.nouveau)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: AppColor.kSecondary, borderRadius: BorderRadius.circular(20)),
              child: Text(
                'NOUVEAU',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        // Promotion à durée limitée : le temps qu'il reste, sur la carte.
        if (p.finPromotion != null && p.prixBarre != null)
          Positioned(left: 6, bottom: 6, child: CompteARebours(fin: p.finPromotion!, compact: true)),
        if (!p.disponible)
          Container(
            color: Colors.white.withValues(alpha: 0.72),
            alignment: Alignment.center,
            child: Text(
              'Indisponible',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.kGrayscale40),
            ),
          ),
        if (p.disponible && p.enRupture) ...[
          Container(color: Colors.white.withValues(alpha: 0.35)),
          const Positioned(left: 6, bottom: 8, child: BadgeRupture(compact: true)),
        ],
        Positioned(right: 6, bottom: 6, child: BoutonFavoriProduit(produit: p)),
      ],
    );
  }

  /// Bouton panier rond. Un produit à options (taille, parfum…) ouvre sa
  /// fiche : on ne peut pas choisir une taille depuis une grille.
  Widget _boutonPanier(BuildContext context) {
    final actif = produit.disponible && !produit.enRupture;
    return Material(
      color: actif ? AppColor.kSucces : AppColor.kLine,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: !actif
            ? null
            : produit.aDesOptions
                ? () => ouvrirFicheProduit(context, produit)
                : () => ajouterAuPanier(context, produit),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            produit.aDesOptions ? Icons.tune_rounded : Icons.add_shopping_cart_rounded,
            size: 18,
            color: actif ? AppColor.kWhite : AppColor.kGrayscale30,
          ),
        ),
      ),
    );
  }
}

/// Cœur des cartes produits : ajoute ou retire le produit des favoris.
class BoutonFavoriProduit extends StatelessWidget {
  final ProduitCatalogue produit;
  final double taille;
  const BoutonFavoriProduit({super.key, required this.produit, this.taille = 34});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: FavorisProduits.liste,
      builder: (context, _, __) {
        final aime = FavorisProduits.contient(produit.id);
        return Material(
          color: AppColor.kWhite,
          shape: const CircleBorder(),
          elevation: 3,
          shadowColor: AppColor.kPrimary.withValues(alpha: 0.25),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              final ajoute = await FavorisProduits.basculer(produit);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(SnackBar(
                  content: Text(ajoute ? 'Ajouté à vos favoris' : 'Retiré de vos favoris'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ));
            },
            child: SizedBox(
              width: taille,
              height: taille,
              child: Icon(
                aime ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: taille * 0.55,
                color: aime ? const Color(0xFFE53935) : AppColor.kGrayscale40,
                semanticLabel: aime ? 'Retirer des favoris' : 'Ajouter aux favoris',
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Ouvre la fiche détaillée d'un produit.
void ouvrirFicheProduit(BuildContext context, ProduitCatalogue p) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProduitDetailPage(produit: p)));
}

/// Ajoute [p] au panier (avec les [options] choisies) et propose d'aller le
/// voir. Le panier ne contient qu'une boutique à la fois : si le client
/// change de boutique, on lui propose de vider l'ancien panier.
Future<bool> ajouterAuPanier(
  BuildContext context,
  ProduitCatalogue p, {
  int quantite = 1,
  Map<String, String> options = const {},
}) async {
  final panier = sl<PanierService>();
  final item = PanierItem(
    produitId: p.id,
    nom: p.nom,
    prix: p.prixPaye,
    image: p.image,
    vendeurId: p.vendeurId,
    vendeurNom: p.boutique?.nom ?? '',
    options: options,
    quantite: quantite,
  );
  try {
    await panier.ajouter(item);
  } on PanierVendeurDifferentException {
    if (!context.mounted) return false;
    final vider = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Une boutique à la fois',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text(
          'Votre panier contient des articles d\'une autre boutique. '
          'Voulez-vous le vider pour ajouter celui-ci ?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.kPrimary,
              foregroundColor: AppColor.kWhite,
              elevation: 0,
            ),
            child: const Text('Vider et ajouter'),
          ),
        ],
      ),
    );
    if (vider != true) return false;
    await panier.vider();
    await panier.ajouter(item);
  }
  if (!context.mounted) return true;

  const duree = Duration(seconds: 3);
  final messager = ScaffoldMessenger.of(context)..clearSnackBars();
  final bandeau = messager.showSnackBar(SnackBar(
    content: Text('Ajouté au panier',
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
    backgroundColor: AppColor.kPrimary,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    duration: duree,
    action: SnackBarAction(
      label: 'Voir le panier',
      textColor: AppColor.kSecondary,
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PanierPage())),
    ),
  ));
  // Fermeture explicite : avec une action, Flutter ne ferme pas toujours le
  // bandeau quand l'accessibilité est active.
  Timer(duree, () {
    try {
      bandeau.close();
    } catch (_) {}
  });
  return true;
}
