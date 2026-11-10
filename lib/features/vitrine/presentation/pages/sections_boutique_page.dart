import 'package:saambiz/core/widgets/page_vendeur.dart';
import 'package:flutter/material.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/core/theme/police.dart';

import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../catalogue/presentation/widgets/produit_card.dart'
    show formaterPrix;
import '../../../home/data/models/produit_model.dart';
import '../../../vendeur/domain/usecases/get_mes_produits.dart';
import '../../domain/entities/vitrine.dart';

/// Palette locale, même convention que les autres écrans vendeur.
class _C {
  static const navy = Color(0xFF01154B);
  static const navyLight = Color(0xFFE8EDF7);
  static const gold = Color(0xFFFBB900);
  static const bg = Color(0xFFF7F9FC);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E7F0);
  static const muted = Color(0xFF5B6C8A);
  static const danger = Color(0xFFC62828);
  static const alerte = Color(0xFFB0850B);
}

/// Limites appliquées par le serveur. Les répéter ici n'est pas une
/// duplication gratuite : sans elles l'écran laisserait composer une
/// treizième section pour la voir disparaître silencieusement à
/// l'enregistrement.
const int maxSections = 12;
const int maxProduitsParSection = 60;
const int maxCaracteresTitre = 60;

/// Saisie du nom d'une section (création ou renommage). Partagée avec la
/// page Boutique, qui permet d'ajouter une section sans passer par cet écran.
Future<String?> demanderTitreSection(
  BuildContext context, {
  String initial = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _DialogueTitreSection(initial: initial),
  );
}

/// Le dialogue garde son propre contrôleur et le libère à sa disparition :
/// le libérer dès le retour de `showDialog` plantait l'animation de
/// fermeture, pendant laquelle le champ est encore affiché.
class _DialogueTitreSection extends StatefulWidget {
  final String initial;
  const _DialogueTitreSection({required this.initial});

  @override
  State<_DialogueTitreSection> createState() => _DialogueTitreSectionState();
}

