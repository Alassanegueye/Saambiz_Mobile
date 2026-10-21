import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routes/app_router.dart';
import 'signup_kit.dart';

/// Écran 1 de l'inscription : client ou vendeur.
///
/// Affiché après l'onboarding et depuis « Créer un compte ». Même mise en
/// page que la connexion (en-tête bleu marine, contenu à cheval), deux cartes
/// à choix unique puis le bouton. Le client est présélectionné.
class ProfileChoicePage extends StatefulWidget {
  const ProfileChoicePage({super.key});

  @override
  State<ProfileChoicePage> createState() => _ProfileChoicePageState();
}

class _ProfileChoicePageState extends State<ProfileChoicePage> {
  String _role = 'Acheteur';

  void _continuer() {
    Navigator.of(context).pushNamed(
      _role == 'Vendeur' ? AppRouter.vendeurSignupRoute : AppRouter.clientSignupRoute,
    );
  }

  void _sansCompte() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.acheteurRoute,
      (_) => false,
      arguments: const {'isGuest': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    return SbPageAuth(
      titre: 'Créer un compte',
      sousTitre: 'Choisissez votre espace.',
      apres: [
        _CarteProfil(
          icone: Icons.shopping_bag_outlined,
          titre: 'Je veux acheter',
          texte: 'Commander et suivre mes livraisons.',
          atouts: const ['Promotions', 'Paiement mobile'],
          choisie: _role == 'Acheteur',
          onTap: () => setState(() => _role = 'Acheteur'),
        ),
        const SizedBox(height: 12),
        _CarteProfil(
          icone: Icons.storefront_outlined,
          titre: 'Je veux vendre',
          texte: 'Ouvrir ma boutique en quelques minutes.',
          atouts: const ['Gratuit', 'Site web inclus'],
          choisie: _role == 'Vendeur',
          onTap: () => setState(() => _role = 'Vendeur'),
        ),
        const SizedBox(height: 22),
        SbPrimaryButton(
          label: 'Continuer',
          icon: Icons.arrow_forward_rounded,
          onPressed: _continuer,
        ),
        const SizedBox(height: 10),
        SbSecondaryButton(label: 'Explorer sans compte', onPressed: _sansCompte),
        const SizedBox(height: 6),
        SbLoginLink(onTap: () => Navigator.of(context).pushNamed(AppRouter.loginRoute)),
      ],
    );
  }
}

/// Carte de choix : toujours blanche ; une fois choisie, seuls la pastille
/// d'icône et le bouton radio passent au jaune de la marque.
class _CarteProfil extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String texte;
  final List<String> atouts;
  final bool choisie;
  final VoidCallback onTap;

  const _CarteProfil({
    required this.icone,
    required this.titre,
    required this.texte,
    required this.atouts,
    required this.choisie,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const encre = Sb.navy;
    const secondaire = Sb.textMid;

    return Semantics(
      button: true,
      selected: choisie,
      label: '$titre. $texte',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Sb.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: choisie ? Sb.gold : Sb.border, width: choisie ? 1.8 : 1.3),
            boxShadow: [
              BoxShadow(
                color: Sb.navy.withValues(alpha: choisie ? 0.12 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: choisie ? Sb.gold : Sb.navySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icone, size: 24, color: Sb.navy),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      titre,
                      style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: encre),
                    ),
                  ),
                  _Radio(coche: choisie),
                ],
              ),
              const SizedBox(height: 12),
              Text(texte, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.45, color: secondaire)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in atouts)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Sb.bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, size: 13, color: choisie ? Sb.goldDark : Sb.textLight),
                          const SizedBox(width: 4),
                          Text(a,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5, fontWeight: FontWeight.w600, color: encre)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool coche;
  const _Radio({required this.coche});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: coche ? Sb.gold : Colors.transparent,
        border: Border.all(color: coche ? Sb.gold : Sb.border, width: 2),
      ),
      child: coche ? const Icon(Icons.check_rounded, size: 15, color: Sb.navy) : null,
    );
  }
}
