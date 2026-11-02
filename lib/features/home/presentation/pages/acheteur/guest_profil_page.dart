import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/routes/app_router.dart';

import '../../../../../core/constants/infos_app.dart';
import '../../../../../core/theme/app_color.dart';
import '../../../../../core/utils/url_externe.dart';
import '../../../../../core/widgets/app_app_bar.dart';
import '../../../../../core/widgets/barre_navigation_verre.dart'
    show kEspaceBarreBas;
import '../../../../../core/widgets/profil_kit.dart';
import '../../../../compte/presentation/pages/aide_page.dart';

/// Onglet « Compte » d’un visiteur sans compte : bloc de connexion, puis
/// assistance.
class GuestProfilPage extends StatefulWidget {
  const GuestProfilPage({super.key});

  @override
  State<GuestProfilPage> createState() => _GuestProfilPageState();
}

class _GuestProfilPageState extends State<GuestProfilPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..forward();
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _ouvrir(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: const AppAppBar(title: 'Compte', implyLeading: false),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, kEspaceBarreBas),
          children: [
            _carteBienvenue(),
            const SizedBox(height: 24),
            SectionProfil(
              titre: 'Assistance',
              entrees: [
                LigneProfil(
                  icone: Icons.help_outline_rounded,
                  libelle: 'Centre d\'aide',
                  sousTitre: 'Questions fréquentes',
                  onTap: () => _ouvrir(const AidePage()),
                ),
                LigneProfil(
                  icone: Icons.support_agent_outlined,
                  libelle: 'Nous contacter',
                  sousTitre: 'Service client',
                  onTap: () => _ouvrir(const AidePage(contactSeulement: true)),
                ),
                LigneProfil(
                  icone: Icons.star_border_rounded,
                  libelle: 'Noter l\'application',
                  sousTitre: 'Votre avis compte',
                  onTap: () => UrlExterne.lancer(InfosApp.lienPlayStore),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const VersionApp(),
          ],
        ),
      ),
    );
  }

  /// Bloc d'accueil : présentation, connexion ou inscription.
  Widget _carteBienvenue() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vous n’êtes pas connecté',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Connectez-vous pour commander, suivre vos livraisons et garder vos favoris.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.4,
              color: AppColor.kGrayscale40,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRouter.loginRoute),
                  child: const Text('Se connecter'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(AppRouter.profileChoiceRoute),
                  child: const Text('Créer un compte'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
