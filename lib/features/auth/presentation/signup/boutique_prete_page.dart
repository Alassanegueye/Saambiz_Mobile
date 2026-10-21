import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routes/app_router.dart';
import '../../../vendeur/presentation/pages/produit_form_page.dart';
import '../../domain/entities/user.dart';
import 'signup_kit.dart';

/// Écran 5B : la boutique existe, on propose d'y mettre un premier produit.
/// L'étape est volontairement sautable — un vendeur qui n'a pas ses photos
/// sous la main doit pouvoir entrer dans l'application quand même.
class BoutiquePretePage extends StatelessWidget {
  final User? user;
  final String nomBoutique;

  const BoutiquePretePage({super.key, this.user, required this.nomBoutique});

  void _versBienvenue(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.vendeurBienvenueRoute,
      (_) => false,
      arguments: {'user': user, 'nomBoutique': nomBoutique},
    );
  }

  Future<void> _ajouterProduit(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProduitFormPage()));
    if (context.mounted) _versBienvenue(context);
  }

  @override
  Widget build(BuildContext context) {
    return SbPageAuth(
      icone: Icons.inventory_2_outlined,
      titre: 'Boutique prête !',
      sousTitre: 'Ajoutez votre premier produit.',
      carte: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Sb.goldSoft, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.storefront_rounded, color: Sb.navy, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                nomBoutique,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Sb.navy),
              ),
            ),
            const Icon(Icons.check_circle_rounded, color: Sb.green, size: 22),
          ],
        ),
        const SizedBox(height: 20),
        SbPrimaryButton(
          label: 'Ajouter un produit',
          icon: Icons.add_rounded,
          onPressed: () => _ajouterProduit(context),
        ),
        const SizedBox(height: 10),
        SbSecondaryButton(label: "Passer pour l'instant", onPressed: () => _versBienvenue(context)),
      ],
    );
  }
}
