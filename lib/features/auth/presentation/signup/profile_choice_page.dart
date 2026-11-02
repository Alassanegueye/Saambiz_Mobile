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
      _role == 'Vendeur'
          ? AppRouter.vendeurSignupRoute
          : AppRouter.clientSignupRoute,
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
          choisie: _role == 'Acheteur',
          onTap: () => setState(() => _role = 'Acheteur'),
        ),
        const SizedBox(height: 12),
        _CarteProfil(
          icone: Icons.storefront_outlined,
          titre: 'Je veux vendre',
          texte: 'Ouvrir ma boutique et vendre en ligne.',
          choisie: _role == 'Vendeur',
          onTap: () => setState(() => _role = 'Vendeur'),
        ),
        const SizedBox(height: 22),
        SbPrimaryButton(label: 'Continuer', onPressed: _continuer),
        const SizedBox(height: 10),
        SbSecondaryButton(
          label: 'Explorer sans compte',
          onPressed: _sansCompte,
        ),
        const SizedBox(height: 6),
        SbLoginLink(
          onTap: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
        ),
      ],
    );
  }
}

/// Choix d'un espace : icône, titre, une ligne d'explication et bouton
/// radio. Choisie, la ligne prend un contour marine.
class _CarteProfil extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String texte;
  final bool choisie;
  final VoidCallback onTap;

  const _CarteProfil({
    required this.icone,
    required this.titre,
    required this.texte,
    required this.choisie,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: choisie,
      label: '$titre. $texte',
      child: Material(
        color: Sb.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: choisie ? Sb.navy : Sb.border,
            width: choisie ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icone, size: 26, color: Sb.navy),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Sb.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        texte,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: Sb.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<bool>(
                  value: true,
                  groupValue: choisie,
                  onChanged: (_) => onTap(),
                  activeColor: Sb.navy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