class _DialogueTitreSectionState extends State<_DialogueTitreSection> {
  late final TextEditingController _controleur =
      TextEditingController(text: widget.initial);
  final _cleForm = GlobalKey<FormState>();

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  void _valider() {
    if (_cleForm.currentState!.validate()) {
      Navigator.of(context).pop(_controleur.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _C.white,
      title: Text(
        widget.initial.isEmpty ? 'Nouvelle section' : 'Renommer la section',
        style: TextStyle(fontFamily: kPolice, 
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _C.navy,
        ),
      ),
      content: Form(
        key: _cleForm,
        child: TextFormField(
          controller: _controleur,
          autofocus: true,
          maxLength: maxCaracteresTitre,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Nouveautés, Promos du mois…',
            helperText: 'Ce nom s\'affiche sur votre site.',
          ),
          validator: (v) => (v ?? '').trim().isEmpty
              ? 'Donnez un nom à cette section.'
              : null,
          onFieldSubmitted: (_) => _valider(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _C.navy),
          onPressed: _valider,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

/// Composition des rayons de la boutique.
///
/// Le vendeur n'entre aucun produit ici : il choisit parmi ceux qu'il a déjà
/// créés depuis « Produits ». C'est volontaire, et c'est aussi la règle du
/// serveur, qui écarte tout identifiant étranger à son catalogue. Un vendeur
/// sans produit est donc renvoyé vers « Produits » plutôt que laissé devant
/// une liste vide sans explication.
///
/// L'écran travaille sur une copie locale et ne rend la liste qu'au moment
/// d'enregistrer : on peut renommer, réordonner et se tromper sans qu'un
/// appel réseau parte à chaque geste.
class SectionsBoutiquePage extends StatefulWidget {
  final List<SectionBoutique> sections;

  /// Ouvre l'onglet « Produits ». Fourni par la page Boutique, qui seule
  /// sait comment atteindre les onglets voisins.
  final VoidCallback? ouvrirProduits;

  const SectionsBoutiquePage({
    super.key,
    required this.sections,
    this.ouvrirProduits,
  });

  @override
  State<SectionsBoutiquePage> createState() => _SectionsBoutiquePageState();
}

class _SectionsBoutiquePageState extends State<SectionsBoutiquePage> {
  late final List<SectionBoutique> _sections = [...widget.sections];

  List<ProduitModel> _produits = const [];
  bool _chargement = true;
  String? _erreur;

  /// Vrai dès qu'un geste a modifié la liste : sert à prévenir avant de
  /// quitter, et à n'activer « Enregistrer » que s'il y a quelque chose à
  /// enregistrer.
  bool _modifie = false;

  @override
  void initState() {
    super.initState();
    _chargerProduits();
  }

  Future<void> _chargerProduits() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    final r = await sl<GetMesProduits>()();
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _erreur = f.errorMessage;
        _chargement = false;
      }),
      (liste) => setState(() {
        _produits = liste;
        _chargement = false;
      }),
    );
  }

  ProduitModel? _produit(String id) {
    for (final p in _produits) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Les produits d'une section qui existent encore. Un produit supprimé
  /// depuis « Produits » laisse son identifiant dans la section : on ne le
  /// compte pas, sinon l'écran annoncerait « 4 produits » pour trois visibles.
  List<ProduitModel> _produitsDe(SectionBoutique s) =>
      s.produitIds.map(_produit).whereType<ProduitModel>().toList();

  Future<void> _ajouterSection() async {
    if (_sections.length >= maxSections) {
      _dire('Vous avez atteint $maxSections sections, le maximum.');
      return;
    }
    final titre = await _demanderTitre();
    if (titre == null) return;
    setState(() {
      _sections.add(SectionBoutique(titre: titre));
      _modifie = true;
    });
  }

  Future<void> _renommer(int i) async {
    final titre = await _demanderTitre(initial: _sections[i].titre);
    if (titre == null) return;
    setState(() {
      _sections[i] = _sections[i].copyWith(titre: titre);
      _modifie = true;
    });
  }

  /// Saisie du nom d'une section. Le titre est obligatoire côté serveur :
  /// on le refuse ici, avec le motif, plutôt que de laisser l'enregistrement
  /// échouer sur l'ensemble des sections pour un seul champ vide.
  Future<String?> _demanderTitre({String initial = ''}) =>
      demanderTitreSection(context, initial: initial);

  Future<void> _supprimer(int i) async {
    final section = _sections[i];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.white,
        title: Text(
          'Supprimer « ${section.titre} » ?',
          style: TextStyle(fontFamily: kPolice, 
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _C.navy,
          ),
        ),
        content: const Text(
          'La section disparaît de votre site. Vos produits, eux, ne sont '
          'pas supprimés : ils restent dans « Produits ».',
          style: TextStyle(color: _C.muted, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _C.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _sections.removeAt(i);
      _modifie = true;
    });
  }

  Future<void> _choisirProduits(int i) async {
    final choix = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => SelecteurProduits(
          titreSection: _sections[i].titre,
          produits: _produits,
          dejaChoisis: _sections[i].produitIds,
        ),
      ),
    );
    if (choix == null) return;
    setState(() {
      _sections[i] = _sections[i].copyWith(produitIds: choix);
      _modifie = true;
    });
  }

