import 'package:flutter/material.dart';

/// Logo affiché quand une boutique n'a pas encore le sien : un sac doré sur
/// un fond bleu marine en dégradé, aux couleurs de SaamBiz. Il remplit son
/// parent ; [rayon] arrondit ses angles quand le parent ne les découpe pas.
class LogoBoutiqueParDefaut extends StatelessWidget {
  final double? rayon;
  const LogoBoutiqueParDefaut({super.key, this.rayon});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, contraintes) {
      final cote = contraintes.biggest.shortestSide;
      final taille = cote.isFinite && cote > 0 ? cote : 48.0;
      return Container(
        width: contraintes.hasBoundedWidth ? double.infinity : taille,
        height: contraintes.hasBoundedHeight ? double.infinity : taille,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: rayon == null ? null : BorderRadius.circular(rayon!),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A4C96), Color(0xFF0D1B3D)],
          ),
        ),
        child: Icon(Icons.shopping_bag_rounded, size: taille * 0.48, color: const Color(0xFFF2B705)),
      );
    });
  }
}
