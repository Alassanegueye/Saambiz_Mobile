import 'package:flutter/material.dart';

/// Étape « Avantages » de l'assistant du site : jusqu'à quatre, chacun avec
/// une icône choisie dans la liste.

class _C {
  static const navy      = Color(0xFF0D1B3D);
  static const navyLight = Color(0xFFE8EDF7);
  static const white     = Color(0xFFFFFFFF);
  static const border    = Color(0xFFE2E7F0);
  static const text      = Color(0xFF0D1B3D);
  static const muted     = Color(0xFF5B6C8A);
  static const danger    = Color(0xFFC94030);
}

// ── Brouillons ─────────────────────────────────────────────────────────

class AvantageBrouillon {
  String icone;
  final TextEditingController titre;
  final TextEditingController texte;

  AvantageBrouillon({required this.icone, String titre = '', String texte = ''})
      : titre = TextEditingController(text: titre),
        texte = TextEditingController(text: texte);

  void dispose() { titre.dispose(); texte.dispose(); }
}

/// Icônes des avantages — mêmes clés que le site et l'API.
const iconesAvantages = <String, (IconData, String)>{
  'livraison': (Icons.local_shipping_outlined, 'Livraison'),
  'paiement': (Icons.verified_user_outlined, 'Paiement sécurisé'),
  'service': (Icons.headset_mic_outlined, 'Service client'),
  'retours': (Icons.undo_rounded, 'Retours'),
  'qualite': (Icons.workspace_premium_outlined, 'Qualité'),
  'cadeau': (Icons.card_giftcard_outlined, 'Cadeau'),
  'promo': (Icons.percent_rounded, 'Promotion'),
  'garantie': (Icons.verified_outlined, 'Garantie'),
  'local': (Icons.location_on_outlined, 'Local'),
  'rapide': (Icons.bolt_outlined, 'Rapide'),
  'coeur': (Icons.favorite_border_rounded, 'Coup de cœur'),
  'etoile': (Icons.star_border_rounded, 'Étoile'),
};

const avantagesSuggeres = [
  ('livraison', 'Livraison rapide', 'Partout au Sénégal'),
  ('paiement', 'Paiement sécurisé', 'À la livraison'),
  ('service', 'Service client', 'Disponible 7j/7'),
  ('retours', 'Retours faciles', 'Sous 7 jours'),
  ('qualite', 'Produits de qualité', 'Sélectionnés avec soin'),
  ('garantie', 'Garantie', 'Produits garantis'),
];

// ── Morceaux communs ───────────────────────────────────────────────────

class _Titre extends StatelessWidget {
  final String titre;
  final String texte;
  const _Titre(this.titre, this.texte);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _C.text)),
          const SizedBox(height: 6),
          Text(texte, style: const TextStyle(fontSize: 13.5, color: _C.muted, height: 1.45)),
        ],
      );
}

class _ChampTexte extends StatelessWidget {
  final TextEditingController controleur;
  final String libelle;
  final String indication;
  final int max;
  final int lignes;
  const _ChampTexte(this.controleur, this.libelle, this.indication, {this.max = 70, this.lignes = 1});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: controleur,
          maxLength: max,
          maxLines: lignes,
          decoration: InputDecoration(
            labelText: libelle,
            hintText: indication,
            counterText: '',
            filled: true,
            fillColor: _C.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.border),
            ),
          ),
        ),
      );
}

class _Carte extends StatelessWidget {
  final Widget child;
  const _Carte({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: child,
      );
}

class _Vide extends StatelessWidget {
  final String texte;
  const _Vide(this.texte);
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Text(texte, style: const TextStyle(fontSize: 13, color: _C.muted, height: 1.45)),
      );
}

// ── Étape : avantages ──────────────────────────────────────────────────

class EtapeAvantages extends StatelessWidget {
  final List<AvantageBrouillon> avantages;
  final VoidCallback onChange;
  const EtapeAvantages({super.key, required this.avantages, required this.onChange});

  Future<void> _choisirIcone(BuildContext context, AvantageBrouillon a) async {
    final cle = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 4,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: iconesAvantages.entries
              .map((e) => InkWell(
                    onTap: () => Navigator.of(context).pop(e.key),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(e.value.$1, color: a.icone == e.key ? _C.navy : _C.muted, size: 28),
                        const SizedBox(height: 4),
                        Text(e.value.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
    if (cle == null) return;
    a.icone = cle;
    onChange();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = avantagesSuggeres.where((s) => !avantages.any((a) => a.titre.text == s.$2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Titre('Vos avantages',
            'Ce qui rassure vos clients : livraison, paiement, service… Jusqu\'à 4, '
            'chacun avec son icône. Aucun avantage, pas de bandeau.'),
        if (avantages.isEmpty) const _Vide('Aucun avantage pour l\'instant.'),
        for (var i = 0; i < avantages.length; i++)
          _Carte(
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => _choisirIcone(context, avantages[i]),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(color: _C.navyLight, borderRadius: BorderRadius.circular(12)),
                        child: Icon(iconesAvantages[avantages[i].icone]?.$1 ?? Icons.star_border_rounded, color: _C.navy),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Touchez l\'icône pour la changer', style: TextStyle(fontSize: 12, color: _C.muted))),
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: () {
                        avantages.removeAt(i);
                        onChange();
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: _C.danger),
                    ),
                  ],
                ),
                _ChampTexte(avantages[i].titre, 'Titre', 'Livraison rapide', max: 40),
                _ChampTexte(avantages[i].texte, 'Précision (facultatif)', 'Partout au Sénégal', max: 60),
              ],
            ),
          ),
        if (avantages.length < 4) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in suggestions)
                ActionChip(
                  avatar: Icon(iconesAvantages[s.$1]!.$1, size: 18, color: _C.navy),
                  label: Text(s.$2),
                  onPressed: () {
                    avantages.add(AvantageBrouillon(icone: s.$1, titre: s.$2, texte: s.$3));
                    onChange();
                  },
                ),
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 18, color: _C.navy),
                label: const Text('Un autre'),
                onPressed: () {
                  avantages.add(AvantageBrouillon(icone: 'etoile'));
                  onChange();
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}