  void _dire(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  /// Rend la liste à la page Boutique, qui se charge de l'envoyer.
  void _enregistrer() {
    final vides = _sections.where((s) => s.produitIds.isEmpty).length;
    if (vides > 0) {
      _dire(
        vides == 1
            ? 'Une section sans produit ne s\'affichera pas sur votre site.'
            : '$vides sections sans produit ne s\'afficheront pas sur votre site.',
      );
    }
    Navigator.of(context).pop(_sections);
  }

  Future<bool> _confirmerSortie() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.white,
        title: Text(
          'Abandonner vos modifications ?',
          style: TextStyle(fontFamily: kPolice, 
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _C.navy,
          ),
        ),
        content: const Text(
          'Vos sections ne sont pas encore enregistrées.',
          style: TextStyle(color: _C.muted, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuer'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _C.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_modifie,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Capturé avant l'attente : après le dialogue, ce `context` n'est
        // plus garanti valide.
        final navigateur = Navigator.of(context);
        if (await _confirmerSortie()) navigateur.pop();
      },
      child: ScaffoldMarine(
        backgroundColor: _C.bg,
        appBar: AppBar(
          title: Text(
            'Sections de ma boutique',
            style: TextStyle(fontFamily: kPolice, 
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          actions: [
            if (!_chargement && _erreur == null && _produits.isNotEmpty)
              TextButton(
                onPressed: _modifie ? _enregistrer : null,
                child: Text(
                  'Enregistrer',
                  style: TextStyle(fontFamily: kPolice, 
                    color: _modifie ? const Color(0xFFFBB900) : Colors.white54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        body: _corps(),
      ),
    );
  }

  Widget _corps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: _C.navy));
    }

    if (_erreur != null) {
      return Center(
        child: EtatVide(
          icone: Icons.wifi_off_rounded,
          titre: 'Chargement impossible',
          message: _erreur,
          action: 'Réessayer',
          onAction: _chargerProduits,
        ),
      );
    }

    // La règle, rendue visible : une section se remplit avec des produits
    // existants, il faut donc en avoir créé au moins un.
    if (_produits.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: EtatVide(
            icone: Icons.inventory_2_outlined,
            titre: 'Créez d\'abord vos produits',
            message:
                'Une section se remplit avec des produits que vous avez déjà '
                'créés. Ajoutez-en depuis « Produits », puis revenez les '
                'ranger ici.',
            action: widget.ouvrirProduits == null ? null : 'Aller aux produits',
            onAction: widget.ouvrirProduits == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    widget.ouvrirProduits!();
                  },
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _sections.isEmpty ? _aucuneSection() : _listeSections(),
        ),
        _barreBas(),
      ],
    );
  }

  Widget _aucuneSection() => Center(
    child: SingleChildScrollView(
      child: EtatVide(
        icone: Icons.dashboard_customize_outlined,
        titre: 'Aucune section',
        message:
            'Rangez vos produits en sections — « Nouveautés », « Promos » — pour '
            'que vos clients s\'y retrouvent. Sans section, votre site '
            'affiche simplement tous vos produits.',
        action: 'Créer une section',
        onAction: _ajouterSection,
      ),
    ),
  );

  Widget _listeSections() => ReorderableListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    itemCount: _sections.length,
    // `onReorderItem` livre un index déjà corrigé du retrait de l'élément
    // déplacé : pas de décalage à refaire à la main.
    onReorderItem: (de, vers) => setState(() {
      _sections.insert(vers, _sections.removeAt(de));
      _modifie = true;
    }),
    itemBuilder: (context, i) {
      final s = _sections[i];
      return Padding(
        key: ValueKey('section-$i-${s.titre}'),
        padding: const EdgeInsets.only(bottom: 10),
        child: _CarteSection(
          position: i + 1,
          titre: s.titre,
          produits: _produitsDe(s),
          onRenommer: () => _renommer(i),
          onSupprimer: () => _supprimer(i),
          onChoisirProduits: () => _choisirProduits(i),
        ),
      );
    },
  );

