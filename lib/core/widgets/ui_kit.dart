import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimensions.dart';
import '../theme/police.dart';

/// Composants visuels communs (charte du design d'origine) : cartes
/// blanches aérées à l'ombre bleutée, titres de section courts, pastilles
/// d'icône bleu pâle, états vides soignés. L'information d'abord.

TextStyle titreSection([double taille = 15]) => TextStyle(
  fontFamily: kPolice,
  fontSize: taille,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.2,
  color: AppColor.kGrayscaleDark100,
);

TextStyle texteDiscret([double taille = 12]) => TextStyle(
  fontFamily: kPolice,
  fontSize: taille,
  height: 1.35,
  color: AppColor.kGrayscale40,
);

/// Carte blanche : coins arrondis, ombre bleutée très douce, sans contour.
BoxDecoration decorationCarte({
  double rayon = AppDim.rayonGrand,
  Color couleur = AppColor.kWhite,
}) => BoxDecoration(
  color: couleur,
  borderRadius: BorderRadius.circular(rayon),
  boxShadow: AppDim.ombreCarte,
);

/// Titre de section avec lien « Voir tout » facultatif.
class EnteteSection extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final String? action;
  final VoidCallback? onAction;

  /// Sur fond marine : titre blanc, lien or.
  final bool surFondSombre;

  const EnteteSection(
    this.titre, {
    super.key,
    this.sousTitre,
    this.action,
    this.onAction,
    this.surFondSombre = false,
  });

  @override
  Widget build(BuildContext context) {
    final couleurTitre = surFondSombre
        ? AppColor.kWhite
        : AppColor.kGrayscaleDark100;
    final couleurLien = surFondSombre ? AppColor.kSecondary : AppColor.kPrimary;
    // « Voir tout → » des anciennes pages : la flèche est dessinée à part.
    final libelle = action?.replaceAll('→', '').trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titreSection(17).copyWith(color: couleurTitre),
              ),
              if (sousTitre != null && sousTitre!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    sousTitre!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: texteDiscret(12.5).copyWith(
                      color: surFondSombre
                          ? AppColor.kWhite.withValues(alpha: 0.7)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (libelle != null && libelle.isNotEmpty && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 2, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    libelle,
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: couleurLien,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: couleurLien,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Pastille d'icône carrée bleu pâle (ou or pâle si [accent]).
class PastilleIcone extends StatelessWidget {
  final IconData icone;
  final bool accent;
  final double taille;
  const PastilleIcone(
    this.icone, {
    super.key,
    this.accent = false,
    this.taille = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: accent ? AppColor.kSecondaryLight : AppColor.kPrimaryLight,
        borderRadius: BorderRadius.circular(taille * 0.3),
      ),
      child: Icon(
        icone,
        size: taille * 0.52,
        color: accent ? AppColor.kSecondaryDark : AppColor.kPrimary,
      ),
    );
  }
}

/// État vide ou d'erreur : grande pastille, titre, texte, action facultative.
class EtatVide extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String? message;
  final String? action;
  final VoidCallback? onAction;
  final bool compact;

  const EtatVide({
    super.key,
    required this.icone,
    required this.titre,
    this.message,
    this.action,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cote = compact ? 52.0 : 68.0;
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: compact ? 12 : 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: cote,
              height: cote,
              decoration: BoxDecoration(
                color: AppColor.kPrimaryLight,
                borderRadius: BorderRadius.circular(cote * 0.32),
              ),
              child: Icon(icone, size: cote * 0.45, color: AppColor.kPrimary),
            ),
            const SizedBox(height: 14),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 13,
                    height: 1.45,
                    color: AppColor.kGrayscale40,
                  ),
                ),
              ),
            ],
            if (action != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                ),
                child: Text(action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Puce de filtre / tri : pilule blanche ; sélectionnée, fond marine.
class PuceFiltre extends StatelessWidget {
  final String libelle;
  final bool active;
  final VoidCallback onTap;
  final IconData? icone;
  const PuceFiltre({
    super.key,
    required this.libelle,
    required this.active,
    required this.onTap,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDim.rayonPastille),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColor.kPrimary : AppColor.kWhite,
            borderRadius: BorderRadius.circular(AppDim.rayonPastille),
            border: Border.all(
              color: active ? AppColor.kPrimary : AppColor.kGrayscale20,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icone != null) ...[
                Icon(
                  icone,
                  size: 16,
                  color: active ? AppColor.kSecondary : AppColor.kPrimary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                libelle,
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColor.kWhite : AppColor.kGrayscaleDark100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Champ de recherche : rectangle arrondi gris bleuté, loupe à gauche. Sur
/// un fond déjà gris ([surFondClair]), il passe en blanc avec un filet.
class ChampRecherche extends StatelessWidget {
  final TextEditingController? controleur;
  final String indication;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool lectureSeule;
  final bool autofocus;

  /// Fond gris de l'écran : champ blanc et filet.
  final bool surFondClair;

  const ChampRecherche({
    super.key,
    this.controleur,
    this.indication = 'Rechercher un produit, une boutique',
    this.onSubmitted,
    this.onChanged,
    this.onTap,
    this.lectureSeule = false,
    this.autofocus = false,
    this.surFondClair = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: surFondClair ? AppColor.kWhite : AppColor.kBackground,
        borderRadius: BorderRadius.circular(AppDim.rayonGrand),
        border: Border.all(
          color: surFondClair ? AppColor.kGrayscale20 : AppColor.kLine,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: AppColor.kPrimary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controleur,
              readOnly: lectureSeule,
              autofocus: autofocus,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: AppColor.kPrimary,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 14.5,
                color: AppColor.kGrayscaleDark100,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                hintText: indication,
                hintStyle: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 14.5,
                  color: AppColor.kGrayscale40,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
