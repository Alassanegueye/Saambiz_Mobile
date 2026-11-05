import 'package:flutter/material.dart';

/// Ferme le clavier quand on touche une zone non interactive de l'écran.
///
/// Sur mobile, Flutter garde le champ actif quand on touche à côté, et le
/// clavier d'iOS n'a pas toujours de touche pour se rabattre. Les éléments
/// interactifs (champs, boutons, listes qu'on fait défiler) gardent la priorité
/// sur ce détecteur : passer d'un champ à l'autre ou afficher le mot de passe
/// laisse donc le clavier ouvert.
class FermetureClavier extends StatelessWidget {
  final Widget child;

  const FermetureClavier({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
