import 'package:saambiz/core/widgets/libelle_obligatoire.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_color.dart';

/// Mise en page commune des écrans d'authentification (connexion, mot de
/// passe oublié…) : page blanche, logo, titre et sous-titre, puis le
/// formulaire, le tout dans un seul défilement.
class MiseEnPageAuth extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final IconData? icone;
  final List<Widget> enfants;

  const MiseEnPageAuth({
    super.key,
    required this.titre,
    required this.sousTitre,
    required this.enfants,
    this.icone,
  });

  /// Chevauchement du contenu sur l'en-tête.
  static const double chevauchement = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kWhite,
      body: CorpsAuth(
        titre: titre,
        sousTitre: sousTitre,
        icone: icone,
        enfants: enfants,
      ),
    );
  }
}

/// Contenu de [MiseEnPageAuth] sans Scaffold, pour les écrans qui ont déjà le
/// leur (écoute d'un bloc, par exemple).
class CorpsAuth extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final IconData? icone;
  final List<Widget> enfants;

  const CorpsAuth({
    super.key,
    required this.titre,
    required this.sousTitre,
    required this.enfants,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    // Page claire : icônes de la barre d'état en sombre.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _EnteteAuth(titre: titre, sousTitre: sousTitre, icone: icone),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: enfants),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnteteAuth extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final IconData? icone;

  const _EnteteAuth({required this.titre, required this.sousTitre, this.icone});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Navigator.of(context).canPop())
              IconButton(
                tooltip: 'Retour',
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColor.kPrimary,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            else
              const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icone == null)
                    Image.asset(
                      'assets/images/logo.png',
                      height: 34,
                      fit: BoxFit.contain,
                      semanticLabel: 'SaamBiz',
                    )
                  else
                    Icon(icone, color: AppColor.kPrimary, size: 34),
                  const SizedBox(height: 28),
                  Text(
                    titre,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColor.kGrayscaleDark100,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sousTitre,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.45,
                      color: AppColor.kGrayscale40,
                    ),
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

/// Bloc d'un formulaire d'authentification, posé à même la page.
class CarteAuth extends StatelessWidget {
  final String? titre;
  final IconData? icone;
  final Widget child;

  const CarteAuth({super.key, this.titre, this.icone, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titre != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    titre!,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColor.kGrayscaleDark100,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

/// Libellé d'un champ de formulaire.
class LibelleChamp extends StatelessWidget {
  final String texte;
  final bool obligatoire;
  const LibelleChamp(this.texte, {super.key, this.obligatoire = false});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      color: AppColor.kGrayscaleDark100,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: obligatoire
          ? LibelleObligatoire(texte, style: style)
          : Text(texte, style: style),
    );
  }
}

/// Lien « Pas encore de compte ? » sous les cartes.
class LienAuth extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onTap;

  const LienAuth({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: GoogleFonts.inter(color: AppColor.kGrayscale40, fontSize: 14),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(
            action,
            style: GoogleFonts.inter(
              color: AppColor.kPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Décoration commune des champs : surface gris-bleu, coins arrondis, contour
/// bleu à la saisie, rouge en erreur.
InputDecoration decorationChampAuth({
  required String hint,
  Widget? prefixe,
  Widget? suffixe,
}) {
  OutlineInputBorder bord(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: AppColor.kGrayscale30, fontSize: 14),
    filled: true,
    fillColor: AppColor.kSurface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    prefixIcon: prefixe,
    suffixIcon: suffixe,
    border: bord(AppColor.kLine),
    enabledBorder: bord(AppColor.kLine),
    focusedBorder: bord(AppColor.kPrimary, 1.5),
    errorBorder: bord(AppColor.kErreur),
    focusedErrorBorder: bord(AppColor.kErreur, 1.5),
    errorStyle: GoogleFonts.inter(fontSize: 12, color: AppColor.kErreur),
  );
}

/// Champ de formulaire complet : libellé au-dessus, saisie au style SaamBiz.
class ChampFormulaire extends StatelessWidget {
  final String libelle;
  final String hint;
  final TextEditingController controller;
  final IconData? icone;
  final TextInputType? clavier;
  final FormFieldValidator<String>? validator;
  final TextInputAction? action;
  final Iterable<String>? autofill;
  final bool obligatoire;

  const ChampFormulaire({
    super.key,
    required this.libelle,
    required this.hint,
    required this.controller,
    this.icone,
    this.clavier,
    this.validator,
    this.action,
    this.autofill,
    this.obligatoire = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LibelleChamp(libelle, obligatoire: obligatoire),
        TextFormField(
          controller: controller,
          keyboardType: clavier,
          textInputAction: action,
          autofillHints: autofill,
          validator: validator,
          cursorColor: AppColor.kPrimary,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: decorationChampAuth(
            hint: hint,
            prefixe: icone == null
                ? null
                : Icon(icone, color: AppColor.kPrimary, size: 20),
          ),
        ),
      ],
    );
  }
}

/// Champ mot de passe : œil pour afficher / masquer la saisie.
class ChampMotDePasse extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String>? validator;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;

  const ChampMotDePasse({
    super.key,
    required this.controller,
    this.hint = 'Votre mot de passe',
    this.validator,
    this.action,
    this.onSubmitted,
  });

  @override
  State<ChampMotDePasse> createState() => _ChampMotDePasseState();
}

class _ChampMotDePasseState extends State<ChampMotDePasse> {
  bool _masque = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _masque,
      textInputAction: widget.action,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      autofillHints: const [AutofillHints.password],
      cursorColor: AppColor.kPrimary,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: AppColor.kGrayscaleDark100,
      ),
      decoration: decorationChampAuth(
        hint: widget.hint,
        prefixe: const Icon(
          Icons.lock_outline_rounded,
          color: AppColor.kPrimary,
          size: 20,
        ),
        suffixe: IconButton(
          tooltip: _masque
              ? 'Afficher le mot de passe'
              : 'Masquer le mot de passe',
          icon: Icon(
            _masque ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColor.kGrayscale40,
            size: 20,
          ),
          onPressed: () => setState(() => _masque = !_masque),
        ),
      ),
    );
  }
}

/// Bouton principal des écrans d'authentification : bleu marine plein,
/// indicateur de chargement à la place du libellé.
class BoutonAuth extends StatelessWidget {
  final String texte;
  final VoidCallback? onPressed;
  final bool chargement;

  const BoutonAuth({
    super.key,
    required this.texte,
    this.onPressed,
    this.chargement = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: chargement ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.kPrimary,
          foregroundColor: AppColor.kWhite,
          disabledBackgroundColor: AppColor.kPrimary.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: chargement
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColor.kWhite),
                ),
              )
            : Text(texte),
      ),
    );
  }
}
