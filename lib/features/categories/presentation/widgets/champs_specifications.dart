import 'package:flutter/material.dart';

import '../../data/specification.dart';

/// Options et caractéristiques du produit, remplies par le vendeur lui-même.
///
/// La catégorie suggère des cases bien nommées (« Tailles », « Parfums »,
/// « Formats »…) ; le vendeur y tape ses valeurs (« XL », « Bissap »,
/// « 1,5 L ») et peut ajouter ses propres options. Rien n'est obligatoire :
/// publier un produit doit rester rapide.
///
/// Les valeurs sont un `Map` { clé: valeur } : un tableau pour les options
/// que le client choisit, un texte pour une simple information.
class ChampsSpecifications extends StatefulWidget {
  final List<SpecificationProduit> specifications;
  final Map<String, dynamic> valeurs;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, String> erreurs;

  const ChampsSpecifications({
    super.key,
    required this.specifications,
    required this.valeurs,
    required this.onChanged,
    this.erreurs = const {},
  });

  @override
  State<ChampsSpecifications> createState() => _ChampsSpecificationsState();
}

class _ChampsSpecificationsState extends State<ChampsSpecifications> {
  static const _navy = Color(0xFF0D1B3D);
  static const _border = Color(0xFFE2E7F0);
  static const _sub = Color(0xFF6B7891);

  final _nouveauNom = TextEditingController();

  @override
  void dispose() {
    _nouveauNom.dispose();
    super.dispose();
  }

  void _maj(String cle, dynamic valeur) {
    widget.onChanged({...widget.valeurs, cle: valeur});
  }

  void _retirer(String cle) {
    final copie = Map<String, dynamic>.from(widget.valeurs)..remove(cle);
    widget.onChanged(copie);
  }

  /// Suggestions de la catégorie + options ajoutées par le vendeur.
  List<SpecificationProduit> get _champs {
    final connues = widget.specifications.map((s) => s.cle).toSet();
    final ajoutees = widget.valeurs.keys
        .where((cle) => !connues.contains(cle))
        .map((cle) => SpecificationProduit(
              cle: cle,
              libelle: cle,
              type: widget.valeurs[cle] is List ? 'variantes' : 'texte',
              libre: true,
            ));
    return [...widget.specifications, ...ajoutees];
  }

  bool _estAjoutee(String cle) => !widget.specifications.any((s) => s.cle == cle);

