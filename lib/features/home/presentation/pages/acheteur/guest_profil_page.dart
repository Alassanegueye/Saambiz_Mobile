import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/routes/app_router.dart';

import '../../../../../core/constants/infos_app.dart';
import '../../../../../core/theme/app_color.dart';
import '../../../../../core/utils/url_externe.dart';
import '../../../../../core/widgets/app_app_bar.dart';
import '../../../../../core/widgets/barre_navigation_verre.dart' show kEspaceBarreBas;
import '../../../../../core/widgets/profil_kit.dart';
import '../../../../compte/presentation/pages/aide_page.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';

/// Onglet « Compte » d'un visiteur sans compte — même écran que Yobante
/// Boutique : carte bleue de bienvenue (connexion / inscription), puis
/// notifications et aide.
class GuestProfilPage extends StatefulWidget {
  const GuestProfilPage({super.key});

  @override
  State<GuestProfilPage> createState() => _GuestProfilPageState();
}

class _GuestProfilPageState extends State<GuestProfilPage> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
  late final Animation<double> _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _ouvrir(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

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
              titre: 'Notifications',
              entrees: [
                LigneProfil(
                  icone: Icons.notifications_none_rounded,
                  libelle: 'Notifications',
                  sousTitre: 'Suivi de vos commandes et alertes',
                  onTap: () => _ouvrir(const NotificationsPage()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionProfil(
              titre: 'Aide & Support',
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

  /// Carte bleue de bienvenue : pictogramme, présentation, connexion ou
  /// inscription.
  Widget _carteBienvenue() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColor.kPrimary, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColor.kWhite, borderRadius: BorderRadius.circular(14)),
            child: Image.asset('assets/images/picto_navy.png', width: 32, height: 32),
          ),
          const SizedBox(height: 14),
          Text(
            'Bienvenue sur SaamBiz',
            style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w700, color: AppColor.kWhite),
          ),
          const SizedBox(height: 6),
          Text(
            'Connectez-vous pour suivre vos commandes, retrouver vos favoris et finaliser votre panier.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              color: AppColor.kWhite.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kSecondary,
                    foregroundColor: AppColor.kPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Se connecter', maxLines: 1, softWrap: false),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRouter.profileChoiceRoute),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.kWhite,
                    side: BorderSide(color: AppColor.kWhite.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Créer un compte', maxLines: 1, softWrap: false),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
