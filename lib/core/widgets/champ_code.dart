import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/police.dart';

/// Saisie d'un code à usage unique en cases séparées (une par chiffre).
///
/// Avance d'une case à chaque chiffre, recule avec « retour » sur une case
/// vide, et accepte le collage ou le remplissage automatique du code complet.
class ChampCode extends StatefulWidget {
  final int longueur;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onComplet;
  final bool autofocus;
  final bool erreur;

  const ChampCode({
    super.key,
    this.longueur = 6,
    this.onChanged,
    this.onComplet,
    this.autofocus = false,
    this.erreur = false,
  });

  @override
  State<ChampCode> createState() => _ChampCodeState();
}

class _ChampCodeState extends State<ChampCode> {
  static const _navy = Color(0xFF01154B);
  static const _navyTint = Color(0xFFF5F7FC);
  static const _surface = Color(0xFFF7F8FA);
  static const _border = Color(0xFFE6E9EF);
  static const _rouge = Color(0xFFE53935);

  late final List<TextEditingController> _ctrls = List.generate(
    widget.longueur,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _nodes = List.generate(
    widget.longueur,
    (_) => FocusNode(),
  );
  late final List<FocusNode> _rawNodes = List.generate(
    widget.longueur,
    (_) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nodes.first.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in [..._nodes, ..._rawNodes]) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  void _notifier() {
    setState(() {});
    widget.onChanged?.call(_code);
    if (_code.length == widget.longueur) {
      FocusScope.of(context).unfocus();
      widget.onComplet?.call(_code);
    }
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Collage ou remplissage automatique : on répartit les chiffres.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.longueur; i++) {
        _ctrls[i].text = i < digits.length ? digits[i] : '';
      }
      _notifier();
      return;
    }
    if (value.isNotEmpty && index < widget.longueur - 1) {
      _nodes[index + 1].requestFocus();
    }
    _notifier();
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Row(
        children: [
          for (var i = 0; i < widget.longueur; i++) ...[
            Expanded(child: _case(i)),
            if (i < widget.longueur - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _case(int i) {
    final rempli = _ctrls[i].text.isNotEmpty;
    final couleurBord = widget.erreur
        ? _rouge
        : (rempli ? _navy : _border);
    return SizedBox(
      height: 54,
      child: KeyboardListener(
        focusNode: _rawNodes[i],
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _ctrls[i].text.isEmpty &&
              i > 0) {
            _ctrls[i - 1].clear();
            _nodes[i - 1].requestFocus();
            _notifier();
          }
        },
        child: TextField(
          controller: _ctrls[i],
          focusNode: _nodes[i],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          autofillHints: i == 0 ? const [AutofillHints.oneTimeCode] : null,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
          onChanged: (v) => _onChanged(i, v),
          onTap: () => _ctrls[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _ctrls[i].text.length,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: rempli ? _navyTint : _surface,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: couleurBord, width: 1.4),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.erreur ? _rouge : _navy,
                width: 1.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
