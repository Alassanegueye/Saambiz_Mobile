import 'package:saambiz/core/widgets/messages.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/image_reseau.dart';
import '../../../../core/widgets/page_vendeur.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../boutique/domain/entities/boutique.dart';
import '../../../certification/certification_service.dart';
import '../../../boutique/domain/usecases/get_ma_boutique.dart';
import '../../../boutique/presentation/pages/ma_boutique_page.dart';
import '../../../home/data/models/produit_model.dart';
import '../../../promotions/presentation/pages/nouvelle_campagne_page.dart';
import '../../../vendeur/data/datasources/vendeur_produit_datasource.dart';
import '../../../vendeur/domain/usecases/get_mes_produits.dart';
import '../../domain/entities/vitrine.dart';
import '../bloc/vitrine_bloc.dart';
import '../bloc/vitrine_event.dart';
import '../bloc/vitrine_state.dart';
import 'assistant_vitrine_page.dart';
import 'sections_boutique_page.dart';

/// Palette locale, même convention que les autres écrans vendeur.
class _C {
  static const navy = Color(0xFF01154B);
  static const navyLight = Color(0xFFE8EDF7);
  static const bg = Color(0xFFF7F9FC);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E7F0);
  static const muted = Color(0xFF5B6C8A);
  static const success = Color(0xFF15803D);
  static const alerte = Color(0xFFB0850B);
  static const gold = Color(0xFFFBB900);
  static const danger = Color(0xFFC62828);
}

/// L'onglet « Boutique » : tout ce qui configure la boutique en ligne.
///
/// C'est le point unique où le vendeur met son site en ligne, le ferme,
/// compose ses rayons et y range ses produits. Les produits eux-mêmes se
/// créent dans l'onglet « Produits » : ici on ne fait que les disposer, et
/// l'écran renvoie vers « Produits » quand il n'y en a aucun.
class BoutiquePage extends StatelessWidget {
  /// Ouvre l'onglet « Produits ». Seul [MainVendeurPage] sait atteindre les
  /// onglets voisins, il passe donc le geste plutôt que la page.
  final VoidCallback? ouvrirProduits;

  const BoutiquePage({super.key, this.ouvrirProduits});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VitrineBloc>()..add(ChargerVitrine()),
      child: _VueBoutique(ouvrirProduits: ouvrirProduits),
    );
  }
}

class _VueBoutique extends StatefulWidget {
  final VoidCallback? ouvrirProduits;
  const _VueBoutique({this.ouvrirProduits});

  @override
  State<_VueBoutique> createState() => _VueBoutiqueState();
}

class _VueBoutiqueState extends State<_VueBoutique> {
  /// Dernière boutique affichée. Pendant un enregistrement (ajout de
  /// section, de produits…), le bloc repasse par « chargement » : on garde
  /// l'aperçu à l'écran avec une fine barre de progression, plutôt que de
  /// le remplacer par un rond qui tourne à chaque geste.
  Vitrine? _derniere;
  List<SecteurVitrine> _secteurs = const [];

  @override
  Widget build(BuildContext context) {
    return PageVendeur(
      titre: 'Ma boutique',
      actions: [
        BoutonEnteteVendeur(
          icone: Icons.refresh_rounded,
          infobulle: 'Actualiser',
          onTap: () => context.read<VitrineBloc>().add(ChargerVitrine()),
        ),
      ],
      corps: BlocConsumer<VitrineBloc, VitrineState>(
        listener: (context, state) {
          if (state is VitrineErreur) {
            afficherErreur(context, state.message);
          }
          if (state is VitrineEnregistree) {
            final avant = _derniere?.active;
            final apres = state.vitrine.active;
            afficherSucces(
              context,
              avant != null && avant != apres
                  ? (apres
                        ? 'Votre boutique est en ligne : vos clients peuvent la visiter.'
                        : 'Votre boutique est hors ligne.')
                  : 'Modifications enregistrées avec succès',
            );
          }
          // Retour de l'assistant ou d'un enregistrement : on recharge
          // pour repartir d'un état sûr, plutôt que de recomposer
          // l'écran à partir de ce qui vient d'être renvoyé.
          if (state is VitrineCreee || state is VitrineEnregistree) {
            context.read<VitrineBloc>().add(ChargerVitrine());
          }
          if (state is VitrineSupprimee) {
            afficherSucces(
              context,
              'Votre site a été retiré. Vous pouvez en créer un autre '
              'quand vous voulez.',
            );
            // Recharger : l'écran repart sur l'assistant de création.
            context.read<VitrineBloc>().add(ChargerVitrine());
          }
        },
        builder: (context, state) {
          if (state is VitrineChargee) {
            _derniere = state.vitrine;
            _secteurs = state.secteurs;
          }
          final apercu = _derniere;
          final enCours =
              state is VitrineChargement ||
              state is VitrineEnregistree ||
              state is VitrineCreee;

          // Une boutique déjà publiée reste affichée pendant les
          // enregistrements, et même après une erreur (le message
          // part en bandeau) : le vendeur ne perd pas sa page.
          if (apercu != null &&
              apercu.configuree &&
              (state is VitrineChargee || enCours || state is VitrineErreur)) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 3,
                  child: enCours
                      ? const LinearProgressIndicator(
                          color: _C.navy,
                          backgroundColor: _C.navyLight,
                        )
                      : null,
                ),
                Expanded(
                  child: _Configuration(
                    vitrine: apercu,
                    secteurs: _secteurs,
                    ouvrirProduits: widget.ouvrirProduits,
                    occupe: enCours,
                  ),
                ),
              ],
            );
          }

          if (state is VitrineChargement || state is VitrineInitial) {
            return const Center(
              child: CircularProgressIndicator(color: _C.navy),
            );
          }

