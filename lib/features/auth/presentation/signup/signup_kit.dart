import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/mise_en_page_auth.dart';

/// Briques communes aux écrans du parcours d'inscription (choix du profil,
/// formulaires, vérification email, centres d'intérêt, création de boutique).
/// Un seul endroit à toucher pour faire évoluer la charte de ce parcours.

// ─── Palette SaamBiz ─────────────────────────────────────────────────────────
class Sb {
  Sb._();

  static const navy = Color(0xFF0D1B3D);
  static const navyDeep = Color(0xFF061029);
  static const navySoft = Color(0xFFE8EEF9);
  /// Fond d'une carte sélectionnée : un bleu à peine perceptible.
  static const navyTint = Color(0xFFF1F5FD);
  static const gold = Color(0xFFF2B705);
  static const goldSoft = Color(0xFFFEF3D6);
  /// Or foncé, lisible sur fond blanc (coches, petits textes).
  static const goldDark = Color(0xFF8A6503);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF7F9FD);
  /// Surface des champs dans une carte blanche (comme à la connexion).
  static const surface = Color(0xFFF7F9FC);
  static const border = Color(0xFFE2E7F0);
  static const text = Color(0xFF0D1B3D);
  static const textMid = Color(0xFF48597A);
  static const textLight = Color(0xFF8794AC);
  static const green = Color(0xFF22C55E);
  static const error = Color(0xFFE53935);

  static TextStyle title([double size = 22]) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: navy,
    height: 1.25,
  );

  static TextStyle body([double size = 14]) =>
      GoogleFonts.plusJakartaSans(fontSize: size, color: textMid, height: 1.55);

  static TextStyle label() => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: navy,
  );
}

/// Ossature commune des écrans d'inscription : fond clair uni, contenu
/// défilant. Volontairement sans décor (plus de vague ni de pastille dans
/// l'angle) : l'écran reste calme et le contenu commence tout en haut.
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

/// Progression du parcours d'inscription : segments et « Étape 2 sur 5 ·
/// Contact ». Même nombre d'étapes pour les deux profils, seule la dernière
/// change (vos goûts pour un client, votre boutique pour un vendeur).
/// Pas de logo sur ces écrans : la progression tient lieu d'en-tête.
class SbEtapes extends StatelessWidget {
  final int courante;
  final bool vendeur;
  /// Posée sur l'en-tête bleu marine : segments et texte en clair.
  final bool surFonce;
  const SbEtapes({super.key, required this.courante, this.vendeur = false, this.surFonce = false});

  static const _communes = ['Vous', 'Contact', 'Sécurité', 'Vérification'];

  List<String> get etapes => [..._communes, vendeur ? 'Votre boutique' : 'Vos goûts'];

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
                            : (surFonce ? Sb.white.withValues(alpha: 0.18) : Sb.border),
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: surFonce ? Sb.white.withValues(alpha: 0.7) : Sb.textLight,
            ),
            children: [
              TextSpan(
                text: 'ÉTAPE $n SUR ${liste.length}',
                style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6),
              ),
              TextSpan(text: '  ·  ${liste[n - 1]}'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Flèche de retour discrète, alignée sur les maquettes.
class SbBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const SbBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      borderRadius: BorderRadius.circular(12),
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Sb.navy),
      ),
    );
  }
}

/// Champ de saisie : libellé au-dessus, bordure arrondie, focus or.
class SbField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscure;
  final Widget? suffix;
  final String? errorText;
  final List<TextInputFormatter>? formatters;
  final String? autofillHint;
  final void Function(String)? onSubmitted;
  final IconData? icon;

  const SbField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscure = false,
    this.suffix,
    this.errorText,
    this.formatters,
    this.autofillHint,
    this.onSubmitted,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LibelleChamp(label),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscure,
          inputFormatters: formatters,
          autofillHints: autofillHint == null ? null : [autofillHint!],
          onSubmitted: onSubmitted,
          style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Sb.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 15, color: Sb.textLight),
            errorText: errorText,
            errorStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Sb.error),
            filled: true,
            fillColor: Sb.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: icon == null ? null : Icon(icon, color: Sb.navy, size: 20),
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
          ),
        ),
      ],
    );
  }
}

