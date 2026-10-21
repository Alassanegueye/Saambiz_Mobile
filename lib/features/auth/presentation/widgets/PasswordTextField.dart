import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PasswordTextField extends StatefulWidget {
  final String hintText;
  final double width, height;
  final TextEditingController controller;
  final BorderRadiusGeometry borderRadius;
  final FormFieldValidator<String>? validator;
  final TextStyle? style;
  final FocusNode? focusNode;

  const PasswordTextField({
    Key? key,
    required this.hintText,
    required this.height,
    required this.controller,
    required this.width,
    required this.borderRadius,
    this.validator,
    this.style,
    this.focusNode,
  }) : super(key: key);

  @override
  _PasswordTextFieldState createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  // Bordure complètement transparente — on désactive TOUT
  static const _noBorder = OutlineInputBorder(
    borderSide: BorderSide.none,
    borderRadius: BorderRadius.zero,
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      // On écrase le thème local pour supprimer toute couleur de focus Flutter
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: Colors.transparent,   // supprime le focus ring bleu/orange
          error: Colors.transparent,     // supprime le contour rouge d'erreur
        ),
      ),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: TextFormField(
          obscureText: _obscureText,
          controller: widget.controller,
          focusNode: widget.focusNode,
          style: widget.style ??
              GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0D1B3D),
              ),
          validator: widget.validator,
          cursorColor: const Color(0xFF0D1B3D), // curseur vert, cohérent
          decoration: InputDecoration(
            // On neutralise chaque état de bordure explicitement
            border:               _noBorder,
            enabledBorder:        _noBorder,
            focusedBorder:        _noBorder, // ← clé : élimine le ring orange
            errorBorder:          _noBorder,
            focusedErrorBorder:   _noBorder,
            disabledBorder:       _noBorder,
            filled: false,
            contentPadding: const EdgeInsets.only(
              right: 8,
              top: 14,
              bottom: 14,
            ),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureText = !_obscureText),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  key: ValueKey(_obscureText),
                  color: const Color(0xFF93A1B8),
                  size: 20,
                ),
              ),
            ),
            hintText: widget.hintText,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFC2CCBA),
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}