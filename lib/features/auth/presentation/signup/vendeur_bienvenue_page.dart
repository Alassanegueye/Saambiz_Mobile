import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routes/app_router.dart';
import '../../domain/entities/user.dart';
import 'signup_kit.dart';

/// Écran 6B : dernier écran du parcours vendeur. Sur fond bleu marine, il
/// annonce l'ouverture de la boutique et donne les trois premières actions.
class VendeurBienvenuePage extends StatelessWidget {
  final User? user;
  final String nomBoutique;

  const VendeurBienvenuePage({super.key, this.user, required this.nomBoutique});

  void _entrer(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.vendeurRoute,
      (_) => false,
      arguments: user,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Sb.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Sb.gold.withOpacity(0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: Sb.gold, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.asset('assets/icons/picto_saambiz.png'),
                  ),
                ),
              ),
              const SizedBox(height: 26),

              Text(
                'Bienvenue sur SaamBiz ! 🎉',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: Sb.white,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Votre boutique\n'),
                    TextSpan(
                      text: '« $nomBoutique »',
                      style: const TextStyle(
                        color: Sb.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: '\nest maintenant créée.'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14.5,
                  height: 1.7,
                  color: Sb.white.withOpacity(0.76),
                ),
              ),
              const SizedBox(height: 32),

              _ActionTile(
                icon: Icons.add_shopping_cart_outlined,
                title: '+ Ajouter un produit',
                subtitle: 'Commencez à vendre dès aujourd\'hui',
                onTap: () => _entrer(context),
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.campaign_outlined,
                title: '+ Créer une promotion',
                subtitle: 'Attirez plus de clients',
                onTap: () => _entrer(context),
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.bar_chart_rounded,
                title: 'Voir mon activité',
                subtitle: 'Suivez vos ventes en temps réel',
                onTap: () => _entrer(context),
              ),

              const SizedBox(height: 30),
              SbPrimaryButton(
                label: 'Accéder à ma boutique',
                onPressed: () => _entrer(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Sb.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Sb.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Sb.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 20, color: Sb.gold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sora(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Sb.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Sb.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Sb.white.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
