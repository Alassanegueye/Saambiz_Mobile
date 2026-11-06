import 'package:flutter/material.dart';
import 'package:saambiz/core/constants/infos_app.dart';
import 'package:saambiz/core/routes/app_router.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:saambiz/core/utils/url_externe.dart';
import 'package:saambiz/core/widgets/app_app_bar.dart';
import 'package:saambiz/core/widgets/degrade_fond.dart';
import 'package:saambiz/core/widgets/barre_navigation_verre.dart'
    show kEspaceBarreBas;
import 'package:saambiz/core/widgets/profil_kit.dart';
import 'package:saambiz/features/compte/presentation/pages/a_propos_page.dart';
import 'package:saambiz/features/compte/presentation/pages/aide_page.dart';
import 'package:saambiz/features/promotions/presentation/pages/promotions_actives_page.dart';

/// Onglet « Compte » d'un visiteur sans compte : carte hero de bienvenue
/// invitant a la connexion / inscription, activites accessibles ou necessitant
/// connexion, puis aide et informations.
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

  void _demanderConnexion(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Connectez-vous pour $action',
          style: const TextStyle(fontFamily: kPolice),
        ),
        action: SnackBarAction(
          label: 'Connexion',
          textColor: AppColor.kSecondary,
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRouter.loginRoute),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FondDegradeSubtil(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const AppAppBar(
          title: 'Compte',
          centerTitle: true,
          implyLeading: false,
          couleurFond: Colors.transparent,
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, kEspaceBarreBas),
          children: [
            _carteBienvenue(),
            const SizedBox(height: 24),
            SectionProfil(
              titre: 'Mon activité',
              entrees: [
                LigneProfil(
                  icone: Icons.local_offer_outlined,
                  libelle: 'Promotions actives',
                  sousTitre: 'Bons plans du moment',
                  onTap: () => _ouvrir(const PromotionsActivesPage()),
                ),
                LigneProfil(
                  icone: Icons.receipt_long_outlined,
                  libelle: 'Mes commandes',
                  sousTitre: 'Suivez vos achats et livraisons',
                  onTap: () => _demanderConnexion('suivre vos commandes.'),
                ),
                LigneProfil(
                  icone: Icons.favorite_border_rounded,
                  libelle: 'Mes favoris',
                  sousTitre: 'Vos boutiques enregistrées',
                  onTap: () => _demanderConnexion('retrouver vos favoris.'),
                ),
                LigneProfil(
                  icone: Icons.chat_bubble_outline_rounded,
                  libelle: 'Messages',
                  sousTitre: 'Vos échanges avec les vendeurs',
                  onTap: () => _demanderConnexion('échanger avec les vendeurs.'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionProfil(
              titre: 'Aide et informations',
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
                  sousTitre: 'Service client SaamBiz',
                  onTap: () =>
                      _ouvrir(const AidePage(contactSeulement: true)),
                ),
                LigneProfil(
                  icone: Icons.star_border_rounded,
                  libelle: 'Noter l\'application',
                  sousTitre: 'Votre avis compte pour nous',
                  onTap: () => UrlExterne.lancer(InfosApp.lienPlayStore),
                ),
                LigneProfil(
                  icone: Icons.info_outline_rounded,
                  libelle: 'À propos',
                  sousTitre:
                      'Version ${InfosApp.version}, conditions et confidentialité',
                  onTap: () => _ouvrir(const AProposPage()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const VersionApp(),
          ],
        ),
        ),
      ),
    );
  }

  /// Carte hero marine SaamBiz : icone de marque, message clair et deux boutons
  /// d'action directe.
  Widget _carteBienvenue() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColor.kPrimary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColor.kWhite,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(
              'assets/images/picto_navy.png',
              width: 32,
              height: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bienvenue sur SaamBiz',
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColor.kWhite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connectez-vous pour commander, retrouver vos favoris, échanger avec les boutiques et suivre vos livraisons.',
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 13.5,
              height: 1.45,
              color: AppColor.kWhite.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRouter.loginRoute),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kSecondary,
                    foregroundColor: AppColor.kPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Se connecter'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(AppRouter.profileChoiceRoute),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColor.kPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontFamily: kPolice,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kPrimary,
                      ),
                    ),
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
