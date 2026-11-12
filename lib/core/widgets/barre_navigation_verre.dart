import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_color.dart';
import '../theme/police.dart';

/// Espace a laisser en bas des listes d'un onglet, au-dessus de la barre
/// flottante. Calé sur le cas le plus haut (Android avec ses trois boutons) :
/// le dernier élément d'une liste n'est jamais caché sous la barre.
const double kEspaceBarreBas = 128;

/// Hauteur de la barre d'onglets elle-même.
const double kHauteurBarreNavigation = 68;

/// Distance entre le bas de l'écran et la barre d'onglets, pour un même
/// rendu sur iPhone et sur Android :
/// - iPhone : l'indicateur d'accueil n'est qu'un trait, pas un bouton ; la
///   barre peut descendre sur sa zone au lieu de flotter au-dessus ;
/// - Android avec boutons (retour, accueil…) ou barre de gestes : la barre se
///   pose juste au-dessus, sans jamais les recouvrir ;
/// - aucune barre système : un petit écart fixe.
double basBarreNavigation(BuildContext context) {
  const ecart = 8.0;
  final systeme = MediaQuery.viewPaddingOf(context).bottom;
  if (systeme <= 0) return 12 + ecart;
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return math.max(systeme - 18, 8) + ecart;
  }
  return systeme + ecart;
}

/// Barre de navigation du bas en « liquide glace » (verre depoli / frosted glass),
/// flottant au-dessus du contenu comme sur la maquette de reference.
class BarreNavigationVerre extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  /// Conservé pour compatibilité : l'espace sous la barre est désormais
  /// calculé par [basBarreNavigation], le même pour clients et vendeurs.
  final double margeBas;

  const BarreNavigationVerre({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.margeBas = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, basBarreNavigation(context)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: kHauteurBarreNavigation,
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
