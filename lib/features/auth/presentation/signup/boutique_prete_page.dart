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
    return Scaffold(
      backgroundColor: Sb.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Sb.goldSoft,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 44,
                    color: Sb.navy,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'Votre boutique est prête 🎉',
                  textAlign: TextAlign.center,
                  style: Sb.title(23),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Ajoutez votre premier produit pour commencer à vendre.',
                  textAlign: TextAlign.center,
                  style: Sb.body(14.5),
                ),
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _ajouterProduit(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'Ajouter un produit',
                    style: GoogleFonts.sora(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Sb.navy,
                    foregroundColor: Sb.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _versBienvenue(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Sb.navy,
                    side: const BorderSide(color: Sb.border, width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Passer pour l'instant",
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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
