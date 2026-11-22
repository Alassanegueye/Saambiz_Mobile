import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import 'image_reseau.dart';

/// Rapport largeur/hauteur imposé à TOUTE photo de produit : le carré.
///
/// C'est aussi le rapport demandé au vendeur au moment du recadrage (voir
/// `rognerPhotoProduit`), si bien que la photo enregistrée remplit exactement
/// le cadre : [BoxFit.cover] ne rogne plus rien.
const double kRatioImageProduit = 1;

/// Cadrage unique : la photo remplit son cadre.
///
/// `contain` laissait des bandes vides autour des photos verticales et
/// `cover` sur une photo non recadrée coupait le produit — les deux
/// cohabitaient selon l'écran. Le recadrage en amont supprime le dilemme.
const BoxFit kFitImageProduit = BoxFit.cover;

/// Arrondi des coins, identique partout.
const double kRayonImageProduit = 12;

/// Fond visible pendant le chargement et derrière une photo transparente.
const Color kFondImageProduit = AppColor.kBackground2;

/// Photo d'un produit, partout dans l'application.
///
/// Un même produit se présentait différemment selon l'écran : vignette carrée
/// écrasée dans « Mes produits », photo flottante et centrée dans la vitrine,
/// bandeau débordant dans le formulaire. Chaque écran redéfinissait son
/// cadrage, et les trois divergeaient.
///
/// Tout passe désormais par ici : un seul endroit décide du rapport
/// ([kRatioImageProduit]), du cadrage ([kFitImageProduit]), des coins arrondis
/// et de l'image de remplacement. C'est ce point de passage unique — et non la
/// discipline de chaque écran — qui garantit que ça ne redivergera pas.
class ImageProduit extends StatelessWidget {
  /// Adresse de la photo enregistrée. Vide ou nulle : le repli s'affiche,
  /// sauf si [fichier] est renseigné.
  final String? url;

  /// Photo choisie sur le téléphone mais pas encore envoyée (formulaire
  /// d'ajout / de modification). Prioritaire sur [url] : le vendeur doit voir
  /// la photo qu'il vient de choisir, pas l'ancienne.
  final String? fichier;

  /// Vignette de taille fixe, en points. Sans valeur, la photo prend toute la
  /// largeur disponible et sa hauteur en découle ([kRatioImageProduit]).
  final double? cote;

  /// Coins arrondis. Par défaut [kRayonImageProduit] ; `BorderRadius.zero`
  /// pour une photo pleine largeur déjà découpée par son parent.
  final BorderRadius? rayon;

  /// Largeur demandée au serveur d'images, en pixels. À régler sur la place
  /// réellement occupée : une vignette de 54 points n'a pas besoin de 1080 px.
  final int largeurServeur;

  /// Badges posés sur la photo (remise, statut, favori…), en `Positioned`.
  /// Ils sont découpés avec elle, donc jamais à cheval sur l'arrondi.
  final List<Widget> superpositions;

  /// Remplace l'icône par défaut quand il n'y a pas de photo.
  final Widget? repli;

  const ImageProduit(
    this.url, {
    super.key,
    this.fichier,
    this.cote,
    this.rayon,
    this.largeurServeur = 600,
    this.superpositions = const <Widget>[],
    this.repli,
  });

  @override
  Widget build(BuildContext context) {
    final chemin = fichier?.trim() ?? '';
    final adresse = url?.trim() ?? '';
    final Widget replii = repli ?? const _RepliProduit();

    Widget photo;
    if (chemin.isNotEmpty) {
      photo = Image.file(
        File(chemin),
        fit: kFitImageProduit,
        errorBuilder: (_, __, ___) => replii,
      );
    } else if (adresse.isNotEmpty) {
      photo = ImageReseau(
        adresse,
        fit: kFitImageProduit,
        fond: kFondImageProduit,
        largeurServeur: largeurServeur,
        repli: replii,
      );
    } else {
      photo = replii;
    }

    Widget cadre = ColoredBox(
      color: kFondImageProduit,
      child: superpositions.isEmpty
          ? photo
          : Stack(fit: StackFit.expand, children: [photo, ...superpositions]),
    );

    // Taille fixe ou rapport imposé : dans les deux cas le cadre est carré.
    cadre = cote != null
        ? SizedBox(width: cote, height: cote, child: cadre)
        : AspectRatio(aspectRatio: kRatioImageProduit, child: cadre);

    return ClipRRect(
      borderRadius: rayon ?? BorderRadius.circular(kRayonImageProduit),
      child: cadre,
    );
  }
}

/// Image de remplacement : la même icône discrète partout, plutôt qu'un carré
/// vide qui ressemble à un chargement qui n'aboutit pas.
class _RepliProduit extends StatelessWidget {
  const _RepliProduit();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cote = c.biggest.shortestSide;
        final taille = cote.isFinite ? (cote * 0.34).clamp(16.0, 44.0) : 28.0;
        return ColoredBox(
          color: kFondImageProduit,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: taille,
              color: AppColor.kGrayscale30,
            ),
          ),
        );
      },
    );
  }
}