          if (state is VitrineSansBoutique) {
            return Center(
              child: EtatVide(
                icone: Icons.storefront_outlined,
                titre: 'Créez d\'abord votre boutique',
                message: state.message,
              ),
            );
          }

          if (state is VitrineErreur) {
            return Center(
              child: EtatVide(
                icone: Icons.wifi_off_rounded,
                titre: 'Chargement impossible',
                message: state.message,
                action: 'Réessayer',
                onAction: () =>
                    context.read<VitrineBloc>().add(ChargerVitrine()),
              ),
            );
          }

          if (state is VitrineChargee) {
            return _BoutiqueAcreer(secteurs: state.secteurs);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  LA BOUTIQUE EN LIGNE N'EXISTE PAS ENCORE
// ═══════════════════════════════════════════════════════════════════════

class _BoutiqueAcreer extends StatelessWidget {
  final List<SecteurVitrine> secteurs;
  const _BoutiqueAcreer({required this.secteurs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, espaceBasVendeur(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _C.navyLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.language_rounded, color: _C.navy, size: 30),
          ),
          const SizedBox(height: 18),
          Text(
            'Mettez votre boutique en ligne',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _C.navy,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Votre boutique obtient sa propre adresse sur le web, que vous '
            'partagez à vos clients. Quelques questions suffisent : nous '
            'composons le site à partir de votre logo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.muted, fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _C.navy,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: secteurs.isEmpty
                ? null
                : () => _ouvrirAssistant(context, secteurs),
            icon: const Icon(Icons.auto_awesome_rounded, size: 19),
            label: Text(
              'Créer ma boutique en ligne',
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (secteurs.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Les secteurs d\'activité n\'ont pas pu être chargés. '
              'Actualisez pour réessayer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _C.alerte, fontSize: 12.5, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  CONFIGURATION DE LA BOUTIQUE EN LIGNE
// ═══════════════════════════════════════════════════════════════════════

class _Configuration extends StatefulWidget {
  final Vitrine vitrine;
  final List<SecteurVitrine> secteurs;
  final VoidCallback? ouvrirProduits;

  /// Un enregistrement est en cours : les boutons d'édition attendent.
  final bool occupe;

  const _Configuration({
    required this.vitrine,
    required this.secteurs,
    this.ouvrirProduits,
    this.occupe = false,
  });

  @override
  State<_Configuration> createState() => _ConfigurationState();
}

/// La boutique publiée, telle que les clients la voient, avec un bouton
/// « Modifier » sur chaque élément et un « + » au-dessus de chaque section.
///
/// Chaque geste enregistre tout de suite : le vendeur voit le résultat sans
/// passer par un écran de composition puis un bouton « Enregistrer ».
class _ConfigurationState extends State<_Configuration> {
  List<ProduitModel> _produits = const [];
  bool _produitsCharges = false;
  Boutique? _boutique;

  /// Boutique certifiée : badge « vérifiée » à côté du nom, comme sur le site.
  bool _verifiee = false;

  Vitrine get vitrine => widget.vitrine;
  List<SectionBoutique> get _sections => vitrine.sectionsPerso;

  @override
  void initState() {
    super.initState();
    _chargerProduits();
    _chargerBoutique();
  }

  @override
  void didUpdateWidget(covariant _Configuration ancien) {
    super.didUpdateWidget(ancien);
    // Rechargement de la boutique (actualiser, retour d'un autre onglet) :
    // le catalogue a pu changer entre-temps.
    if (!identical(ancien.vitrine, widget.vitrine) && !widget.occupe) {
      _chargerProduits();
    }
  }

  Future<void> _chargerProduits() async {
    final r = await sl<GetMesProduits>()();
    if (!mounted) return;
    r.fold(
      (_) => setState(() => _produitsCharges = true),
      (liste) => setState(() {
        _produits = liste;
        _produitsCharges = true;
      }),
    );
  }

  Future<void> _chargerBoutique() async {
    final r = await sl<GetMaBoutique>()();
    if (!mounted) return;
    r.fold((_) {}, (b) => setState(() => _boutique = b));
    try {
      final statut = await CertificationService(sl<Dio>()).statut();
      if (mounted) setState(() => _verifiee = statut.certifie);
    } catch (_) {
      // Sans réponse, pas de badge : rien de plus à faire.
    }
  }

  Future<void> _actualiser() async {
    context.read<VitrineBloc>().add(ChargerVitrine());
    await Future.wait([_chargerProduits(), _chargerBoutique()]);
  }

  ProduitModel? _produit(String id) {
    for (final p in _produits) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ── Enregistrement des sections ─────────────────────────────────────

  void _enregistrer(List<SectionBoutique> sections) {
    context.read<VitrineBloc>().add(
      ModifierVitrineDemande({
        'sectionsPerso': sections.map((s) => s.versJson()).toList(),
      }),
    );
  }

  void _dire(String message, {SnackBarAction? action}) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), action: action));

  Future<void> _ajouterSection() async {
    if (_sections.length >= maxSections) {
      _dire('Vous avez atteint $maxSections sections, le maximum.');
      return;
    }
    final titre = await demanderTitreSection(context);
    if (titre == null || !mounted) return;
    final sections = [..._sections, SectionBoutique(titre: titre)];
    _enregistrer(sections);
    // Une section vide ne s'affiche pas sur le site : on enchaîne
    // directement sur le choix de ses produits.
    if (_produits.isNotEmpty) {
      await _choisirProduits(sections.length - 1, sections: sections);
    }
  }

  Future<void> _choisirProduits(
    int i, {
    List<SectionBoutique>? sections,
  }) async {
    final liste = sections ?? _sections;
    if (_produits.isEmpty) {
      _dire(
        _produitsCharges
            ? 'Créez d\'abord des produits pour remplir cette section.'
            : 'Vos produits sont en cours de chargement…',
        action: _produitsCharges && widget.ouvrirProduits != null
            ? SnackBarAction(
                label: 'Produits',
                onPressed: widget.ouvrirProduits!,
              )
            : null,
      );
      return;
    }
    final choix = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => SelecteurProduits(
          titreSection: liste[i].titre,
          produits: _produits,
          dejaChoisis: liste[i].produitIds,
        ),
      ),
    );
    if (choix == null || !mounted) return;
    final maj = [...liste];
    maj[i] = maj[i].copyWith(produitIds: choix);
    _enregistrer(maj);
  }

  // ── « Nos produits » : la section par défaut ─────────────────────────

  /// Sans section, le site montre tous les produits sous « Nos produits ».
  /// La modifier la transforme en vraie section, qui garde d'abord tous
  /// les produits : le site ne change pas tant que le vendeur n'a rien
  /// retiré.
  SectionBoutique _sectionNosProduits({String titre = 'Nos produits'}) =>
      SectionBoutique(
        titre: titre,
        produitIds: _produits.map((p) => p.id).toList(),
      );

  Future<void> _renommerNosProduits() async {
    final titre = await demanderTitreSection(context, initial: 'Nos produits');
    if (titre == null || !mounted) return;
    _enregistrer([_sectionNosProduits(titre: titre)]);
  }

  Future<void> _choisirNosProduits() =>
      _choisirProduits(0, sections: [_sectionNosProduits()]);

  Future<void> _renommer(int i) async {
    final titre = await demanderTitreSection(
      context,
      initial: _sections[i].titre,
    );
    if (titre == null || !mounted) return;
    final maj = [..._sections];
    maj[i] = maj[i].copyWith(titre: titre);
    _enregistrer(maj);
  }

  void _deplacer(int i, int sens) {
    final j = i + sens;
    if (j < 0 || j >= _sections.length) return;
    final maj = [..._sections];
    final s = maj.removeAt(i);
    maj.insert(j, s);
    _enregistrer(maj);
  }

  Future<void> _supprimer(int i) async {
    final section = _sections[i];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.white,
        title: Text(
          'Supprimer « ${section.titre} » ?',
          style: const TextStyle(
            fontFamily: kPolice,
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
    if (ok != true || !mounted) return;
    _enregistrer([..._sections]..removeAt(i));
  }

  // ── Actions sur un produit ──────────────────────────────────────────

  /// Le menu « ⋮ » d'un produit : tout ce qui se règle d'ici. Le nom, la
  /// description et le prix se modifient dans l'onglet « Produits ».
  Future<void> _menuProduit(int section, ProduitModel p) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _C.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                p.nom,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _C.navy,
                ),
              ),
            ),
            _ActionMenu(
              icone: Icons.local_offer_outlined,
              texte: 'Mettre en promo',
              onTap: () => Navigator.of(ctx).pop('promo'),
            ),
            if (section >= 0)
              _ActionMenu(
                icone: Icons.remove_circle_outline_rounded,
                texte: 'Retirer de cette section',
                onTap: () => Navigator.of(ctx).pop('retirer'),
              ),
            _ActionMenu(
              icone: Icons.delete_outline_rounded,
              texte: 'Supprimer le produit',
              couleur: _C.danger,
              onTap: () => Navigator.of(ctx).pop('supprimer'),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Text(
                'Le nom, la description et le prix se modifient dans « Produits ».',
                style: TextStyle(color: _C.muted, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    final source = sl<VendeurProduitDataSource>();
    try {
      switch (action) {
        case 'promo':
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => NouvelleCampagnePage(produitId: p.id),
            ),
          );
          await _chargerProduits();
        case 'retirer':
          final maj = [..._sections];
          maj[section] = maj[section].copyWith(
            produitIds: maj[section].produitIds
                .where((id) => id != p.id)
                .toList(),
          );
          _enregistrer(maj);
        case 'supprimer':
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: _C.white,
              title: Text('Supprimer « ${p.nom} » ?'),
              content: const Text(
                'Le produit disparaît de votre boutique et de votre catalogue. '
                'Cette action est définitive.',
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
          await source.supprimerProduit(p.id);
          await _chargerProduits();
          if (mounted) afficherSucces(context, 'Produit supprimé avec succès');
      }
    } catch (_) {
      if (mounted)
        _dire('Action impossible. Vérifiez votre connexion et réessayez.');
    }
  }

  /// Le menu « Modifier » d'une section.
  Future<void> _modifierSection(int i) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _C.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                _sections[i].titre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _C.navy,
                ),
              ),
            ),
            _ActionMenu(
              icone: Icons.edit_outlined,
              texte: 'Renommer',
              onTap: () => Navigator.of(ctx).pop('renommer'),
            ),
            _ActionMenu(
              icone: Icons.checklist_rounded,
              texte: 'Choisir les produits',
              onTap: () => Navigator.of(ctx).pop('produits'),
            ),
            if (i > 0)
              _ActionMenu(
                icone: Icons.arrow_upward_rounded,
                texte: 'Monter',
                onTap: () => Navigator.of(ctx).pop('monter'),
              ),
            if (i < _sections.length - 1)
              _ActionMenu(
                icone: Icons.arrow_downward_rounded,
                texte: 'Descendre',
                onTap: () => Navigator.of(ctx).pop('descendre'),
              ),
            _ActionMenu(
              icone: Icons.delete_outline_rounded,
              texte: 'Supprimer la section',
              couleur: _C.danger,
              onTap: () => Navigator.of(ctx).pop('supprimer'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'renommer':
        await _renommer(i);
      case 'produits':
        await _choisirProduits(i);
      case 'monter':
        _deplacer(i, -1);
      case 'descendre':
        _deplacer(i, 1);
      case 'supprimer':
        await _supprimer(i);
    }
  }

