import 'package:saambiz/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:saambiz/core/theme/police.dart';

class CustomRichText extends StatelessWidget {
  const CustomRichText({
    super.key,
    required this.textePrincipal,
    required this.texteSecondaireCliquable,
    required this.onTap,
    required this.styleTexteSecondaire,
  });

  final String textePrincipal, texteSecondaireCliquable;
  final TextStyle styleTexteSecondaire;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: textePrincipal,
          style: TextStyle(fontFamily: kPolice, 
            color: AppColor.kGrayscale40,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          children: <TextSpan>[
            TextSpan(
              text: texteSecondaireCliquable,
              style: styleTexteSecondaire,
            ),
          ],
        ),
      ),
    );
  }
}
