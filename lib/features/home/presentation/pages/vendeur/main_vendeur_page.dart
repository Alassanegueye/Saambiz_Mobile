import 'package:flutter/material.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';

import '../../../../../core/theme/app_color.dart';
import '../../../../../core/widgets/barre_navigation_verre.dart';
import 'home_page.dart';
import 'profil_page.dart';
import '../../../../commande/presentation/pages/vendeur_commandes_page.dart';
import '../../../../vendeur/presentation/pages/mes_produits_page.dart';
import '../../../../promotions/presentation/pages/mes_promotions_page.dart';

/// Espace vendeur : tableau de bord, commandes, produits, promotions et
/// compte, sous la barre de navigation flottante.
class MainVendeurPage extends StatefulWidget {
  final User? user;
  const MainVendeurPage({super.key, this.user});

  @override
  State<MainVendeurPage> createState() => _MainVendeurPageState();
}

class _MainVendeurPageState extends State<MainVendeurPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    HomePage(user: widget.user),
    const VendeurCommandesPage(),
    const MesProduitsPage(),
    const MesPromotionsPage(),
    ProfilPage(user: widget.user),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Commandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag_rounded),
            label: 'Produits',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer_rounded),
            label: 'Promos',
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
