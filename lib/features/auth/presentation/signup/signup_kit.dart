import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saambiz/core/theme/police.dart';

import '../widgets/mise_en_page_auth.dart';

/// Briques communes aux ecrans du parcours d'inscription (choix du profil,
/// formulaires, verification email, centres d'interet, creation de boutique).
/// Un seul endroit a toucher pour faire evoluer la charte de ce parcours.

// Palette SaamBiz
class Sb {
  Sb._();

  static const navy = Color(0xFF01154B);
  static const navyDeep = Color(0xFF000B30);
  static const navySoft = Color(0xFFEDF0F8);

  /// Fond d'une carte selectionnee : un bleu/sable a peine perceptible.
  static const navyTint = Color(0xFFF5F7FC);
  static const gold = Color(0xFFFBB900);
  static const goldSoft = Color(0xFFFFF4D1);

  /// Or fonce, lisible sur fond blanc (coches, petits textes).
  static const goldDark = Color(0xFF9A6B00);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F8);

  /// Surface des champs dans une carte blanche (comme a la connexion).
  static const surface = Color(0xFFF7F8FA);
  static const border = Color(0xFFE6E9EF);
  static const text = Color(0xFF01154B);
  static const textMid = Color(0xFF4B5568);
  static const textLight = Color(0xFF98A2B3);
  static const green = Color(0xFF22C55E);
  static const error = Color(0xFFE53935);

  static TextStyle title([double size = 22]) => TextStyle(
    fontFamily: kPolice,
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: navy,
    height: 1.25,
  );

  static TextStyle body([double size = 14]) => TextStyle(
    fontFamily: kPolice,
    fontSize: size,
    color: textMid,
    height: 1.55,
  );

  static TextStyle label() => const TextStyle(
    fontFamily: kPolice,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: navy,
  );
}

