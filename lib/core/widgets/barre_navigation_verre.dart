import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_color.dart';

/// Espace à laisser en bas des listes d'un onglet. La barre est posée sous
/// le contenu (elle ne flotte plus) : une simple respiration suffit.
const double kEspaceBarreBas = 24;

/// Barre de navigation du bas : fond blanc, filet en haut, icône et libellé
/// sous chaque onglet. L'onglet actif : icône marine sur une pastille or
/// pâle, libellé marine.
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColor.kWhite,
        border: Border(top: BorderSide(color: AppColor.kLine)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarTheme.of(context).copyWith(
          backgroundColor: AppColor.kWhite,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          height: 66,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorColor: AppColor.kSecondaryLight,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected)
                  ? AppColor.kPrimary
                  : AppColor.kGrayscale40,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11.5,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? AppColor.kPrimary
                  : AppColor.kGrayscale40,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) {
            if (i != selectedIndex) HapticFeedback.selectionClick();
            onDestinationSelected(i);
          },
          destinations: destinations,
        ),
      ),
    );
  }
}
