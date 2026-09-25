import 'package:flutter/material.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';
import 'package:google_fonts/google_fonts.dart';
import 'accueil_boutiques_page.dart';
import 'produit_page.dart';
import 'profil_page.dart';
import 'guest_profil_page.dart';
import '../../../../commande/presentation/pages/mes_commandes_page.dart';
import '../../../../favoris/presentation/pages/favoris_page.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
class _C {
  static const green      = Color(0xFF1B3A6B);
  static const greenLight = Color(0xFFE8EEF7);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7F2);
  static const border     = Color(0xFFF0F4EC);
  static const label      = Color(0xFF9EAA94);
  static const inactive   = Color(0xFFC2CCBA);
}

// ─── Modèle d'un item de navigation ──────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool hasNotif;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.hasNotif = false,
  });
}

class MainAcheteurPage extends StatefulWidget {
  final User? user;
  final bool isGuest;
  const MainAcheteurPage({super.key, this.user, this.isGuest = false});

  @override
  State<MainAcheteurPage> createState() => _MainAcheteurPageState();
}

class _MainAcheteurPageState extends State<MainAcheteurPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // Animations par item
  late List<AnimationController> _itemCtrl;
  late List<Animation<double>>   _itemScale;
  late List<Animation<double>>   _labelFade;

  final List<_NavItem> _navItems = const [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    _NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Catégories',
    ),
    _NavItem(
      icon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
      label: 'Favoris',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Commandes',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      // Accueil orienté boutiques, personnalisé par le backend.
      // L'ancien fil produits reste dans home_page.dart, non branché.
      AccueilBoutiquesPage(user: widget.user, isGuest: widget.isGuest),
      ProduitPage(user: widget.user),
      const FavorisPage(),
      const MesCommandesPage(),
      widget.isGuest
          ? const GuestProfilPage()
          : ProfilPage(user: widget.user),
    ];

    _itemCtrl = List.generate(
      _navItems.length,
          (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 280),
      ),
    );

    _itemScale = _itemCtrl.map((ctrl) {
      return Tween<double>(begin: 1.0, end: 1.18).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOutBack),
      );
    }).toList();

    _labelFade = _itemCtrl.map((ctrl) {
      return CurvedAnimation(parent: ctrl, curve: Curves.easeOut);
    }).toList();

    // Activer le premier tab au démarrage
    _itemCtrl[0].forward();
  }

  @override
  void dispose() {
    for (final ctrl in _itemCtrl) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onTap(int index) {
    if (_selectedIndex == index) return;
    _itemCtrl[_selectedIndex].reverse();
    _itemCtrl[index].forward();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      extendBody: true, // pour que le contenu passe sous la nav bar arrondie
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  // ── Barre de navigation custom ─────────────────────────────────────────────
  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        border: Border(
          top: BorderSide(color: _C.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _navItems.length,
                  (i) => _buildNavItem(i),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item     = _navItems[index];
    final selected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _itemScale[index],
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 23,
                  color: selected ? _C.green : _C.inactive,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _C.green : _C.inactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}