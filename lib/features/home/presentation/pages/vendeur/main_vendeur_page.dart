import 'package:saambiz/core/widgets/onglets_conserves.dart';
import 'package:flutter/material.dart';
import 'package:saambiz/core/services/fcm_service.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';

import '../../../../../core/theme/app_color.dart';
import '../../../../../core/widgets/barre_navigation_verre.dart';
import 'home_page.dart';
import '../../../../commande/presentation/pages/vendeur_commandes_page.dart';
import '../../../../vendeur/presentation/pages/mes_produits_page.dart';
import '../../../../promotions/presentation/pages/mes_promotions_page.dart';
import '../../../../vitrine/presentation/pages/boutique_page.dart';

/// Espace vendeur : tableau de bord, commandes, boutique, produits et
/// promotions, barre de navigation en bas d'écran.
///
/// Le compte n'est plus un onglet : il s'ouvre depuis l'avatar, en haut de
/// l'accueil. La place libérée revient à « Boutique », au centre, parce que
/// c'est là que le vendeur configure désormais sa boutique en ligne : mise
/// en ligne du site, composition des sections, rangement de ses produits.
class MainVendeurPage extends StatefulWidget {
  final User? user;
  const MainVendeurPage({super.key, this.user});

  @override
  State<MainVendeurPage> createState() => _MainVendeurPageState();
}

class _MainVendeurPageState extends State<MainVendeurPage> {
  /// Position de « Produits » dans la barre. Nommée plutôt qu'écrite en
  /// clair : la page Boutique y renvoie, et un onglet inséré un jour de plus
  /// ne doit pas envoyer le vendeur sur un écran au hasard.
  static const int _ongletProduits = 3;

  int _selectedIndex = 0;

  void _ouvrirOnglet(int i) => setState(() => _selectedIndex = i);

  @override
  void initState() {
    super.initState();
    // Notifications push : autorisation et jeton de l'appareil.
    WidgetsBinding.instance.addPostFrameCallback((_) => FcmService.init());
  }

  late final List<Widget> _pages = [
    HomePage(user: widget.user, ouvrirOnglet: _ouvrirOnglet),
    const VendeurCommandesPage(),
    // Une section ne se remplit qu'avec des produits déjà créés : la page
    // Boutique doit donc pouvoir renvoyer vers « Produits ».
    BoutiquePage(ouvrirProduits: () => _ouvrirOnglet(_ongletProduits)),
    const MesProduitsPage(),
    const MesPromotionsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColor.kBackground,
      body: OngletsConserves(index: _selectedIndex, pages: _pages),
      bottomNavigationBar: BarreNavigationVerre(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _ouvrirOnglet,
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
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Boutique',
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
        ],
      ),
    );
  }
}
