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
    return SbPageAuth(
      icone: Icons.storefront_rounded,
      titre: 'Bienvenue !',
      sousTitre: '« $nomBoutique » est en ligne.',
      carte: [
        _ActionTile(
          icon: Icons.add_shopping_cart_outlined,
          title: 'Ajouter un produit',
          onTap: () => _entrer(context),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.campaign_outlined,
          title: 'Créer une promotion',
          onTap: () => _entrer(context),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.bar_chart_rounded,
          title: 'Voir mon activité',
          onTap: () => _entrer(context),
        ),
      ],
      apres: [
        SbPrimaryButton(
          label: 'Accéder à ma boutique',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => _entrer(context),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Sb.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Sb.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: Sb.navySoft, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 19, color: Sb.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w600, color: Sb.navy),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Sb.textLight),
            ],
          ),
        ),
      ),
    );
  }
}
