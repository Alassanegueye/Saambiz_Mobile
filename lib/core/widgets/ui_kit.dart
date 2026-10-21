import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_color.dart';

/// Composants visuels communs de l'espace client (charte reprise de
/// l'application Yobante Boutique) : cartes blanches aérées, titres courts,
/// pastilles d'icône bleu clair, états vides soignés.

TextStyle titreSection([double taille = 15]) => GoogleFonts.plusJakartaSans(
      fontSize: taille,
      fontWeight: FontWeight.w700,
      color: AppColor.kGrayscaleDark100,
    );

TextStyle texteDiscret([double taille = 12]) =>
    GoogleFonts.plusJakartaSans(fontSize: taille, color: AppColor.kGrayscale40);

/// Carte blanche : coins arrondis, ombre bleutée très douce, sans contour.
BoxDecoration decorationCarte({double rayon = 16, Color couleur = AppColor.kWhite}) => BoxDecoration(
      color: couleur,
      borderRadius: BorderRadius.circular(rayon),
      boxShadow: [
        BoxShadow(
          color: AppColor.kPrimary.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );

/// Titre de section avec lien « Voir tout » facultatif.
class EnteteSection extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final String? action;
  final VoidCallback? onAction;
  const EnteteSection(this.titre, {super.key, this.sousTitre, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: titreSection(16.5)),
              if (sousTitre != null && sousTitre!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(sousTitre!, style: texteDiscret(12)),
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColor.kPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Pastille d'icône carrée bleu clair (ou jaune clair si [accent]).
class PastilleIcone extends StatelessWidget {
  final IconData icone;
  final bool accent;
  final double taille;
  const PastilleIcone(this.icone, {super.key, this.accent = false, this.taille = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: accent ? AppColor.kSecondaryLight : AppColor.kPrimaryLight,
        borderRadius: BorderRadius.circular(taille * 0.28),
      ),
      child: Icon(icone,
          size: taille * 0.53, color: accent ? AppColor.kSecondaryDark : AppColor.kPrimary),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28, vertical: compact ? 20 : 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 64 : 84,
            height: compact ? 64 : 84,
            decoration: BoxDecoration(
              color: AppColor.kPrimaryLight,
              borderRadius: BorderRadius.circular(compact ? 20 : 26),
            ),
            child: Icon(icone, size: compact ? 30 : 38, color: AppColor.kPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                height: 1.45,
                color: AppColor.kGrayscale40,
              ),
            ),
          ],
          if (action != null && onAction != null) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kPrimary,
                foregroundColor: AppColor.kWhite,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                action!,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
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
  const PuceFiltre({super.key, required this.libelle, required this.active, required this.onTap, this.icone});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColor.kPrimary : AppColor.kWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppColor.kPrimary : AppColor.kLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, size: 15, color: active ? AppColor.kWhite : AppColor.kPrimary),
              const SizedBox(width: 5),
            ],
            Text(
              libelle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
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

/// Champ de recherche arrondi sur fond clair.
class ChampRecherche extends StatelessWidget {
  final TextEditingController? controleur;
  final String indication;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool lectureSeule;
  final bool autofocus;

  /// Fond blanc et ombre légère (sur un écran gris clair), comme Yobante.
  final bool surFondClair;

  const ChampRecherche({
    super.key,
    this.controleur,
    this.indication = 'Rechercher un produit, une boutique…',
    this.onSubmitted,
    this.onChanged,
    this.onTap,
    this.lectureSeule = false,
    this.autofocus = false,
    this.surFondClair = false,
  });

  @override
  Widget build(BuildContext context) {
    // Même champ que Yobante Boutique : 48 de haut, fond clair, filet gris,
    // loupe bleue de la marque.
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: surFondClair ? AppColor.kWhite : AppColor.kBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.kLine),
        boxShadow: surFondClair
            ? [BoxShadow(color: AppColor.kPrimary.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5))]
            : null,
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
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColor.kGrayscaleDark100),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                hintText: indication,
                hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.kGrayscale40),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}
