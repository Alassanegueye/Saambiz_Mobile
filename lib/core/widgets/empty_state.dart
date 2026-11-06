import 'package:flutter/material.dart';

import 'ui_kit.dart';

/// État vide réutilisable pour toutes les pages liste : même dessin que
/// [EtatVide] (grande pastille bleu pâle, titre, texte, bouton).
///
/// [scrollable] = true  → enrobe dans un ListView (pour remplacer un ListView vide)
/// [scrollable] = false → Centre le contenu directement (pour Sliver ou Expanded)
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  /// Conservé pour les écrans qui le passent encore ; la charte n'a plus
  /// qu'une couleur d'état vide.
  final Color? accentColor;
  final bool scrollable;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionLabel,
    this.accentColor,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final contenu = EtatVide(
      icone: icon,
      titre: title,
      message: subtitle,
      action: actionLabel,
      onAction: onAction,
    );

    if (!scrollable) return Center(child: contenu);

    return LayoutBuilder(
      builder: (context, contraintes) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: contraintes.maxHeight.isFinite
                  ? contraintes.maxHeight * 0.85
                  : 0,
            ),
            child: Center(child: contenu),
          ),
        ],
      ),
    );
  }
}