  Future<void> _modifierIdentite() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MaBoutiquePage()));
    if (mounted) _chargerBoutique();
  }

  void _modifierApparence() =>
      _ouvrirAssistant(context, widget.secteurs, vitrine: vitrine);

  /// Retire le site public, après confirmation explicite.
  ///
  /// Le geste est irréversible côté serveur : le site est supprimé, son
  /// adresse se libère, et les liens déjà partagés par le vendeur ne mènent
  /// plus nulle part. La boutique et les produits, eux, restent — c'est la
  /// distinction que la confirmation doit rendre évidente, sans quoi le
  /// vendeur croit tout perdre et n'ose pas, ou croit ne rien perdre et
  /// s'étonne après coup.
  Future<void> _supprimerSite() async {
    final bloc = context.read<VitrineBloc>();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer votre site ?'),
        content: const Text(
          'Votre site public sera supprimé et son adresse libérée : les liens '
          'que vous avez partagés ne mèneront plus à rien.\n\n'
          'Votre boutique et vos produits ne sont pas touchés, et vous pourrez '
          'créer un nouveau site quand vous voudrez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _C.danger),
            child: const Text('Retirer mon site'),
          ),
        ],
      ),
    );
    if (confirme == true) bloc.add(SupprimerVitrineDemande());
  }

  // ── Mise en ligne ───────────────────────────────────────────────────

  void _mettreEnLigne(bool enLigne) {
    if (enLigne == vitrine.active) return;
    HapticFeedback.mediumImpact();
    context.read<VitrineBloc>().add(
      ModifierVitrineDemande({'active': enLigne}),
    );
    // Le message part une fois l'enregistrement confirmé (voir le listener).
  }

  // ── Affichage ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final occupe = widget.occupe;
    final teintes = _Teintes.depuis(vitrine.accent);
    // Les catégories des produits, en pastilles, comme sur le site quand la
    // boutique a des sections.
    final rayons = <String>{
      for (final p in _produits)
        if (p.categorie.trim().isNotEmpty) p.categorie.trim(),
    }.toList();
    final apropos = (vitrine.apropos ?? '').trim();
    final horaires = (vitrine.horaires ?? '').trim();

    return RefreshIndicator(
      color: _C.navy,
      onRefresh: _actualiser,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 18, 16, espaceBasVendeur(context)),
        children: [
          // ── Le grand interrupteur : en ligne / hors ligne ───────────
          _CarteEnLigne(
            vitrine: vitrine,
            onChanged: occupe ? null : _mettreEnLigne,
          ),

          // ── La boutique, telle que la voient les clients ────────────
          const SizedBox(height: 26),
          const _TitreBloc(
            'Ce que voient vos clients',
            aide: 'Touchez un élément ou son crayon pour le modifier.',
          ),
          _CadreSite(
            adresse: vitrine.url,
            pied: teintes.pied,
            nomBoutique: _boutique?.nom ?? 'Ma boutique',
            enfants: [
              _BlocModifiable(
                infobulle: 'Modifier le nom, le logo et l\'adresse',
                onModifier: occupe ? null : _modifierIdentite,
                enfant: _EnteteSite(
                  boutique: _boutique,
                  vitrine: vitrine,
                  teintes: teintes,
                  verifiee: _verifiee,
                ),
              ),
              if (_sections.isNotEmpty && rayons.length > 1)
                _RayonsSite(categories: rayons),

              for (var i = 0; i < _sections.length; i++)
                _SectionSite(
                  titre: _sections[i].titre,
                  produits: _sections[i].produitIds
                      .map(_produit)
                      .whereType<ProduitModel>()
                      .toList(),
                  teintes: teintes,
                  chargement: !_produitsCharges,
                  onAjouter: occupe ? null : () => _choisirProduits(i),
                  onModifier: occupe ? null : () => _modifierSection(i),
                  onMenuProduit: occupe ? null : (p) => _menuProduit(i, p),
                ),

              // Sans section, le site montre simplement tout le catalogue.
              if (_sections.isEmpty)
                _SectionSite(
                  titre: 'Nos produits',
                  note:
                      'Votre site montre tous vos produits. Créez des '
                      'sections (Nouveautés, Promos…) pour en mettre en avant.',
                  produits: _produits,
                  teintes: teintes,
                  chargement: !_produitsCharges,
                  onAjouter: occupe ? null : _choisirNosProduits,
                  onModifier: occupe ? null : _renommerNosProduits,
                  onMenuProduit: occupe ? null : (p) => _menuProduit(-1, p),
                ),

              _BoutonAjoutSection(onTap: occupe ? null : _ajouterSection),

              if (apropos.isNotEmpty || horaires.isNotEmpty) ...[
                const Divider(height: 1, thickness: 1, color: _C.border),
                _BlocModifiable(
                  infobulle: 'Modifier la présentation',
                  onModifier: occupe ? null : _modifierApparence,
                  enfant: _InfosSite(
                    nom: _boutique?.nom ?? 'la boutique',
                    apropos: apropos,
                    horaires: horaires,
                    accent: teintes.texte,
                  ),
                ),
              ],
            ],
          ),

          // ── Réglages ────────────────────────────────────────────────
          const SizedBox(height: 26),
          const _TitreBloc('Réglages'),
          _Bloc(
            enfant: Column(
              children: [
                _LigneReglage(
                  icone: Icons.palette_outlined,
                  titre: 'Apparence du site',
                  sousTitre: 'Couleur, mise en page, présentation',
                  onTap: occupe ? null : _modifierApparence,
                ),
                const Divider(height: 1, color: _C.border),
                _LigneReglage(
                  icone: Icons.inventory_2_outlined,
                  titre: 'Gérer mes produits',
                  sousTitre: 'Créer, modifier ou retirer un produit',
                  onTap: widget.ouvrirProduits,
                ),
                const Divider(height: 1, color: _C.border),
                // `DELETE /vendeur/ma-vitrine` existait côté backend sans
                // qu'aucun écran ne l'appelle : un vendeur pouvait créer son
                // site, jamais le retirer.
                _LigneReglage(
                  icone: Icons.delete_outline_rounded,
                  titre: 'Retirer mon site',
                  sousTitre: 'La boutique reste, seul le site disparaît',
                  couleur: _C.danger,
                  onTap: occupe ? null : _supprimerSite,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Le rappel de la gratuité n'est pas décoratif : un vendeur qui a un
          // site suppose qu'on va le lui facturer, et se retient de le
          // partager tant qu'il n'est pas fixé.
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _C.navyLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.favorite_rounded, color: _C.navy, size: 18),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Votre site ne vous coûte rien : aucun abonnement, aucune '
                    'commission sur vos ventes. Partagez-le sans crainte.',
                    style: TextStyle(
                      color: _C.navy,
                      fontSize: 12.8,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Les couleurs du site, dérivées de la couleur du vendeur avec les mêmes
/// règles que le site (theme.js) : l'aperçu ressemble à ce que voit le client.
class _Teintes {
  /// Accent posé en texte sur blanc (liens, icônes).
  final Color texte;

  /// Fond des boutons pleins (WhatsApp, « + ») et texte posé dessus.
  final Color bouton;
  final Color surBouton;

  /// Pied de page.
  final Color pied;

  /// Fond du haut du site (l'identité de la boutique) : l'accent fondu dans
  /// le blanc, comme sur saambiz.com (variable --bq-teinte du site).
  final Color teinte;
  final Color teinteLigne;

  const _Teintes({
    required this.texte,
    required this.bouton,
    required this.surBouton,
    required this.pied,
    required this.teinte,
    required this.teinteLigne,
  });

  static const _encre = Color(0xFF121418);

  static double _contraste(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  static Color _lisible(Color c, Color fond, double cible) {
    if (_contraste(c, fond) >= cible) return c;
    for (var t = 0.04; t <= 1.0; t += 0.04) {
      final essai = Color.lerp(c, Colors.black, t)!;
      if (_contraste(essai, fond) >= cible) return essai;
    }
    return Colors.black;
  }

  factory _Teintes.depuis(String hex) {
    final m = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(hex.trim());
    final brut = m == null
        ? _C.navy
        : Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
    final accent = _lisible(brut, Colors.white, 1.9);

    var bouton = accent;
    var surBouton = Colors.white;
    if (_contraste(Colors.white, accent) < 4.5) {
      if (_contraste(_encre, accent) >= 7) {
        surBouton = _encre;
      } else {
        bouton = _lisible(accent, Colors.white, 4.5);
      }
    }

    var pied = accent;
    for (var t = 0.0; t <= 1.0 && pied.computeLuminance() > 0.016; t += 0.02) {
      pied = Color.lerp(accent, Colors.black, t)!;
    }

    return _Teintes(
      texte: _lisible(accent, Colors.white, 4.6),
      bouton: bouton,
      surBouton: surBouton,
      pied: pied,
      teinte: Color.lerp(Colors.white, accent, 0.07)!,
      teinteLigne: Color.lerp(Colors.white, accent, 0.16)!,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  EN LIGNE / HORS LIGNE
// ═══════════════════════════════════════════════════════════════════════

/// L'état du site, le grand interrupteur pour le changer, et son adresse.
class _CarteEnLigne extends StatelessWidget {
  final Vitrine vitrine;
  final ValueChanged<bool>? onChanged;
  const _CarteEnLigne({required this.vitrine, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final enLigne = vitrine.active;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enLigne ? _C.success : const Color(0xFF9AA6BC),
                  boxShadow: enLigne
                      ? [
                          BoxShadow(
                            color: _C.success.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  enLigne
                      ? 'Votre boutique est en ligne'
                      : 'Votre boutique est hors ligne',
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: _C.navy,
                  ),
                ),
              ),
              if (vitrine.vues > 0)
                Text(
                  '${vitrine.vues} visites',
                  style: const TextStyle(color: _C.muted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            enLigne
                ? 'Vos clients peuvent la visiter et commander.'
                : 'Personne ne peut la visiter pour l\'instant.',
            style: const TextStyle(color: _C.muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          _GrandInterrupteur(enLigne: enLigne, onChanged: onChanged),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _ouvrirLien(vitrine.url),
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _C.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 15,
                            color: _C.muted,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              _sansProtocole(vitrine.url),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _C.navy,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: _C.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _BoutonIcone(
                icone: Icons.copy_rounded,
                infobulle: 'Copier l\'adresse',
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: vitrine.url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Adresse copiée.')),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              _BoutonIcone(
                icone: Icons.share_rounded,
                infobulle: 'Partager sur WhatsApp',
                onTap: () => _partagerWhatsapp(context, vitrine.url),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _sansProtocole(String url) =>
    url.replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'/$'), '');

/// Deux grandes moitiés : « En ligne » et « Hors ligne ». La moitié active
/// est pleine ; l'autre porte le nom de l'action (« Mettre en ligne »).
class _GrandInterrupteur extends StatelessWidget {
  final bool enLigne;
  final ValueChanged<bool>? onChanged;
  const _GrandInterrupteur({required this.enLigne, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final actif = onChanged != null;
    return Container(
      height: 62,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: enLigne ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                decoration: BoxDecoration(
                  color: enLigne ? _C.success : _C.navy,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (enLigne ? _C.success : _C.navy).withValues(
                        alpha: 0.28,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _MoitieInterrupteur(
                icone: Icons.public_rounded,
                texte: enLigne ? 'En ligne' : 'Mettre en ligne',
                selectionnee: enLigne,
                onTap: actif ? () => onChanged!(true) : null,
              ),
              _MoitieInterrupteur(
                icone: Icons.public_off_rounded,
                texte: enLigne ? 'Mettre hors ligne' : 'Hors ligne',
                selectionnee: !enLigne,
                onTap: actif ? () => onChanged!(false) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoitieInterrupteur extends StatelessWidget {
  final IconData icone;
  final String texte;
  final bool selectionnee;
  final VoidCallback? onTap;
  const _MoitieInterrupteur({
    required this.icone,
    required this.texte,
    required this.selectionnee,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = selectionnee ? _C.white : _C.navy;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selectionnee,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: selectionnee ? null : onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 19, color: couleur),
                const SizedBox(width: 7),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 14,
                      fontWeight: selectionnee
                          ? FontWeight.w800
                          : FontWeight.w700,
                      color: couleur,
                    ),
                    child: Text(
                      texte,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  LE SITE, TEL QUE LE VOIENT LES CLIENTS
// ═══════════════════════════════════════════════════════════════════════

/// Titre d'un groupe, avec une ligne d'aide facultative.
class _TitreBloc extends StatelessWidget {
  final String titre;
  final String? aide;
  const _TitreBloc(this.titre, {this.aide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _C.navy,
            ),
          ),
          if (aide != null) ...[
            const SizedBox(height: 2),
            Text(
              aide!,
              style: const TextStyle(
                color: _C.muted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le cadre d'un navigateur autour de l'aperçu : barre d'adresse en haut,
/// pied de page aux couleurs de la boutique en bas.
class _CadreSite extends StatelessWidget {
  final String adresse;
  final Color pied;
  final String nomBoutique;
  final Widget? barre;
  final List<Widget> enfants;
  const _CadreSite({
    required this.adresse,
    required this.pied,
    required this.nomBoutique,
    this.barre,
    required this.enfants,
  });

  @override
  Widget build(BuildContext context) {
    final barreSite = barre;
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: _C.navy.withValues(alpha: 0.07),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFF1F3F7),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 12, color: _C.muted),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      _sansProtocole(adresse),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _C.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (barreSite != null) barreSite,
          ...enfants,
          Container(
            color: pied,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Text(
              nomBoutique,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit bouton rond posé sur l'aperçu (crayon, « + »).
class _PastilleAction extends StatelessWidget {
  final IconData icone;
  final String infobulle;
  final VoidCallback? onTap;
  final bool principal;
  const _PastilleAction({
    required this.icone,
    required this.infobulle,
    this.onTap,
    this.principal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: infobulle,
      child: Material(
        color: principal ? _C.gold : _C.white,
        shape: CircleBorder(
          side: principal
              ? BorderSide.none
              : const BorderSide(color: _C.border),
        ),
        elevation: principal ? 0 : 1.5,
        shadowColor: _C.navy.withValues(alpha: 0.25),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icone,
              size: principal ? 21 : 17,
              color: onTap == null ? _C.muted : _C.navy,
            ),
          ),
        ),
      ),
    );
  }
}

/// Un élément du site qu'on modifie en le touchant, crayon en haut à droite.
class _BlocModifiable extends StatelessWidget {
  final Widget enfant;
  final String infobulle;
  final VoidCallback? onModifier;
  const _BlocModifiable({
    required this.enfant,
    required this.infobulle,
    this.onModifier,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(onTap: onModifier, child: enfant),
        Positioned(
          top: 10,
          right: 10,
          child: _PastilleAction(
            icone: Icons.edit_rounded,
            infobulle: infobulle,
            onTap: onModifier,
          ),
        ),
      ],
    );
  }
}

/// Couleurs fixes du site (vitrine.css).
class _S {
  static const encre = Color(0xFF121418);
  static const encreDouce = Color(0xFF5C626C);
  static const encrePale = Color(0xFF8A909A);
  static const ligne = Color(0xFFE4E7EC);
  static const papierFonce = Color(0xFFF5F6F8);
  static const remise = Color(0xFFC2410C);
  static const verifie = Color(0xFF1A8CD8);
}

/// « 14 900 » : le montant, espaces fines entre les milliers.
String _montant(double v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

/// Le haut du site, comme sur saambiz.com : logo et nom (avec le badge
/// « vérifiée »), activité, adresse et horaires, puis WhatsApp, Appeler et
/// Partager.
class _EnteteSite extends StatelessWidget {
  final Boutique? boutique;
  final Vitrine vitrine;
  final _Teintes teintes;
  final bool verifiee;
  const _EnteteSite({
    required this.boutique,
    required this.vitrine,
    required this.teintes,
    required this.verifiee,
  });

  @override
  Widget build(BuildContext context) {
    final b = boutique;
    final nom = b?.nom ?? 'Ma boutique';
    const cote = 66.0;
    final rond = vitrine.logoForme == 'rond';
    final rayon = BorderRadius.circular(rond ? cote / 2 : 16);

    final initiale = Container(
      width: cote,
      height: cote,
      decoration: BoxDecoration(color: teintes.bouton, borderRadius: rayon),
      alignment: Alignment.center,
      child: Text(
        nom.trim().isEmpty ? '?' : nom.trim()[0].toUpperCase(),
        style: TextStyle(
          fontFamily: kPolice,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: teintes.surBouton,
        ),
      ),
    );

    final activite = (vitrine.activite ?? '').trim();
    final sousTitre = activite.isNotEmpty
        ? activite
        : (b?.description ?? '').split('\n').first.trim();
    final adresse = b?.localisation ?? '';
    final horaires = (vitrine.horaires ?? '').trim();
    final whatsapp = (vitrine.reseaux['whatsapp'] ?? b?.telephone ?? '').trim();
    final telephone = (b?.telephone ?? '').trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: teintes.teinte,
        border: Border(bottom: BorderSide(color: teintes.teinteLigne)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: rayon,
                    border: Border.all(color: _S.ligne),
                  ),
                  child: ClipRRect(
                    borderRadius: rayon,
                    child: (b?.logo ?? '').isEmpty
                        ? initiale
                        : ImageReseau(
                            b!.logo,
                            largeurServeur: 200,
                            width: cote,
                            height: cote,
                            fit: BoxFit.cover,
                            repli: initiale,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    // Laisse la place au crayon, en haut à droite.
                    padding: const EdgeInsets.only(right: 34),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: nom,
                            children: [
                              if (verifiee)
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Icon(
                                      Icons.verified_rounded,
                                      size: 20,
                                      color: _S.verifie,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            height: 1.18,
                            color: _S.encre,
                          ),
                        ),
                        if (sousTitre.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            sousTitre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: _S.encreDouce,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (adresse.isNotEmpty || horaires.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  if (adresse.isNotEmpty)
                    _Repere(icone: Icons.place_outlined, texte: adresse),
                  if (horaires.isNotEmpty)
                    _Repere(icone: Icons.schedule_rounded, texte: horaires),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (whatsapp.isNotEmpty) ...[
                  Expanded(
                    child: _ActionSite(
                      icone: Icons.chat_outlined,
                      texte: 'WhatsApp',
                      fond: teintes.bouton,
                      couleur: teintes.surBouton,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (telephone.isNotEmpty) ...[
                  Expanded(
                    child: _ActionSite(
                      icone: Icons.call_outlined,
                      texte: 'Appeler',
                      couleurIcone: teintes.texte,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _ActionSite(
                    icone: Icons.share_outlined,
                    texte: 'Partager',
                    couleurIcone: teintes.texte,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Repere extends StatelessWidget {
  final IconData icone;
  final String texte;
  const _Repere({required this.icone, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 16, color: _S.encre),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            texte,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, color: _S.encre),
          ),
        ),
      ],
    );
  }
}

/// Bouton du haut du site (WhatsApp, Appeler, Partager), tel qu'affiché.
class _ActionSite extends StatelessWidget {
  final IconData icone;
  final String texte;
  final Color? fond;
  final Color couleur;
  final Color? couleurIcone;
  const _ActionSite({
    required this.icone,
    required this.texte,
    this.fond,
    this.couleur = _S.encre,
    this.couleurIcone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: fond ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: fond == null ? Border.all(color: _S.ligne) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 17, color: couleurIcone ?? couleur),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              texte,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: couleur,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Les catégories du catalogue, en pastilles qui défilent (comme sur le site
/// quand la boutique a des sections).
class _RayonsSite extends StatelessWidget {
  final List<String> categories;
  const _RayonsSite({required this.categories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _S.ligne),
          ),
          child: Text(
            categories[i],
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _S.encre,
            ),
          ),
        ),
      ),
    );
  }
}

/// Une section du site : titre, « Tout voir », puis les produits en tuiles
/// sur une ligne qui défile. Le « + » ajoute des produits, le crayon
/// modifie la section.
class _SectionSite extends StatelessWidget {
  final String titre;
  final String? note;
  final List<ProduitModel> produits;
  final _Teintes teintes;
  final bool chargement;
  final VoidCallback? onAjouter;
  final VoidCallback? onModifier;
  final void Function(ProduitModel)? onMenuProduit;

  const _SectionSite({
    required this.titre,
    required this.produits,
    required this.teintes,
    required this.chargement,
    this.note,
    this.onAjouter,
    this.onModifier,
    this.onMenuProduit,
  });

  @override
  Widget build(BuildContext context) {
    final modifiable = onAjouter != null || onModifier != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 0, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    titre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      height: 1.2,
                      color: _S.encre,
                    ),
                  ),
                ),
                if (produits.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    child: Text(
                      'Tout voir',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: teintes.texte,
                        decoration: TextDecoration.underline,
                        decorationColor: teintes.texte,
                      ),
                    ),
                  ),
                if (modifiable) ...[
                  const SizedBox(width: 6),
                  _PastilleAction(
                    icone: Icons.add_rounded,
                    infobulle: 'Ajouter des produits',
                    principal: true,
                    onTap: onAjouter,
                  ),
                  const SizedBox(width: 6),
                  _PastilleAction(
                    icone: Icons.edit_rounded,
                    infobulle: 'Modifier la section',
                    onTap: onModifier,
                  ),
                ],
              ],
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 16),
              child: Text(
                note!,
                style: const TextStyle(
                  color: _C.muted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
          if (!chargement && produits.isEmpty && modifiable)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'Vide : cette section n\'apparaît pas encore sur le site.',
                style: TextStyle(color: _C.alerte, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          if (chargement)
            const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _C.navy,
                ),
              ),
            )
          else if (produits.isEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 10),
              child: InkWell(
                onTap: onAjouter,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _S.papierFonce,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _S.ligne),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: _C.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        onAjouter == null
                            ? 'Aucun produit pour l\'instant'
                            : 'Ajoutez des produits à cette section',
                        style: const TextStyle(color: _C.muted, fontSize: 12.8),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 16, bottom: 2),
                itemCount: produits.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _ProduitSite(
                  produits[i],
                  teintes: teintes,
                  onMenu: onMenuProduit == null
                      ? null
                      : () => onMenuProduit!(produits[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Une tuile produit du site : photo sur fond gris clair, pastille (remise
/// ou dernières pièces), nom, prix (l'ancien barré au-dessus) et bouton
/// rond « + ». Le « ⋮ » du vendeur est posé sur la photo.
class _ProduitSite extends StatelessWidget {
  final ProduitModel produit;
  final _Teintes teintes;
  final VoidCallback? onMenu;
  const _ProduitSite(this.produit, {required this.teintes, this.onMenu});

  @override
  Widget build(BuildContext context) {
    const largeur = 156.0;
    final prix = double.tryParse(produit.prix) ?? 0;
    final promo = double.tryParse(produit.prixPromo ?? '');
    final enPromo = promo != null && promo > 0 && promo < prix;
    final remise = enPromo ? ((1 - promo / prix) * 100).round() : 0;
    final prixAffiche = enPromo ? promo : prix;
    final stockFaible = produit.quantite > 0 && produit.quantite <= 3;

    Widget? pastille;
    if (remise > 0) {
      pastille = _PastilleSite(
        texte: '−$remise %',
        fond: _S.remise,
        couleur: Colors.white,
      );
    } else if (stockFaible) {
      pastille = const _PastilleSite(
        texte: 'Dernières pièces',
        fond: Color(0xFFFDF0DC),
        couleur: Color(0xFF9A4A06),
      );
    }

    return Container(
      width: largeur,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _S.ligne),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: largeur,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: _S.papierFonce,
                  padding: const EdgeInsets.all(9),
                  child: produit.image.isEmpty
                      ? const Icon(
                          Icons.image_not_supported_outlined,
                          color: _S.encrePale,
                        )
                      : ImageReseau(
                          produit.image,
                          largeurServeur: 320,
                          fit: BoxFit.contain,
                          fond: _S.papierFonce,
                          repli: const Icon(
                            Icons.image_not_supported_outlined,
                            color: _S.encrePale,
                          ),
                        ),
                ),
                if (pastille != null)
                  Positioned(top: 9, left: 9, child: pastille),
                if (onMenu != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _PastilleAction(
                      icone: Icons.more_vert_rounded,
                      infobulle: 'Actions sur ce produit',
                      onTap: onMenu,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produit.nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: _S.encre,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (enPromo)
                              Text(
                                '${_montant(prix)} FCFA',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: _S.encrePale,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: _S.encrePale,
                                ),
                              ),
                            Text.rich(
                              TextSpan(
                                text: _montant(prixAffiche),
                                children: const [
                                  TextSpan(
                                    text: ' FCFA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _S.encre,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: teintes.bouton,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 20,
                          color: teintes.surBouton,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PastilleSite extends StatelessWidget {
  final String texte;
  final Color fond;
  final Color couleur;
  const _PastilleSite({
    required this.texte,
    required this.fond,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texte,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: couleur,
        ),
      ),
    );
  }
}

/// « Ajouter une section », sous la dernière section.
class _BoutonAjoutSection extends StatelessWidget {
  final VoidCallback? onTap;
  const _BoutonAjoutSection({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Ajouter une section',
          style: TextStyle(
            fontFamily: kPolice,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _C.navy,
          backgroundColor: _C.navyLight.withValues(alpha: 0.45),
          side: BorderSide(color: _C.navy.withValues(alpha: 0.3), width: 1.2),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// « À propos » et horaires, en bas du site.
class _InfosSite extends StatelessWidget {
  final String nom;
  final String apropos;
  final String horaires;
  final Color accent;
  const _InfosSite({
    required this.nom,
    required this.apropos,
    required this.horaires,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 56, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (apropos.isNotEmpty) ...[
            Text(
              'À propos de $nom',
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF121418),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              apropos,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _C.muted,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
          if (horaires.isNotEmpty) ...[
            if (apropos.isNotEmpty) const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule_rounded, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    horaires,
                    style: const TextStyle(
                      color: Color(0xFF121418),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  final IconData icone;
  final String texte;
  final VoidCallback onTap;
  final Color couleur;
  const _ActionMenu({
    required this.icone,
    required this.texte,
    required this.onTap,
    this.couleur = _C.navy,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icone, color: couleur),
      title: Text(
        texte,
        style: TextStyle(
          fontFamily: kPolice,
          fontWeight: FontWeight.w600,
          color: couleur,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _LigneReglage extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String sousTitre;
  final VoidCallback? onTap;

  /// Teinte du titre et de l'icône. Sert à distinguer une action
  /// irréversible des réglages ordinaires.
  final Color? couleur;

  const _LigneReglage({
    required this.icone,
    required this.titre,
    required this.sousTitre,
    this.onTap,
    this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icone, color: couleur ?? _C.navy),
      title: Text(
        titre,
        style: TextStyle(
          fontFamily: kPolice,
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: couleur ?? _C.navy,
        ),
      ),
      subtitle: Text(
        sousTitre,
        style: const TextStyle(color: _C.muted, fontSize: 12.5),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: _C.muted),
      onTap: onTap,
    );
  }
}

/// Une carte blanche de réglages.
class _Bloc extends StatelessWidget {
  final Widget enfant;
  const _Bloc({required this.enfant});

  @override
  Widget build(BuildContext context) {
    // Un Material, pas un Container coloré : les ListTile dessinent leur
    // effet de toucher sur le Material le plus proche.
    return Material(
      color: _C.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _C.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
        child: enfant,
      ),
    );
  }
}

class _BoutonIcone extends StatelessWidget {
  final IconData icone;
  final String infobulle;
  final VoidCallback onTap;

  const _BoutonIcone({
    required this.icone,
    required this.infobulle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: infobulle,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _C.navyLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, color: _C.navy, size: 19),
        ),
      ),
    );
  }
}

void _ouvrirAssistant(
  BuildContext context,
  List<SecteurVitrine> secteurs, {
  Vitrine? vitrine,
}) {
  final bloc = context.read<VitrineBloc>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AssistantVitrinePage(secteurs: secteurs, vitrine: vitrine),
      ),
    ),
  );
}

Future<void> _ouvrirLien(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _partagerWhatsapp(BuildContext context, String url) async {
  final texte = Uri.encodeComponent('Découvrez ma boutique en ligne : $url');
  final uri = Uri.parse('https://wa.me/?text=$texte');
  final ouvert = await launchUrl(uri, mode: LaunchMode.externalApplication);

  // WhatsApp absent de l'appareil : on ne laisse pas le vendeur sans solution,
  // l'adresse part dans le presse-papier.
  if (!ouvert && context.mounted) {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adresse copiée : collez-la où vous voulez.'),
        ),
      );
    }
  }
}
