import 'package:flutter/material.dart';

/// Un formulaire dont le bouton d'action n'est PAS collé en bas de l'écran.
///
/// ## Le défaut qu'il corrige
///
/// Les écrans de saisie étaient bâtis ainsi :
///
/// ```dart
/// Column([ Expanded(ListView(...champs...)), bouton ])
/// ```
///
/// Le bouton, collé en bas, remonte au-dessus du clavier dès qu'il s'ouvre.
/// Il ne reste alors aux champs qu'une bande étroite, prise entre l'en-tête
/// et ce bouton — et un champ à plusieurs lignes n'y tient pas : son bas est
/// coupé net. Sur « Nouvelle promotion », on écrivait son message sans voir
/// ce qu'on écrivait.
///
/// Le bouton ne cachait pas le champ : il lui prenait sa place.
///
/// ## Ce que fait ce widget
///
/// Tout défile d'un seul tenant, bouton compris — la mise en page de l'écran
/// de connexion, qui n'a jamais eu ce défaut. Le clavier ouvert, toute la
/// hauteur restante revient au champ qu'on remplit.
///
/// `minHeight` garde le bouton en bas de l'écran tant qu'il y a de la place :
/// clavier fermé, RIEN NE CHANGE pour l'utilisateur. La différence
/// n'apparaît qu'une fois le clavier ouvert.
class FormulaireDefilant extends StatelessWidget {
  /// Le contenu du formulaire, de haut en bas.
  final List<Widget> enfants;

  /// L'action principale, posée sous le contenu.
  final Widget bouton;

  /// Marge autour du contenu (le bouton a la sienne).
  final EdgeInsetsGeometry padding;

  /// Marge autour du bouton.
  final EdgeInsetsGeometry paddingBouton;

  /// Posé sur le défilement, pour les écrans qui en ont un.
  final ScrollController? controleur;

  const FormulaireDefilant({
    super.key,
    required this.enfants,
    required this.bouton,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 8),
    this.paddingBouton = const EdgeInsets.fromLTRB(16, 8, 16, 12),
    this.controleur,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) => SingleChildScrollView(
        controller: controleur,
        // Un glissé vers le bas ferme le clavier, en plus du toucher à côté
        // (voir `FermerClavierAuToucher`).
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          // Au moins la hauteur visible : sans cela le bouton remonterait
          // coller au dernier champ sur un formulaire court.
          constraints: BoxConstraints(minHeight: contraintes.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: enfants,
                  ),
                ),
                // Pousse le bouton en bas quand le contenu ne remplit pas
                // l'écran ; ne prend aucune place quand il le remplit.
                const Spacer(),
                SafeArea(
                  top: false,
                  child: Padding(padding: paddingBouton, child: bouton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
