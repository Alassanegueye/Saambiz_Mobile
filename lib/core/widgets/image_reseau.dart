import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../utils/image_url.dart';

/// Image distante (photos de produits, logos, avatars).
///
/// Un seul endroit pour ce que chaque écran réglait à sa façon :
/// - le cache disque (une photo vue n'est plus retéléchargée) ;
/// - la version réduite demandée à Cloudinary ([imageOptimisee]) ;
/// - la taille de décodage, calée sur la place réellement occupée à l'écran
///   (une photo de 1080 px décodée pour une vignette de 52 px coûtait
///   inutilement de la mémoire et faisait saccader les listes) ;
/// - le fond d'attente, le fondu d'apparition et l'image de repli.
class ImageReseau extends StatelessWidget {
  /// Adresse de l'image ; vide ou nulle : [repli] est affiché.
  final String? url;
  final BoxFit fit;
  final Alignment alignment;

  /// Affiché sans adresse ou si le chargement échoue. Par défaut, une
  /// icône d'image discrète sur le fond d'attente.
  final Widget? repli;

  /// Fond visible pendant le chargement (et derrière les images
  /// transparentes).
  final Color fond;

  /// Coins arrondis : l'image est découpée.
  final BorderRadius? rayon;

  final double? width;
  final double? height;

  /// Largeur demandée au serveur d'images, en pixels.
  final int largeurServeur;

  const ImageReseau(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.repli,
    this.fond = AppColor.kBackground2,
    this.rayon,
    this.width,
    this.height,
    this.largeurServeur = 1080,
  });

  /// Aperçus et tests : remplace le téléchargement par une image locale.
  /// Jamais renseigné dans l'application.
  @visibleForTesting
  static ImageProvider Function(String url)? substitut;

  @override
  Widget build(BuildContext context) {
    final adresse = url?.trim() ?? '';
    final Widget repliEffectif = repli ?? const _RepliImage();

    Widget contenu;
    if (adresse.isEmpty) {
      contenu = repliEffectif;
    } else {
      contenu = LayoutBuilder(
        builder: (context, contraintes) {
          // Décodage à la taille affichée (densité de l'écran comprise).
          final dpr = MediaQuery.devicePixelRatioOf(context);
          // Le plus grand côté : avec BoxFit.cover, une photo en largeur
          // dans un cadre carré s'affiche plus large que le cadre.
          final w = contraintes.hasBoundedWidth
              ? contraintes.maxWidth
              : (width ?? 0);
          final h = contraintes.hasBoundedHeight
              ? contraintes.maxHeight
              : (height ?? 0);
          final cote = w > h ? w : h;
          final largeurDecodage = cote > 0 ? (cote * dpr).round() : null;
          return Image(
            image: fournisseurImageReseau(
              adresse,
              largeurServeur: largeurServeur,
              largeurDecodage: largeurDecodage,
            ),
            fit: fit,
            alignment: alignment,
            width: width,
            height: height,
            gaplessPlayback: true,
            frameBuilder: (context, enfant, image, synchrone) {
              if (synchrone) return enfant;
              return AnimatedOpacity(
                opacity: image == null ? 0 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: enfant,
              );
            },
            errorBuilder: (_, __, ___) => repliEffectif,
          );
        },
      );
    }

    Widget resultat = ColoredBox(color: fond, child: contenu);
    if (width != null || height != null) {
      resultat = SizedBox(width: width, height: height, child: resultat);
    }
    if (rayon != null) {
      resultat = ClipRRect(borderRadius: rayon!, child: resultat);
    }
    return resultat;
  }
}

/// Fournisseur d'une image distante, pour les endroits qui demandent un
/// `ImageProvider` (avatar rond, image de fond d'une décoration).
ImageProvider fournisseurImageReseau(
  String url, {
  int largeurServeur = 1080,
  int? largeurDecodage,
}) {
  final substitut = ImageReseau.substitut;
  final ImageProvider source = substitut != null
      ? substitut(url)
      : CachedNetworkImageProvider(
          imageOptimisee(url, largeur: largeurServeur),
        );
  if (largeurDecodage == null || largeurDecodage <= 0) return source;
  return ResizeImage(source, width: largeurDecodage, allowUpscaling: false);
}

class _RepliImage extends StatelessWidget {
  const _RepliImage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cote = c.biggest.shortestSide;
        final taille = cote.isFinite ? (cote * 0.32).clamp(16.0, 40.0) : 28.0;
        return Center(
          child: Icon(
            Icons.image_outlined,
            size: taille,
            color: AppColor.kGrayscale30,
          ),
        );
      },
    );
  }
}
