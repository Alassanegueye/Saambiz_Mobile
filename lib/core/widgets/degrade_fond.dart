import 'package:flutter/material.dart';

/// Décoration d'arrière-plan avec un dégradé bleu très subtil dans le 1/4
/// supérieur de l'écran, le reste (3/4 inférieur) étant entièrement blanc pur.
BoxDecoration decorationFondSubtil() {
  return const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0.0, 0.22, 1.0],
      colors: [
        Color(0xFFE8EFFB), // Lueur bleue très douce en haut (1/4 haut)
        Colors.white, // Transition douce vers le blanc
        Colors.white, // 3/4 inférieur en blanc pur
      ],
    ),
  );
}

/// Enveloppe de page avec fond en dégradé subtil en haut et blanc en bas.
class FondDegradeSubtil extends StatelessWidget {
  final Widget child;

  const FondDegradeSubtil({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: decorationFondSubtil(),
      child: child,
    );
  }
}
