import 'package:flutter/widgets.dart';

/// Ferme le clavier quand on touche à côté d'un champ.
///
/// Pour le fermer, il fallait faire glisser la liste vers le bas — un geste
/// que peu de gens connaissent. On restait donc à taper avec la moitié de
/// l'écran prise par le clavier, sans savoir comment le renvoyer.
///
/// `translucent` et non `opaque` : le toucher est VU au passage, puis
/// continue sa route. Un bouton, une case à cocher, un autre champ font
/// exactement ce qu'ils faisaient — seuls les touchers qui ne rencontrent
/// rien ferment le clavier.
///
/// `unfocus` ne fait rien quand aucun champ n'a le focus : poser ce widget
/// sur un écran sans saisie ne coûte rien et ne change rien.
class FermerClavierAuToucher extends StatelessWidget {
  final Widget child;
  const FermerClavierAuToucher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
