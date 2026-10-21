import 'package:flutter/material.dart';

import '../theme/app_color.dart';

/// Espace à laisser en bas des onglets : la barre de navigation flotte
/// au-dessus du contenu, qui défile dessous.
const double kEspaceBarreBas = 104;

/// Barre de navigation flottante : pilule blanche, filet gris, ombre
/// discrète, pastille bleu clair sous l'onglet actif. À utiliser avec
/// `extendBody: true` sur le Scaffold.
class BarreNavigationVerre extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> destinations;

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
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColor.kWhite,
                border: Border.all(color: AppColor.kLine),
              ),
              child: NavigationBarTheme(
                data: NavigationBarTheme.of(context).copyWith(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  height: 66,
                  indicatorColor: AppColor.kPrimaryLight,
                  indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  iconTheme: WidgetStateProperty.resolveWith(
                    (states) => IconThemeData(
                      size: 22,
                      color: states.contains(WidgetState.selected)
                          ? AppColor.kPrimary
                          : AppColor.kGrayscale30,
                    ),
                  ),
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => TextStyle(
                      fontSize: 11,
                      fontWeight: states.contains(WidgetState.selected)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: states.contains(WidgetState.selected)
                          ? AppColor.kPrimary
                          : AppColor.kGrayscale30,
                    ),
                  ),
                ),
                // La barre est déjà au-dessus de la zone système : sans cela,
                // NavigationBar ajouterait une seconde marge en bas.
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    destinations: destinations,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