  Widget _barreBas() {
    final complet = _sections.length >= maxSections;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              complet
                  ? '$maxSections sections, c\'est le maximum.'
                  : '${_sections.length} section${_sections.length > 1 ? 's' : ''} sur $maxSections',
              style: const TextStyle(color: _C.muted, fontSize: 12.5),
            ),
          ),
          OutlinedButton.icon(
            onPressed: complet ? null : _ajouterSection,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Section'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.navy,
              side: const BorderSide(color: _C.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une section dans la liste : son nom, ses produits en aperçu, ses actions.
class _CarteSection extends StatelessWidget {
  final int position;
  final String titre;
  final List<ProduitModel> produits;
  final VoidCallback onRenommer;
  final VoidCallback onSupprimer;
  final VoidCallback onChoisirProduits;

  const _CarteSection({
    required this.position,
    required this.titre,
    required this.produits,
    required this.onRenommer,
    required this.onSupprimer,
    required this.onChoisirProduits,
  });

  @override
  Widget build(BuildContext context) {
    final vide = produits.isEmpty;
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _C.navyLight,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$position',
                    style: TextStyle(fontFamily: kPolice, 
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _C.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: kPolice, 
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _C.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vide
                            ? 'Aucun produit — invisible sur le site'
                            : '${produits.length} produit${produits.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: vide ? _C.alerte : _C.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Renommer',
                  onPressed: onRenommer,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 19,
                    color: _C.muted,
                  ),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  onPressed: onSupprimer,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: _C.danger,
                  ),
                ),
              ],
            ),
          ),

          if (!vide)
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: produits.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _Vignette(produits[i], cote: 48),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: TextButton.icon(
              onPressed: onChoisirProduits,
              icon: Icon(
                vide ? Icons.add_rounded : Icons.tune_rounded,
                size: 18,
              ),
              label: Text(
                vide ? 'Choisir des produits' : 'Modifier les produits',
                style: TextStyle(fontFamily: kPolice, 
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: _C.navy),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vignette d'un produit, avec un repli quand l'image manque ou échoue.
class _Vignette extends StatelessWidget {
  final ProduitModel produit;
  final double cote;
  const _Vignette(this.produit, {this.cote = 48});

  @override
  Widget build(BuildContext context) {
    final repli = Container(
      width: cote,
      height: cote,
      color: _C.navyLight,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: cote * 0.42,
        color: _C.muted,
      ),
    );

    if (produit.image.isEmpty) return repli;
    return ImageReseau(produit.image, largeurServeur: 240, width: cote, height: cote, fit: BoxFit.cover, repli: repli);
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  CHOIX DES PRODUITS D'UNE SECTION
// ═══════════════════════════════════════════════════════════════════════

/// Coche les produits d'une section parmi le catalogue du vendeur.
///
/// Aucune création ici : c'est la page « Produits » qui crée, celle-ci ne
/// fait que ranger. L'ordre des coches est conservé, c'est celui que le site
/// affichera.
class SelecteurProduits extends StatefulWidget {
  final String titreSection;
  final List<ProduitModel> produits;
  final List<String> dejaChoisis;

  const SelecteurProduits({
    required this.titreSection,
    required this.produits,
    required this.dejaChoisis,
  });

  @override
  State<SelecteurProduits> createState() => SelecteurProduitsState();
}

class SelecteurProduitsState extends State<SelecteurProduits> {
  /// Liste et non ensemble : l'ordre des coches est l'ordre d'affichage sur
  /// le site, et un `Set` le perdrait. On repart des identifiants encore
  /// valides, pour ne pas réenregistrer un produit supprimé entre-temps.
  late final List<String> _choisis = widget.dejaChoisis
      .where((id) => widget.produits.any((p) => p.id == id))
      .toList();

  String _recherche = '';

  List<ProduitModel> get _visibles {
    final q = _recherche.trim().toLowerCase();
    if (q.isEmpty) return widget.produits;
    return widget.produits
        .where(
          (p) =>
              p.nom.toLowerCase().contains(q) ||
              p.categorie.toLowerCase().contains(q),
        )
        .toList();
  }

  void _basculer(String id) {
    if (_choisis.contains(id)) {
      setState(() => _choisis.remove(id));
      return;
    }
    if (_choisis.length >= maxProduitsParSection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Une section contient au plus $maxProduitsParSection produits.',
          ),
        ),
      );
      return;
    }
    setState(() => _choisis.add(id));
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles;

    return ScaffoldMarine(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(
          widget.titreSection,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: kPolice, 
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_choisis),
            child: Text(
              'Valider',
              style: TextStyle(fontFamily: kPolice, 
                color: const Color(0xFFFBB900),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: ChampRecherche(
              indication: 'Rechercher un produit',
              surFondClair: true,
              onChanged: (v) => setState(() => _recherche = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Row(
              children: [
                Text(
                  '${_choisis.length} choisi${_choisis.length > 1 ? 's' : ''}',
                  style: TextStyle(fontFamily: kPolice, 
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _C.navy,
                  ),
                ),
                const Spacer(),
                if (_choisis.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(_choisis.clear),
                    child: const Text('Tout décocher'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: visibles.isEmpty
                ? const Center(
                    child: EtatVide(
                      icone: Icons.search_off_rounded,
                      titre: 'Aucun produit trouvé',
                      message: 'Essayez un autre mot.',
                      compact: true,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: visibles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final p = visibles[i];
                      final rang = _choisis.indexOf(p.id);
                      return _LigneProduit(
                        produit: p,
                        rang: rang < 0 ? null : rang + 1,
                        onTap: () => _basculer(p.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LigneProduit extends StatelessWidget {
  final ProduitModel produit;

  /// Position dans la section, à partir de 1 ; `null` si le produit n'est
  /// pas choisi.
  final int? rang;
  final VoidCallback onTap;

  const _LigneProduit({
    required this.produit,
    required this.rang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final coche = rang != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: coche ? _C.navy : _C.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: _Vignette(produit, cote: 52),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produit.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: kPolice, 
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.navy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formaterPrix(double.tryParse(produit.prix) ?? 0),
                    style: TextStyle(fontFamily: kPolice, 
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _C.muted,
                    ),
                  ),
                ],
              ),
            ),
            // Le rang n'est pas décoratif : il dit dans quel ordre le site
            // affichera les produits de la section.
            if (coche)
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _C.navy,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rang',
                  style: TextStyle(fontFamily: kPolice, 
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              )
            else
              const Icon(
                Icons.radio_button_unchecked_rounded,
                color: _C.border,
                size: 26,
              ),
          ],
        ),
      ),
    );
  }
}
