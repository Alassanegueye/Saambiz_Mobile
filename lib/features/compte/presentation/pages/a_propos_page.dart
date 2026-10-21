import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/infos_app.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/url_externe.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/profil_kit.dart';
import '../../../auth/presentation/widgets/ContiditionUtilisation.dart';
import '../../../auth/presentation/widgets/PolitiqueConfidentialite.dart';

/// À propos : version de l'application, site web et textes légaux.
class AProposPage extends StatelessWidget {
  const AProposPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: const AppAppBar(title: 'À propos'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Image.asset('assets/images/picto_navy.png', width: 76, height: 76, fit: BoxFit.contain),
                const SizedBox(height: 14),
                Text(
                  InfosApp.nom,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version ${InfosApp.version}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kGrayscale40),
                ),
                const SizedBox(height: 10),
                Text(
                  'L\'application qui met la boutique des commerçants sénégalais en ligne.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.5, color: AppColor.kGrayscale40),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          SectionProfil(
            titre: 'Informations',
            entrees: [
              LigneProfil(
                icone: Icons.public_rounded,
                libelle: 'Site web',
                sousTitre: 'saambiz.com',
                onTap: () => UrlExterne.lancer(InfosApp.site),
              ),
              LigneProfil(
                icone: Icons.description_outlined,
                libelle: 'Conditions d\'utilisation',
                sousTitre: 'Règles d\'utilisation de SaamBiz',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ConditionUtilisation()),
                ),
              ),
              LigneProfil(
                icone: Icons.privacy_tip_outlined,
                libelle: 'Politique de confidentialité',
                sousTitre: 'Ce que nous faisons de vos données',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PolitiqueConfidentialite()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
