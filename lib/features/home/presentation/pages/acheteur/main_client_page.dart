import 'package:flutter/material.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';

import '../../../../../core/theme/app_color.dart';
import '../../../../../core/widgets/barre_navigation_verre.dart';
import 'accueil_boutiques_page.dart';
import 'profil_page.dart';
import 'guest_profil_page.dart';
import '../../../../commande/presentation/pages/mes_commandes_page.dart';
import '../../../../favoris/presentation/pages/favoris_page.dart';
import '../../../../catalogue/presentation/pages/categories_page.dart';
import '../../../../../core/routes/app_router.dart';
import '../../../../../core/widgets/ui_kit.dart';

/// Onglet demandé depuis une page fille (« Découvrir les boutiques » d'une
/// liste de commandes vide, par exemple) : 0 accueil, 1 catégories,
/// 2 favoris, 3 commandes, 4 compte.
final ValueNotifier<int?> ongletAcheteurDemande = ValueNotifier<int?>(null);

/// Espace acheteur : cinq onglets sous une barre de navigation flottante
/// (même construction que l'application Yobante Boutique).
class MainAcheteurPage extends StatefulWidget {
  final User? user;
  final bool isGuest;
  const MainAcheteurPage({super.key, this.user, this.isGuest = false});

  @override
  State<MainAcheteurPage> createState() => _MainAcheteurPageState();
}

class _MainAcheteurPageState extends State<MainAcheteurPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    ongletAcheteurDemande.addListener(_surOngletDemande);
  }

  @override
  void dispose() {
    ongletAcheteurDemande.removeListener(_surOngletDemande);
    super.dispose();
  }

  void _surOngletDemande() {
    final i = ongletAcheteurDemande.value;
    if (i == null || !mounted) return;
    ongletAcheteurDemande.value = null;
    setState(() => _selectedIndex = i);
  }

  late final List<Widget> _pages = [
    // Accueil orienté boutiques, personnalisé par le serveur.
    AccueilBoutiquesPage(user: widget.user, isGuest: widget.isGuest),
    const CategoriesPage(),
    // Les favoris (boutiques suivies) demandent un compte.
    widget.isGuest ? const _FavorisInvite() : const FavorisPage(),
    MesCommandesPage(isGuest: widget.isGuest),
    widget.isGuest ? const GuestProfilPage() : ProfilPage(user: widget.user),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      // Le contenu défile sous la barre flottante.
      extendBody: true,
      body: KeyedSubtree(
        key: ValueKey(_selectedIndex),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BarreNavigationVerre(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Catégories',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favoris',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Commandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Compte',
          ),
        ],
      ),
    );
  }
}

class _FavorisInvite extends StatelessWidget {
  const _FavorisInvite();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: EtatVide(
              icone: Icons.favorite_border_rounded,
              titre: 'Vos boutiques préférées',
              message: 'Connectez-vous pour suivre des boutiques et recevoir leurs nouveautés et promotions en premier.',
              action: 'Se connecter',
              onAction: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
            ),
          ),
        ),
      ),
    );
  }
}
