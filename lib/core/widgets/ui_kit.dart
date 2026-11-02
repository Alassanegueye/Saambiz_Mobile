import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_color.dart';

/// Composants visuels communs de l'espace client : cartes blanches à
/// filet fin, titres de section sobres, puces de filtre et champ de
/// recherche. Pas d'ornement : l'information d'abord.

TextStyle titreSection([double taille = 15]) => GoogleFonts.inter(
  fontSize: taille,
  fontWeight: FontWeight.w700,
  color: AppColor.kGrayscaleDark100,
);

TextStyle texteDiscret([double taille = 12]) =>
    GoogleFonts.inter(fontSize: taille, color: AppColor.kGrayscale40);

/// Carte blanche : coins arrondis, filet fin, sans ombre.
BoxDecoration decorationCarte({
  double rayon = 12,
  Color couleur = AppColor.kWhite,
}) => BoxDecoration(
  color: couleur,
  borderRadius: BorderRadius.circular(rayon),
  border: Border.all(color: AppColor.kLine),
);

/// Titre de section avec lien « Voir tout » facultatif.
class EnteteSection extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final String? action;
  final VoidCallback? onAction;
  const EnteteSection(
    this.titre, {
    super.key,
    this.sousTitre,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: titreSection(17)),
              if (sousTitre != null && sousTitre!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(sousTitre!, style: texteDiscret(12.5)),
                ),
            ],
          ),
        ),
        if (action != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              action!,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColor.kPrimaryMedium,
              ),
            ),
          ),
      ],
    );
  }
}

/// Pastille d'icône : carré arrondi gris clair (ou doré si [accent]).
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
        borderRadius: BorderRadius.circular(taille * 0.25),
      ),
      child: Icon(
        icone,
        size: taille * 0.52,
        color: accent ? AppColor.kSecondaryDark : AppColor.kPrimary,
      ),
    );
  }
}

/// État vide ou d'erreur : icône, titre, texte, action facultative.
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 32,
        vertical: compact ? 28 : 48,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: compact ? 40 : 48, color: AppColor.kGrayscale30),
          const SizedBox(height: 14),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: AppColor.kGrayscale40,
              ),
            ),
          ],
          if (action != null && onAction != null) ...[
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}

/// Puce de filtre / tri (sélectionnée : fond marine, texte blanc).
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColor.kPrimary : AppColor.kWhite,
          borderRadius: BorderRadius.circular(8),
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
                size: 15,
                color: active ? AppColor.kWhite : AppColor.kPrimary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              libelle,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? AppColor.kWhite : AppColor.kGrayscaleDark100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Champ de recherche : rectangle arrondi blanc, loupe à gauche.
class ChampRecherche extends StatelessWidget {
  final TextEditingController? controleur;
  final String indication;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool lectureSeule;
  final bool autofocus;

  /// Filet autour du champ, quand il est posé sur un fond clair.
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
      height: 46,
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(10),
        border: surFondClair ? Border.all(color: AppColor.kGrayscale20) : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(
            Icons.search_rounded,
            color: AppColor.kGrayscale40,
            size: 22,
          ),
          const SizedBox(width: 8),
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
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColor.kGrayscaleDark100,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                hintText: indication,
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColor.kGrayscale30,
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