  void _ajouterOption() {
    final nom = _nouveauNom.text.trim();
    if (nom.isEmpty) return;
    final existe = _champs.any((c) =>
        c.cle.toLowerCase() == nom.toLowerCase() ||
        c.libelle.toLowerCase() == nom.toLowerCase());
    if (!existe) _maj(nom.length > 40 ? nom.substring(0, 40) : nom, <String>[]);
    _nouveauNom.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text.rich(
            TextSpan(
              text: 'Options du produit',
              children: [
                TextSpan(
                  text: '  (facultatif)',
                  style: TextStyle(fontWeight: FontWeight.w500, color: _sub, fontSize: 12.5),
                ),
              ],
            ),
            style: TextStyle(fontWeight: FontWeight.w700, color: _navy, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ce que le client pourra choisir : tailles, couleurs, parfums, formats…',
            style: TextStyle(fontSize: 12.5, color: _sub, height: 1.4),
          ),
          const SizedBox(height: 14),
          for (final s in _champs) ...[
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: s.libelle,
                      children: [
                        if (s.obligatoire)
                          const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _navy),
                  ),
                ),
                if (_estAjoutee(s.cle))
                  GestureDetector(
                    onTap: () => _retirer(s.cle),
                    child: const Text('Retirer',
                        style: TextStyle(fontSize: 12, color: _sub, decoration: TextDecoration.underline)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _champ(s),
            if (widget.erreurs[s.cle] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(widget.erreurs[s.cle]!,
                    style: const TextStyle(fontSize: 12, color: Colors.red)),
              ),
            const SizedBox(height: 14),
          ],
          // Le vendeur ajoute ses propres options (« Saveur », « Pointure enfant »).
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nouveauNom,
                  maxLength: 40,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _ajouterOption(),
                  decoration: _decoration('Autre option (ex. Saveur)'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _ajouterOption,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ajouter'),
                style: TextButton.styleFrom(foregroundColor: _navy),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _champ(SpecificationProduit s) {
    final v = widget.valeurs[s.cle];
    switch (s.type) {
      case 'variantes':
      case 'liste':
        return _Valeurs(
          spec: s,
          valeurs: _enListe(v),
          onChanged: (liste) => _maj(s.cle, liste),
        );
      case 'choix':
        return DropdownButtonFormField<String>(
          key: ValueKey('choix-${s.cle}'),
          initialValue: s.options.contains(v) ? v as String : null,
          isExpanded: true,
          decoration: _decoration('Choisir'),
          items: s.options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (o) => _maj(s.cle, o),
        );
      case 'oui_non':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: v == true || v == 'true',
          activeThumbColor: _navy,
          title: const Text('Oui', style: TextStyle(fontSize: 13)),
          onChanged: (b) => _maj(s.cle, b),
        );
      case 'nombre':
        return TextFormField(
          key: ValueKey('nombre-${s.cle}'),
          initialValue: v?.toString() ?? '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _decoration('', suffixe: s.unite),
          onChanged: (t) => _maj(s.cle, num.tryParse(t.replaceAll(',', '.')) ?? t),
        );
      default:
        return TextFormField(
          key: ValueKey('texte-${s.cle}'),
          initialValue: v?.toString() ?? '',
          maxLength: 200,
          decoration: _decoration(s.aide ?? ''),
          onChanged: (t) => _maj(s.cle, t.trim()),
        );
    }
  }

  /// Une « liste » revient du serveur en texte « a, b » : on la redécoupe.
  static List<String> _enListe(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.trim().isNotEmpty) {
      return v.split(RegExp(r',\s+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  static InputDecoration _decoration(String hint, {String? suffixe}) => InputDecoration(
        hintText: hint.isEmpty ? null : hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9AA5B8)),
        suffixText: suffixe,
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _navy),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
      );
}

/// Valeurs d'une option : propositions de l'admin (s'il y en a) à cocher,
/// et un champ pour taper les siennes. Une valeur se retire d'un appui.
class _Valeurs extends StatefulWidget {
  final SpecificationProduit spec;
  final List<String> valeurs;
  final ValueChanged<List<String>> onChanged;

  const _Valeurs({required this.spec, required this.valeurs, required this.onChanged});

  @override
  State<_Valeurs> createState() => _ValeursState();
}

class _ValeursState extends State<_Valeurs> {
  static const _navy = Color(0xFF0D1B3D);
  static const _tint = Color(0xFFEEF3FC);
  static const _border = Color(0xFFE2E7F0);

  final _saisie = TextEditingController();

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  bool _coche(String o) => widget.valeurs.any((v) => v.toLowerCase() == o.toLowerCase());

  void _basculer(String o) {
    widget.onChanged(_coche(o)
        ? widget.valeurs.where((v) => v.toLowerCase() != o.toLowerCase()).toList()
        : [...widget.valeurs, o]);
  }

  /// « S, M, L » tapé d'un coup donne trois valeurs ; « 1,5 L » en reste une.
  void _ajouter() {
    final nouvelles = _saisie.text
        .split(RegExp(r',(?!\d)'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !_coche(e))
        .toList();
    if (nouvelles.isNotEmpty) widget.onChanged([...widget.valeurs, ...nouvelles]);
    _saisie.clear();
  }

  Widget _puce(String texte, {required bool active, bool retirable = false}) {
    return InkWell(
      onTap: () => _basculer(texte),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _tint : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? _navy : _border, width: active ? 1.4 : 1.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texte,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: _navy,
              ),
            ),
            if (retirable) ...[
              const SizedBox(width: 4),
              const Icon(Icons.close_rounded, size: 14, color: _navy),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.spec.options;
    final tapees = widget.valeurs
        .where((v) => !options.any((o) => o.toLowerCase() == v.toLowerCase()))
        .toList();
    final peutTaper = widget.spec.libre || options.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (options.isNotEmpty || tapees.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final o in options) _puce(o, active: _coche(o)),
              for (final v in tapees) _puce(v, active: true, retirable: true),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (peutTaper)
          TextField(
            controller: _saisie,
            maxLength: 80,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _ajouter(),
            onTapOutside: (_) => _ajouter(),
            decoration: InputDecoration(
              hintText: widget.spec.aide ?? 'Tapez une valeur puis OK',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9AA5B8)),
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: _navy),
                tooltip: 'Ajouter',
                onPressed: _ajouter,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _navy),
              ),
            ),
          ),
      ],
    );
  }
}
