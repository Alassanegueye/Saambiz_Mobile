import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routes/app_router.dart';
import 'signup_kit.dart';

/// Écran 1 du parcours : client ou vendeur.
/// Affiché juste après l'onboarding, et accessible ensuite depuis « Créer un
/// compte ». Le choix n'est pas définitif : un client peut ouvrir une boutique
/// plus tard depuis son profil.
class ProfileChoicePage extends StatefulWidget {
  const ProfileChoicePage({super.key});

  @override
  State<ProfileChoicePage> createState() => _ProfileChoicePageState();
}

class _ProfileChoicePageState extends State<ProfileChoicePage> {
  // null = rien de sélectionné : le bouton reste inactif tant qu'on n'a pas
  // choisi, comme sur la maquette.
  String? _role;

  void _continuer() {
    if (_role == null) return;
    Navigator.of(context).pushNamed(
      _role == 'Vendeur'
          ? AppRouter.vendeurSignupRoute
          : AppRouter.clientSignupRoute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SbScaffold(
      children: [
        const SbWordmark(),
        const SizedBox(height: 34),
        Text('Bienvenue sur SaamBiz 👋', style: Sb.title(24)),
        const SizedBox(height: 10),
        Text('Comment souhaitez-vous utiliser SaamBiz ?', style: Sb.body(14.5)),
        const SizedBox(height: 26),

        _RoleCard(
          icon: Icons.shopping_bag_outlined,
          title: 'Je suis client',
          subtitle:
              'Je veux découvrir et acheter des produits près de chez moi.',
          selected: _role == 'Acheteur',
          onTap: () => setState(() => _role = 'Acheteur'),
        ),
        const SizedBox(height: 14),
        _RoleCard(
          icon: Icons.storefront_outlined,
          title: 'Je suis vendeur',
          subtitle: 'Je veux créer ma boutique et vendre mes produits.',
          selected: _role == 'Vendeur',
          onTap: () => setState(() => _role = 'Vendeur'),
        ),

        const SizedBox(height: 26),
        SbPrimaryButton(
          label: 'Continuer',
          icon: Icons.arrow_forward_rounded,
          onPressed: _role == null ? null : _continuer,
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Vous pourrez changer votre choix plus tard.',
            textAlign: TextAlign.center,
            style: Sb.body(12.5),
          ),
        ),

        const SizedBox(height: 22),
        // Consultation libre : on peut parcourir les boutiques sans
        // compte, la connexion n'est demandée qu'à la commande.
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.acheteurRoute,
              (_) => false,
              arguments: const {'isGuest': true},
            ),
            child: Text(
              'Continuer sans compte',
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Sb.textMid,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SbLoginLink(
          onTap: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Sélectionnée, la carte passe en bleu marine plein : c'est le seul repère
    // de la maquette, sans case à cocher.
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? Sb.navy : Sb.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? Sb.navy : Sb.border,
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Sb.navy.withOpacity(selected ? 0.22 : 0.05),
                blurRadius: selected ? 22 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? Sb.white.withOpacity(0.12) : Sb.navySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 23,
                  color: selected ? Sb.gold : Sb.navy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.sora(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? Sb.white : Sb.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        height: 1.45,
                        color: selected
                            ? Sb.white.withOpacity(0.72)
                            : Sb.textMid,
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
