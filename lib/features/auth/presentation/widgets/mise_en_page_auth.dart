import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:saambiz/core/widgets/libelle_obligatoire.dart';

import '../../../../core/theme/app_color.dart';

/// Mise en page commune des ecrans d'authentification (connexion, mot de
/// passe oublie) : en-tete bleu marine (pictogramme, titre, sous-titre), puis
/// le contenu pose a cheval sur l'en-tete, le tout dans un seul defilement.
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

  /// Chevauchement du contenu sur l'en-tete.
  static const double chevauchement = 36;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      body: CorpsAuth(
        titre: titre,
        sousTitre: sousTitre,
        icone: icone,
        enfants: enfants,
      ),
    );
  }
}

/// Contenu de [MiseEnPageAuth] sans Scaffold, pour les ecrans qui ont deja le
/// leur (ecoute d'un bloc, par exemple).
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
    // En-tete bleu : icones de la barre d'etat en blanc.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _EnteteAuth(titre: titre, sousTitre: sousTitre, icone: icone),
            Transform.translate(
              offset: const Offset(0, -MiseEnPageAuth.chevauchement),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: enfants),
              ),
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColor.kPrimary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            8,
            4,
            24,
            MiseEnPageAuth.chevauchement + 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Navigator.of(context).canPop())
                IconButton(
                  tooltip: 'Retour',
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColor.kWhite,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              else
                const SizedBox(height: 48),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo pose directement sur le bleu : version claire
                    // (cadenas blanc, barres dorees), sans cadre blanc.
                    if (icone == null)
                      Image.asset(
                        'assets/images/picto_clair.png',
                        height: 52,
                        fit: BoxFit.contain,
                        semanticLabel: 'SaamBiz',
                      )
                    else
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColor.kWhite.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColor.kWhite.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(
                          icone,
                          color: AppColor.kSecondary,
                          size: 26,
                        ),
                      ),
                    const SizedBox(height: 26),
                    Text(
                      titre,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kWhite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sousTitre,
                      style: TextStyle(
                        fontFamily: kPolice,
                        fontSize: 14,
                        color: AppColor.kWhite.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
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

/// Libelle au-dessus d'un champ avec asterisque rouge optionnel.
class LibelleChamp extends StatelessWidget {
  final String texte;
  final bool obligatoire;
  const LibelleChamp(this.texte, {super.key, this.obligatoire = false});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: kPolice,
      fontWeight: FontWeight.w600,
      fontSize: 13,
      color: AppColor.kGrayscaleDark100,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: obligatoire
          ? LibelleObligatoire(texte, style: style)
          : Text(texte, style: style),
    );
  }
}

/// Carte blanche posee sur le bleu de l'en-tete.
class CarteAuth extends StatelessWidget {
  final Widget child;
  const CarteAuth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Lien sous la carte ("Pas encore de compte ? Creer un compte").
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontFamily: kPolice,
              color: AppColor.kGrayscale40,
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: Text(
              action,
              style: const TextStyle(
                fontFamily: kPolice,
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
}

/// Decoration commune des champs : surface gris-bleu, coins arrondis, contour
/// bleu a la saisie, rouge en erreur.
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
    hintStyle: const TextStyle(
      fontFamily: kPolice,
      color: AppColor.kGrayscale30,
      fontSize: 14,
    ),
    filled: true,
    fillColor: AppColor.kSurface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    // Icone fine et grise, avec de l'air avant le texte saisi.
    prefixIcon: prefixe == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: IconTheme.merge(
              data: const IconThemeData(color: AppColor.kGrayscale30, size: 19),
              child: prefixe,
            ),
          ),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    suffixIcon: suffixe,
    border: bord(AppColor.kLine),
    enabledBorder: bord(AppColor.kLine),
    focusedBorder: bord(AppColor.kPrimary, 1.5),
    errorBorder: bord(AppColor.kErreur),
    focusedErrorBorder: bord(AppColor.kErreur, 1.5),
    errorStyle: const TextStyle(
      fontFamily: kPolice,
      fontSize: 12,
      color: AppColor.kErreur,
    ),
  );
}

/// Champ de formulaire complet : libelle au-dessus, saisie au style SaamBiz.
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

  /// Remplace l'icône de gauche (sélecteur de pays d'un téléphone).
  final Widget? prefixe;
  final List<TextInputFormatter>? formats;

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
    this.prefixe,
    this.formats,
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
          inputFormatters: formats,
          textInputAction: action,
          autofillHints: autofill,
          validator: validator,
          cursorColor: AppColor.kPrimary,
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 15,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: decorationChampAuth(
            hint: hint,
            prefixe: prefixe ?? (icone == null ? null : Icon(icone)),
          ),
        ),
      ],
    );
  }
}

/// Champ mot de passe : oeil pour afficher / masquer la saisie.
class ChampMotDePasse extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String>? validator;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const ChampMotDePasse({
    super.key,
    required this.controller,
    this.hint = 'Votre mot de passe',
    this.validator,
    this.action,
    this.onSubmitted,
    this.focusNode,
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
      focusNode: widget.focusNode,
      obscureText: _masque,
      textInputAction: widget.action,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      autofillHints: const [AutofillHints.password],
      cursorColor: AppColor.kPrimary,
      style: const TextStyle(
        fontFamily: kPolice,
        fontSize: 15,
        color: AppColor.kGrayscaleDark100,
      ),
      decoration: decorationChampAuth(
        hint: widget.hint,
        prefixe: const Icon(Icons.lock_outline_rounded),
        suffixe: IconButton(
          tooltip: _masque
              ? 'Afficher le mot de passe'
              : 'Masquer le mot de passe',
          icon: Icon(
            _masque ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColor.kGrayscale30,
            size: 19,
          ),
          onPressed: () => setState(() => _masque = !_masque),
        ),
      ),
    );
  }
}

/// Bouton principal des ecrans d'authentification : bleu marine plein,
/// indicateur de chargement a la place du libelle.
class BoutonAuth extends StatelessWidget {
  final String texte;
  final VoidCallback? onPressed;
  final bool chargement;
  final Color fond;
  final Color couleurTexte;

  const BoutonAuth({
    super.key,
    required this.texte,
    this.onPressed,
    this.chargement = false,
    this.fond = AppColor.kPrimary,
    this.couleurTexte = AppColor.kWhite,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: chargement ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: fond,
          foregroundColor: couleurTexte,
          disabledBackgroundColor: fond.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: kPolice,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: chargement
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(couleurTexte),
                ),
              )
            : Text(texte),
      ),
    );
  }
}
