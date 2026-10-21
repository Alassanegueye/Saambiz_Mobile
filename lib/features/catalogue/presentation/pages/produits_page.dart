import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../categories/data/categorie.dart';
import '../../../categories/presentation/icones_categories.dart';
import '../../../categories/presentation/pages/categorie_boutiques_page.dart';
import '../../data/catalogue_remote_datasource.dart';
import '../../data/produit_catalogue.dart';
import '../widgets/bouton_panier.dart';
import '../widgets/produit_card.dart';

/// Liste de produits : une catégorie, une recherche ou les promotions.
/// Tri en un geste (récents, populaires, prix), défilement infini.
class ProduitsPage extends StatefulWidget {
  final String titre;

  /// Catégorie (pour ses produits et le lien vers ses boutiques).
  final Categorie? categorie;
  final String? recherche;
  final bool promotions;

  const ProduitsPage({super.key, required this.titre, this.categorie, this.recherche, this.promotions = false});

  @override
  State<ProduitsPage> createState() => _ProduitsPageState();
}

class _ProduitsPageState extends State<ProduitsPage> {
  static const _tris = [
    ('recents', 'Récents', Icons.schedule_rounded),
    ('populaires', 'Populaires', Icons.local_fire_department_outlined),
    ('prix_asc', 'Prix ↑', null),
    ('prix_desc', 'Prix ↓', null),
  ];

  final _ds = CatalogueRemoteDataSource(sl<Dio>());
  final _scroll = ScrollController();
  late final _rechercheCtrl = TextEditingController(text: widget.recherche ?? '');

  final List<ProduitCatalogue> _produits = [];
  late String _tri = widget.promotions ? 'promos' : 'recents';
  late String _recherche = widget.recherche ?? '';
  int _page = 1;
  int _pages = 1;
  int _total = 0;
  bool _chargement = true;
  bool _suite = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _chargerSuite();
    });
    _charger();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _rechercheCtrl.dispose();
    super.dispose();
  }

  Future<PageProduits> _requete(int page) => _ds.produits(
        categorie: widget.categorie?.slug,
        recherche: _recherche,
        promo: widget.promotions,
        tri: _tri,
        page: page,
      );

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final res = await _requete(1);
      if (!mounted) return;
      setState(() {
        _produits
          ..clear()
          ..addAll(res.produits);
        _page = 1;
        _pages = res.pages;
        _total = res.total;
        _chargement = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _erreur = 'Impossible de charger les produits. Vérifiez votre connexion.';
          _chargement = false;
        });
      }
    }
  }

  Future<void> _chargerSuite() async {
    if (_suite || _chargement || _page >= _pages) return;
    setState(() => _suite = true);
    try {
      final res = await _requete(_page + 1);
      if (!mounted) return;
      setState(() {
        _produits.addAll(res.produits);
        _page += 1;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _suite = false);
    }
  }

  void _trier(String tri) {
    if (tri == _tri) return;
    setState(() => _tri = tri);
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.categorie;
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        backgroundColor: AppColor.kWhite,
        surfaceTintColor: AppColor.kWhite,
        elevation: 0,
        foregroundColor: AppColor.kGrayscaleDark100,
        titleSpacing: 0,
        title: Row(
          children: [
            if (c != null) ...[
              PastilleIcone(iconeCategorie(c.icone), taille: 34),
              const SizedBox(width: 10),
            ] else if (widget.promotions) ...[
              const PastilleIcone(Icons.local_offer_outlined, accent: true, taille: 34),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (!_chargement)
                    Text('$_total produit${_total > 1 ? 's' : ''}', style: texteDiscret(11.5)),
                ],
              ),
            ),
          ],
        ),
        actions: const [BoutonPanier(), SizedBox(width: 6)],
      ),
      body: RefreshIndicator(
        color: AppColor.kPrimary,
        onRefresh: _charger,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _barreOutils()),
            ..._contenu(),
            SliverToBoxAdapter(
              child: _suite
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator(color: AppColor.kPrimary, strokeWidth: 2)),
                    )
                  : const SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barreOutils() {
    final c = widget.categorie;
    return Container(
      color: AppColor.kWhite,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.promotions)
            ChampRecherche(
              controleur: _rechercheCtrl,
              indication: c != null ? 'Rechercher dans ${c.nom}' : 'Rechercher un produit…',
              onSubmitted: (v) {
                _recherche = v;
                _charger();
              },
            ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (widget.promotions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PuceFiltre(
                      libelle: 'Fin la plus proche',
                      icone: Icons.timer_outlined,
                      active: _tri == 'promos',
                      onTap: () => _trier('promos'),
                    ),
                  ),
                for (final t in _tris)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PuceFiltre(
                      libelle: t.$2,
                      icone: t.$3,
                      active: _tri == t.$1,
                      onTap: () => _trier(t.$1),
                    ),
                  ),
                // Une catégorie, c'est aussi des boutiques.
                if (c != null)
                  PuceFiltre(
                    libelle: 'Voir les boutiques',
                    icone: Icons.storefront_outlined,
                    active: false,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CategorieBoutiquesPage(categorie: c),
                    )),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _contenu() {
    if (_chargement) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(child: CircularProgressIndicator(color: AppColor.kPrimary, strokeWidth: 2.5)),
          ),
        ),
      ];
    }
    if (_erreur != null) {
      return [
        SliverToBoxAdapter(
          child: EtatVide(icone: Icons.wifi_off_rounded, titre: 'Oups', message: _erreur, action: 'Réessayer', onAction: _charger),
        ),
      ];
    }
    if (_produits.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EtatVide(
            icone: widget.promotions ? Icons.local_offer_outlined : Icons.inventory_2_outlined,
            titre: widget.promotions
                ? 'Pas de promotion en ce moment'
                : _recherche.isNotEmpty
                    ? 'Aucun résultat pour « $_recherche »'
                    : 'Bientôt des produits ici',
            message: widget.promotions
                ? 'Revenez vite : les vendeurs lancent régulièrement de nouvelles offres.'
                : _recherche.isNotEmpty
                    ? 'Essayez un autre mot, plus court ou plus général.'
                    : 'Les vendeurs de cette catégorie ajoutent leurs produits. Revenez très vite !',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        sliver: SliverGrid(
          gridDelegate: grilleProduits(context),
          delegate: SliverChildBuilderDelegate(
            (_, i) => ProduitCard(produit: _produits[i]),
            childCount: _produits.length,
          ),
        ),
      ),
    ];
  }
}
