import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Briques communes aux écrans du parcours d'inscription (choix du profil,
/// formulaires, vérification email, centres d'intérêt, création de boutique).
/// Un seul endroit à toucher pour faire évoluer la charte de ce parcours.

// ─── Palette SaamBiz ─────────────────────────────────────────────────────────
class Sb {
  Sb._();

  static const navy = Color(0xFF0D1B3D);
  static const navyDeep = Color(0xFF061029);
  static const navySoft = Color(0xFFE8EDF7);
  static const gold = Color(0xFFF2B705);
  static const goldSoft = Color(0xFFFEF3D6);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFFBFBFC);
  static const border = Color(0xFFE2E7F0);
  static const text = Color(0xFF0D1B3D);
  static const textMid = Color(0xFF48597A);
  static const textLight = Color(0xFF8794AC);
  static const green = Color(0xFF22C55E);
  static const error = Color(0xFFE53935);

  static TextStyle title([double size = 22]) => GoogleFonts.sora(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: navy,
    height: 1.25,
  );

  static TextStyle body([double size = 14]) =>
      GoogleFonts.dmSans(fontSize: size, color: textMid, height: 1.55);

  static TextStyle label() => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: navy,
  );
}

/// Le décor de la maquette : la vague bleu marine et la pastille or du coin
/// haut-droit. Il se pose en fond de [SbScaffold], sous le contenu, et
/// n'occupe donc aucune hauteur dans le flux — le formulaire commence en haut
/// de l'écran et passe par-dessus.
class SbCornerDecor extends StatelessWidget {
  const SbCornerDecor({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 170,
        height: 132,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -46,
              top: -62,
              child: Container(
                width: 158,
                height: 158,
                decoration: const BoxDecoration(
                  color: Sb.navy,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(118),
                    bottomRight: Radius.circular(50),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -28,
              top: 42,
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Sb.gold,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ossature commune des écrans d'inscription : le décor en fond, le contenu
/// défilant par-dessus. Évite de perdre 150 px de haut d'écran — et donc de
/// devoir faire défiler pour atteindre le premier champ.
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
      body: Stack(
        children: [
          const Positioned(top: 0, right: 0, child: SbCornerDecor()),
          SafeArea(
            child: SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo SaamBiz : pictogramme + mot-symbole, comme en tête des maquettes.
class SbWordmark extends StatelessWidget {
  final double height;
  const SbWordmark({super.key, this.height = 42});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/icons/picto_saambiz.png', height: height),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style: GoogleFonts.sora(
              fontSize: height * 0.66,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            children: const [
              TextSpan(
                text: 'Saam',
                style: TextStyle(color: Sb.navy),
              ),
              TextSpan(
                text: 'Biz',
                style: TextStyle(color: Sb.gold),
              ),
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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Sb.label()),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscure,
          inputFormatters: formatters,
          autofillHints: autofillHint == null ? null : [autofillHint!],
          onSubmitted: onSubmitted,
          style: GoogleFonts.dmSans(fontSize: 15, color: Sb.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(fontSize: 15, color: Sb.textLight),
            errorText: errorText,
            errorStyle: GoogleFonts.dmSans(fontSize: 12, color: Sb.error),
            filled: true,
            fillColor: Sb.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            suffixIcon: suffix,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Sb.border, width: 1.3),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Sb.gold, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Sb.error, width: 1.3),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Sb.error, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bouton principal or, pleine largeur, avec état de chargement intégré.
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
          backgroundColor: Sb.gold,
          disabledBackgroundColor: Sb.gold.withOpacity(0.55),
          foregroundColor: Sb.navy,
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
                  valueColor: AlwaysStoppedAnimation<Color>(Sb.navy),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.sora(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Sb.navy,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 19, color: Sb.navy),
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
        border: Border.all(color: Sb.error.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Sb.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message!,
              style: GoogleFonts.dmSans(fontSize: 13, color: Sb.error),
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
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Déjà un compte ? ', style: Sb.body(13.5)),
          GestureDetector(
            onTap: onTap,
            child: Text(
              'Se connecter',
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Sb.gold,
              ),
            ),
          ),
        ],
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
