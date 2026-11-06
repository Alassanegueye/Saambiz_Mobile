import 'dart:async';
import 'package:saambiz/core/widgets/image_reseau.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/animations.dart';
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

/// Montant avec espace insécable classique entre les milliers : l'espace
/// fine du format français disparaissait presque à l'écran (« 29900 »).
String formaterMontant(double montant) =>
    _francs.format(montant.round()).replaceAll('\u202F', '\u00A0');

String formaterPrix(double montant) => '${formaterMontant(montant)} FCFA';

/// Rapport largeur/hauteur d'une [ProduitCard] (grille et carrousels) :
/// la photo à peu près carrée, puis trois lignes de texte.
const double ratioCarteProduit = 0.64;

/// Grille de produits adaptée à la largeur de l'écran.
SliverGridDelegate grilleProduits(BuildContext context) {
  final largeur = MediaQuery.sizeOf(context).width;
  final colonnes = largeur >= 900
      ? 4
      : largeur >= 600
      ? 3
      : 2;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: colonnes,
    crossAxisSpacing: 12,
    mainAxisSpacing: 18,
    childAspectRatio: ratioCarteProduit,
  );
}

/// Montant suivi de « FCFA » en plus petit : le chiffre se lit d'abord.
class PrixTexte extends StatelessWidget {
  final double montant;
  final double taille;
  final Color couleur;
  const PrixTexte(
    this.montant, {
    super.key,
    this.taille = 15,
    this.couleur = AppColor.kPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: formaterMontant(montant)),
          TextSpan(
            text: ' FCFA',
            style: TextStyle(
              fontSize: taille * 0.68,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: kPolice,
        fontSize: taille,
        fontWeight: FontWeight.w800,
        color: couleur,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Pastille « -11% » : marine sur or, les couleurs du logo.
class PastilleReduction extends StatelessWidget {
  final int pourcentage;
  final double taille;
  const PastilleReduction({
    super.key,
    required this.pourcentage,
    this.taille = 11.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: taille * 0.6,
        vertical: taille * 0.28,
      ),
      decoration: BoxDecoration(
        color: AppColor.kSecondary,
        borderRadius: BorderRadius.circular(taille * 0.6),
      ),
      child: Text(
        '-$pourcentage%',
        style: TextStyle(
          fontFamily: kPolice,
          fontSize: taille,
          fontWeight: FontWeight.w800,
          color: AppColor.kPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
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
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColor.kGrayscaleDark100.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Rupture de stock',
        style: TextStyle(
          fontFamily: kPolice,
          fontSize: compact ? 10 : 11.5,
          fontWeight: FontWeight.w700,
          color: AppColor.kWhite,
        ),
      ),
    );
  }
}

/// Carte produit : la photo porte la carte, sans cadre autour. Dessous, le
/// nom sur deux lignes et le prix ; le prix d'origine barré seulement s'il
/// y a une remise. Sur la photo : la remise (or), le cœur des favoris et,
/// pour une promotion limitée, le temps qui reste.
///
/// [surFond] : posée sur un fond coloré (bandeau des promotions), la carte
/// reçoit un fond blanc qui la détache.
class ProduitCard extends StatelessWidget {
  final ProduitCatalogue produit;
  final bool surFond;
  const ProduitCard({super.key, required this.produit, this.surFond = false});

  @override
  Widget build(BuildContext context) {
    final p = produit;
    final contenu = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _visuel()),
        const SizedBox(height: 8),
        // Deux lignes réservées : les prix d'une rangée restent alignés,
        // nom court ou long.
        SizedBox(
          height: 35,
          child: Text(
            p.nom,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 13,
              height: 1.32,
              fontWeight: FontWeight.w600,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
        ),
        const SizedBox(height: 3),
        PrixTexte(p.prixPaye),
        SizedBox(
          height: 16,
          child: p.prixBarre == null
              ? null
              : Text(
                  formaterPrix(p.prixBarre!),
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 11.5,
                    color: AppColor.kGrayscale30,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColor.kGrayscale30,
                  ),
                ),
        ),
      ],
    );

    return Pressable(
      echelle: 0.97,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ouvrirFicheProduit(context, p),
        child: surFond
            ? Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                decoration: BoxDecoration(
                  color: AppColor.kWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: contenu,
              )
            : contenu,
      ),
    );
  }

