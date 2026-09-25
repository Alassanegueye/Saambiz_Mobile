import 'package:saambiz/core/theme/app_color.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndPrivacyText extends StatefulWidget {
  const TermsAndPrivacyText({
    super.key,
    required this.texteInitial,
    required this.texteTermes,
    required this.texteConnecteur,
    required this.texteConditions,
    this.couleurTermes,
    this.onTapTermes,
    this.onTapConditions,
  });

  final String texteInitial;
  final String texteTermes;
  final String texteConnecteur;
  final String texteConditions;
  final Color? couleurTermes;
  final VoidCallback? onTapTermes;
  final VoidCallback? onTapConditions;

  @override
  State<TermsAndPrivacyText> createState() => _TermsAndPrivacyTextState();
}

class _TermsAndPrivacyTextState extends State<TermsAndPrivacyText> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _conditionsRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTapTermes;
    _conditionsRecognizer = TapGestureRecognizer()
      ..onTap = widget.onTapConditions;
  }

  @override
  void didUpdateWidget(covariant TermsAndPrivacyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _termsRecognizer.onTap = widget.onTapTermes;
    _conditionsRecognizer.onTap = widget.onTapConditions;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _conditionsRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final styleParDefaut = GoogleFonts.plusJakartaSans(
      color: AppColor.kGrayscale40,
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );
    final styleLien = GoogleFonts.plusJakartaSans(
      color: widget.couleurTermes ?? AppColor.kGrayscaleDark100,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: styleParDefaut,
        children: [
          TextSpan(text: widget.texteInitial),
          TextSpan(
            text: widget.texteTermes,
            style: styleLien,
            recognizer: _termsRecognizer,
          ),
          TextSpan(text: widget.texteConnecteur),
          TextSpan(
            text: widget.texteConditions,
            style: styleLien,
            recognizer: _conditionsRecognizer,
          ),
        ],
      ),
    );
  }
}