/// Ossature commune des ecrans d'inscription : fond clair uni, contenu defilant.
class SbScaffold extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;

  const SbScaffold({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 8, 24, 28),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Sb.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Progression du parcours d'inscription : segments et « Etape 2 sur 5 · Contact ».
class SbEtapes extends StatelessWidget {
  final int courante;
  final bool vendeur;

  /// Posee sur l'en-tete bleu marine : segments et texte en clair.
  final bool surFonce;
  const SbEtapes({
    super.key,
    required this.courante,
    this.vendeur = false,
    this.surFonce = false,
  });

  static const _communes = ['Vous', 'Contact', 'Securite', 'Verification'];

  List<String> get etapes => [
    ..._communes,
    vendeur ? 'Votre boutique' : 'Centres d\'interet',
  ];

  @override
  Widget build(BuildContext context) {
    final liste = etapes;
    final n = courante.clamp(1, liste.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 1; i <= liste.length; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  decoration: BoxDecoration(
                    color: i == n
                        ? Sb.gold
                        : i < n
                        ? (surFonce ? Sb.white : Sb.navy)
                        : (surFonce
                              ? Sb.white.withValues(alpha: 0.18)
                              : Sb.border),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (i < liste.length) const SizedBox(width: 5),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 11.5,
              color: surFonce ? Sb.white.withValues(alpha: 0.7) : Sb.textLight,
            ),
            children: [
              TextSpan(
                text: 'ÉTAPE $n SUR ${liste.length}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ' · ${liste[n - 1]}'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bouton principal SaamBiz (52 px, arrondi 16, marine).
class SbPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const SbPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Sb.navy,
          foregroundColor: Sb.white,
          disabledBackgroundColor: Sb.navy.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: kPolice,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Sb.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Bouton secondaire (fond blanc, bord fin).
class SbSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SbSecondaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Sb.navy,
          side: const BorderSide(color: Sb.border, width: 1.3),
          backgroundColor: Sb.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: kPolice,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Lien texte discret « Déjà un compte ? Se connecter ».
class SbLoginLink extends StatelessWidget {
  final VoidCallback onTap;
  const SbLoginLink({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: TextButton(
          onPressed: onTap,
          child: const Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 13.5,
                color: Sb.textMid,
              ),
              children: [
                TextSpan(text: 'Déjà un compte ? '),
                TextSpan(
                  text: 'Se connecter',
                  style: TextStyle(
                    fontFamily: kPolice,
                    fontWeight: FontWeight.w700,
                    color: Sb.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Champ de formulaire : libelle au-dessus, icone a gauche, fond gris clair.
class SbField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? autofillHint;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final List<TextInputFormatter>? formatters;
  final bool obligatoire;

  /// Remplace l'icône de gauche (sélecteur de pays d'un téléphone, par ex.).
  final Widget? prefixe;

  const SbField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHint,
    this.errorText,
    this.onSubmitted,
    this.suffix,
    this.formatters,
    this.obligatoire = false,
    this.prefixe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LibelleChamp(label, obligatoire: obligatoire),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHint != null ? [autofillHint!] : null,
          inputFormatters: formatters,
          onFieldSubmitted: onSubmitted,
          cursorColor: Sb.navy,
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 15,
            color: Sb.text,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: kPolice,
              color: Sb.textLight,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Sb.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            prefixIcon: prefixe ?? Icon(icon, size: 20, color: Sb.navy),
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Sb.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Sb.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Sb.navy, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Sb.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Sb.error, width: 1.5),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(
              fontFamily: kPolice,
              fontSize: 12,
              color: Sb.error,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bandeau d'erreur rouge clair en haut d'une etape.
class SbErrorBanner extends StatelessWidget {
  final String? message;
  const SbErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Sb.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message!,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 13,
                color: Color(0xFF991B1B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mise en page des ecrans d'inscription, calquee sur la connexion :
/// en-tete bleu marine SaamBiz (logo, titre, sous-titre), carte blanche
/// posee a cheval sur l'en-tete, contenu en defilement continu.
class SbPageAuth extends StatelessWidget {
  final String titre;
  final String? sousTitre;

  /// Pictogramme de l'en-tete ; sans lui, le logo SaamBiz picto_clair.
  final IconData? icone;

  /// Etape courante (1 a 5) du parcours ; null : pas de progression.
  final int? etape;
  final bool vendeur;

  /// Action du bouton retour ; par defaut, la page precedente si elle existe.
  final VoidCallback? onRetour;

  /// Contenu de la carte blanche ; null : pas de carte.
  final List<Widget>? carte;
  final List<Widget> apres;

  /// Bouton a droite de l'en-tete.
  final Widget? actionEntete;

  const SbPageAuth({
    super.key,
    required this.titre,
    this.sousTitre,
    this.icone,
    this.etape,
    this.vendeur = false,
    this.onRetour,
    this.carte,
    this.apres = const [],
    this.actionEntete,
  });

  static const double _chevauchement = 36;

  @override
  Widget build(BuildContext context) {
    final peutRevenir = onRetour != null || Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Sb.bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Sb.navy,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      8,
                      4,
                      24,
                      _chevauchement + 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              if (peutRevenir)
                                IconButton(
                                  tooltip: 'Retour',
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Sb.white,
                                    size: 20,
                                  ),
                                  onPressed:
                                      onRetour ??
                                      () => Navigator.of(context).maybePop(),
                                )
                              else
                                const SizedBox(width: 16),
                              if (etape != null)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: SbEtapes(
                                      courante: etape!,
                                      vendeur: vendeur,
                                      surFonce: true,
                                    ),
                                  ),
                                )
                              else
                                const Spacer(),
                              if (actionEntete != null) ...[
                                const SizedBox(width: 8),
                                actionEntete!,
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                    color: Sb.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Sb.white.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Icon(icone, color: Sb.gold, size: 26),
                                ),
                              const SizedBox(height: 22),
                              Text(
                                titre,
                                style: const TextStyle(
                                  fontFamily: kPolice,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Sb.white,
                                  height: 1.2,
                                ),
                              ),
                              if (sousTitre != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  sousTitre!,
                                  style: TextStyle(
                                    fontFamily: kPolice,
                                    fontSize: 14,
                                    height: 1.45,
                                    color: Sb.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -_chevauchement),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (carte != null)
                        CarteAuth(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: carte!,
                          ),
                        ),
                      ...apres,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Validations partagees
final RegExp kEmailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

/// Regle du backend (MED-02) : 8 caracteres, une majuscule, un chiffre,
/// un caractere special. On la verifie cote app pour eviter un aller-retour.
String? validateMotDePasse(String value) {
  if (value.length < 8) return 'Au moins 8 caracteres.';
  if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Au moins une majuscule.';
  if (!RegExp(r'[0-9]').hasMatch(value)) return 'Au moins un chiffre.';
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
    return 'Au moins un caractere special.';
  }
  return null;
}