/// Bouton principal bleu marine, pleine largeur, flèche or, avec état de
/// chargement intégré.
class SbPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const SbPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Sb.navy,
          disabledBackgroundColor: Sb.navy.withValues(alpha: 0.35),
          foregroundColor: Sb.white,
          disabledForegroundColor: Sb.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Sb.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Sb.white,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 10),
                    Icon(icon, size: 22, color: Sb.gold),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Bandeau d'erreur sous un formulaire (message renvoyé par le backend).
class SbErrorBanner extends StatelessWidget {
  final String? message;
  const SbErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Sb.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Sb.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message!,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Sb.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// « Déjà un compte ? Se connecter »
class SbLoginLink extends StatelessWidget {
  final VoidCallback onTap;
  const SbLoginLink({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) =>
      LienAuth(question: 'Déjà un compte ? ', action: 'Se connecter', onTap: onTap);
}

/// Bouton secondaire (blanc, contour discret), pleine largeur.
class SbSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const SbSecondaryButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    final texte = Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700));
    final style = OutlinedButton.styleFrom(
      foregroundColor: Sb.navy,
      backgroundColor: Sb.white,
      side: const BorderSide(color: Sb.border, width: 1.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: icon == null
          ? OutlinedButton(onPressed: onPressed, style: style, child: texte)
          : OutlinedButton.icon(onPressed: onPressed, style: style, icon: Icon(icon, size: 20), label: texte),
    );
  }
}

/// Mise en page des écrans d'inscription, calquée sur la connexion :
/// en-tête bleu marine (retour, progression, pictogramme, titre court) puis
/// une carte blanche posée à cheval, et ce qui suit la carte (boutons, liens).
class SbPageAuth extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  /// Pictogramme de l'en-tête ; sans lui, le logo SaamBiz.
  final IconData? icone;
  /// Étape courante (1 à 5) du parcours ; null : pas de progression.
  final int? etape;
  final bool vendeur;
  /// Action du bouton retour ; par défaut, la page précédente si elle existe.
  final VoidCallback? onRetour;
  /// Contenu de la carte blanche ; null : pas de carte.
  final List<Widget>? carte;
  final List<Widget> apres;
  /// Bouton à droite de l'en-tête (« Se connecter »…).
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
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 20, _chevauchement + 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              if (peutRevenir)
                                IconButton(
                                  tooltip: 'Retour',
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Sb.white, size: 20),
                                  onPressed: onRetour ?? () => Navigator.of(context).maybePop(),
                                )
                              else
                                const SizedBox(width: 16),
                              if (etape != null)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: SbEtapes(courante: etape!, vendeur: vendeur, surFonce: true),
                                  ),
                                )
                              else
                                const Spacer(),
                              if (actionEntete != null) ...[const SizedBox(width: 8), actionEntete!],
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
                                    border: Border.all(color: Sb.white.withValues(alpha: 0.18)),
                                  ),
                                  child: Icon(icone, color: Sb.gold, size: 26),
                                ),
                              const SizedBox(height: 22),
                              Text(
                                titre,
                                style: GoogleFonts.plusJakartaSans(
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
                                  style: GoogleFonts.plusJakartaSans(
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

// ─── Validations partagées ───────────────────────────────────────────────────

final RegExp kEmailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

/// Règle du backend (MED-02) : 8 caractères, une majuscule, un chiffre,
/// un caractère spécial. On la vérifie côté app pour éviter un aller-retour.
String? validateMotDePasse(String value) {
  if (value.length < 8) return 'Au moins 8 caractères.';
  if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Au moins une majuscule.';
  if (!RegExp(r'[0-9]').hasMatch(value)) return 'Au moins un chiffre.';
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
    return 'Au moins un caractère spécial.';
  }
  return null;
}