  Widget _visuel() {
    final p = produit;
    return ClipRRect(
      borderRadius: BorderRadius.circular(surFond ? 12 : 14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageReseau(
            p.image,
            largeurServeur: 480,
            fit: BoxFit.cover,
            fond: AppColor.kBackground,
            repli: const Center(
              child: Icon(
                Icons.image_outlined,
                color: AppColor.kGrayscale30,
                size: 30,
              ),
            ),
          ),
          if (p.remise > 0)
            Positioned(
              top: 8,
              left: 8,
              child: PastilleReduction(pourcentage: p.remise),
            ),
          if (p.remise == 0 && p.nouveau)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColor.kWhite,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'Nouveau',
                  style: TextStyle(
                    fontFamily: kPolice,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kPrimary,
                  ),
                ),
              ),
            ),
          // Promotion à durée limitée : le temps qu'il reste, sur la photo.
          if (p.finPromotion != null && p.prixBarre != null)
            Positioned(
              left: 8,
              bottom: 8,
              child: CompteARebours(fin: p.finPromotion!, compact: true),
            ),
          if (!p.disponible)
            Container(
              color: Colors.white.withValues(alpha: 0.72),
              alignment: Alignment.center,
              child: const Text(
                'Indisponible',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ),
          if (p.disponible && p.enRupture) ...[
            Container(color: Colors.white.withValues(alpha: 0.4)),
            const Positioned(
              left: 8,
              bottom: 8,
              child: BadgeRupture(compact: true),
            ),
          ],
          Positioned(
            right: 6,
            top: 6,
            child: BoutonFavoriProduit(produit: p, taille: 32),
          ),
        ],
      ),
    );
  }
}

/// Cœur des cartes produits : ajoute ou retire le produit des favoris.
class BoutonFavoriProduit extends StatelessWidget {
  final ProduitCatalogue produit;
  final double taille;
  const BoutonFavoriProduit({
    super.key,
    required this.produit,
    this.taille = 34,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: FavorisProduits.liste,
      builder: (context, _, __) {
        final aime = FavorisProduits.contient(produit.id);
        return Material(
          color: AppColor.kWhite.withValues(alpha: 0.94),
          shape: const CircleBorder(),
          elevation: 1.5,
          shadowColor: AppColor.kPrimary.withValues(alpha: 0.2),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              HapticFeedback.lightImpact();
              final ajoute = await FavorisProduits.basculer(produit);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      ajoute ? 'Ajouté à vos favoris' : 'Retiré de vos favoris',
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
            },
            child: SizedBox(
              width: taille,
              height: taille,
              child: AnimatedSwitcher(
                duration: Mouvement.normal,
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (enfant, anim) =>
                    ScaleTransition(scale: anim, child: enfant),
                child: Icon(
                  aime ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  key: ValueKey(aime),
                  size: taille * 0.52,
                  color: aime ? const Color(0xFFE5484D) : AppColor.kGrayscale60,
                  semanticLabel: aime
                      ? 'Retirer des favoris'
                      : 'Ajouter aux favoris',
                ),
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
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => ProduitDetailPage(produit: p)));
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
        title: Text(
          'Une boutique à la fois',
          style: TextStyle(fontFamily: kPolice, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'Votre panier contient des articles d\'une autre boutique. '
          'Voulez-vous le vider pour ajouter celui-ci ?',
          style: TextStyle(fontFamily: kPolice, fontSize: 14, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
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
  final bandeau = messager.showSnackBar(
    SnackBar(
      content: Text(
        'Ajouté au panier',
        style: TextStyle(fontFamily: kPolice, fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      backgroundColor: AppColor.kPrimary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: duree,
      action: SnackBarAction(
        label: 'Voir le panier',
        textColor: AppColor.kSecondary,
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PanierPage())),
      ),
    ),
  );
  // Fermeture explicite : avec une action, Flutter ne ferme pas toujours le
  // bandeau quand l'accessibilité est active.
  Timer(duree, () {
    try {
      bandeau.close();
    } catch (_) {}
  });
  return true;
}
