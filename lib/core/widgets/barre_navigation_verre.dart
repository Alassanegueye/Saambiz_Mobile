import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_color.dart';
import '../theme/police.dart';

/// Espace a laisser en bas des listes d'un onglet, au-dessus de la barre flottante.
const double kEspaceBarreBas = 96;

/// Barre de navigation du bas en « liquide glace » (verre depoli / frosted glass),
/// flottant au-dessus du contenu comme sur la maquette de reference.
class BarreNavigationVerre extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  const BarreNavigationVerre({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: AppColor.kPrimary.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _ItemNavigationVerre(
                        destination: destinations[i],
                        selectionne: i == selectedIndex,
                        onTap: () {
                          if (i != selectedIndex) {
                            HapticFeedback.selectionClick();
                            onDestinationSelected(i);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemNavigationVerre extends StatelessWidget {
  final NavigationDestination destination;
  final bool selectionne;
  final VoidCallback onTap;

  const _ItemNavigationVerre({
    required this.destination,
    required this.selectionne,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Teinte bleue de l'application pour l'onglet actif
    const couleurActive = AppColor.kPrimary;
    final fondActif = AppColor.kPrimary.withValues(alpha: 0.10);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: selectionne ? fondActif : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconTheme(
              data: IconThemeData(
                size: 22,
                color: selectionne ? couleurActive : AppColor.kGrayscale40,
              ),
              child: selectionne
                  ? (destination.selectedIcon ?? destination.icon)
                  : destination.icon,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 10.5,
              fontWeight: selectionne ? FontWeight.w700 : FontWeight.w500,
              color: selectionne ? couleurActive : AppColor.kGrayscale40,
              letterSpacing: -0.2,
            ),
            child: Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
