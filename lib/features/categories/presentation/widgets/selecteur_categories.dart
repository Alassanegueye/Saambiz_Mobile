import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../injection_container.dart';
import '../../data/categorie.dart';
import '../icones_categories.dart';

/// Choix des catégories d'une boutique : puces à cocher, 1 à [maximum].
///
/// La première cochée devient la catégorie principale (celle affichée sous
/// le nom de la boutique) ; elle est signalée par une étoile. Les valeurs
/// renvoyées sont des slugs, que le backend accepte tels quels.
class SelecteurCategories extends StatefulWidget {
  /// Slugs (ou noms, ou ids) déjà choisis.
  final List<String> initiales;
  final int maximum;
  final ValueChanged<List<String>> onChanged;
  final String? erreur;

  const SelecteurCategories({
    super.key,
    this.initiales = const [],
    this.maximum = 3,
    required this.onChanged,
    this.erreur,
  });

  @override
  State<SelecteurCategories> createState() => _SelecteurCategoriesState();
}

class _SelecteurCategoriesState extends State<SelecteurCategories> {
  static const _navy = Color(0xFF0D1B3D);
  static const _gold = Color(0xFFF2B705);
  // Sélection : même langage que le choix du profil (fond bleuté, bord marine).
  static const _tint = Color(0xFFEEF3FC);
  static const _border = Color(0xFFE2E7F0);
  static const _textLight = Color(0xFF8794AC);
  static const _erreur = Color(0xFFE53935);

  List<Categorie> _categories = kCategoriesSecours;
  final List<String> _choix = [];

  @override
  void initState() {
    super.initState();
    _appliquerInitiales(_categories);
    _charger();
  }

  Future<void> _charger() async {
    final liste = await CategoriesRemoteDataSource(sl<Dio>()).lister();
    if (!mounted) return;
    setState(() {
      _categories = liste;
      _choix.clear();
      _appliquerInitiales(liste);
    });
  }

  /// Les valeurs initiales peuvent être des noms ou des ids : on les ramène
  /// aux slugs de la liste chargée.
  void _appliquerInitiales(List<Categorie> liste) {
    for (final v in widget.initiales) {
      for (final c in liste) {
        if (c.correspond(v) && !_choix.contains(c.slug)) _choix.add(c.slug);
      }
    }
  }

  void _basculer(Categorie c) {
    setState(() {
      if (_choix.contains(c.slug)) {
        _choix.remove(c.slug);
      } else if (_choix.length < widget.maximum) {
        _choix.add(c.slug);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('${widget.maximum} catégories au maximum. Retirez-en une d\'abord.'),
          ));
        return;
      }
    });
    widget.onChanged(List.unmodifiable(_choix));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégories de la boutique',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: _navy),
        ),
        const SizedBox(height: 4),
        Text(
          'Choisissez 1 à ${widget.maximum} catégories. La première est la principale.',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _textLight),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in _categories) _puce(c),
          ],
        ),
        if (widget.erreur != null) ...[
          const SizedBox(height: 8),
          Text(widget.erreur!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _erreur)),
        ],
      ],
    );
  }

  Widget _puce(Categorie c) {
    final rang = _choix.indexOf(c.slug);
    final choisie = rang >= 0;
    return Semantics(
      button: true,
      selected: choisie,
      child: InkWell(
        onTap: () => _basculer(c),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: choisie ? _tint : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: choisie ? _navy : _border, width: choisie ? 1.6 : 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                rang == 0 ? Icons.star_rounded : iconeCategorie(c.icone),
                size: 16,
                color: rang == 0 ? _gold : _navy,
              ),
              const SizedBox(width: 6),
              Text(
                c.nom,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: _navy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
