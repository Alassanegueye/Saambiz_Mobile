import 'package:flutter/material.dart';

import '../theme/app_color.dart';

/// Libellé d'un champ obligatoire : le texte suivi d'un astérisque rouge.
///
/// À placer dans `InputDecoration.label` : contrairement à un simple texte
/// indicatif, il reste visible une fois le champ rempli.
class LibelleObligatoire extends StatelessWidget {
  final String texte;
  final TextStyle? style;

  const LibelleObligatoire(this.texte, {super.key, this.style});

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      text: texte,
      children: const [
        TextSpan(
          text: ' *',
          style: TextStyle(color: AppColor.kErreur),
        ),
      ],
    ),
    style: style,
    semanticsLabel: '$texte, obligatoire',
  );
}
