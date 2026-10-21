import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Couleurs des promotions : orange sur fond pêche.
const Color kPromoFond = Color(0xFFFFF1E6);
const Color kPromoEncre = Color(0xFFEF7D22);

/// Compte à rebours jusqu'à la fin d'une promotion, mis à jour chaque
/// seconde. Disparaît de lui-même quand la promotion est terminée.
///
/// [compact] : une puce « 02:14:09 » pour les cartes produit ; sinon le bloc
/// « Fin de la promotion dans » avec jours, heures, minutes, secondes.
class CompteARebours extends StatefulWidget {
  final DateTime fin;
  final bool compact;
  final VoidCallback? onTermine;

  const CompteARebours({super.key, required this.fin, this.compact = false, this.onTermine});

  @override
  State<CompteARebours> createState() => _CompteAReboursState();
}

class _CompteAReboursState extends State<CompteARebours> {
  Timer? _minuteur;
  Duration _restant = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tic();
    _minuteur = Timer.periodic(const Duration(seconds: 1), (_) => _tic());
  }

  @override
  void didUpdateWidget(covariant CompteARebours ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.fin != widget.fin) _tic();
  }

  void _tic() {
    final restant = widget.fin.difference(DateTime.now());
    if (restant <= Duration.zero) {
      _minuteur?.cancel();
      if (mounted) setState(() => _restant = Duration.zero);
      widget.onTermine?.call();
      return;
    }
    if (mounted) setState(() => _restant = restant);
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  String _deux(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    if (_restant <= Duration.zero) return const SizedBox.shrink();
    final j = _restant.inDays;
    final h = _restant.inHours % 24;
    final m = _restant.inMinutes % 60;
    final s = _restant.inSeconds % 60;

    if (widget.compact) {
      final texte = j > 0 ? '${j}j ${_deux(h)}h ${_deux(m)}m' : '${_deux(h)}:${_deux(m)}:${_deux(s)}';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: kPromoEncre, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, size: 11, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              texte,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }

    Widget caseTemps(String valeur, String unite) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: valeur,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: kPromoEncre,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              TextSpan(
                text: unite,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: kPromoEncre),
              ),
            ]),
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kPromoFond, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: kPromoEncre),
              const SizedBox(width: 6),
              Text(
                'Fin de la promotion dans',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: kPromoEncre),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (j > 0) caseTemps('$j', ' j'),
              caseTemps(_deux(h), ' h'),
              caseTemps(_deux(m), ' min'),
              caseTemps(_deux(s), ' s'),
            ],
          ),
        ],
      ),
    );
  }
}
