import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:saambiz/core/theme/police.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/texte.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/degrade_fond.dart';
import '../../../../core/widgets/barre_navigation_verre.dart'
    show kEspaceBarreBas;
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../categories/data/categorie.dart';
import '../../../categories/presentation/icones_categories.dart';
import '../../../categories/presentation/pages/categorie_boutiques_page.dart'
    show LigneBoutique;
import '../../data/catalogue_remote_datasource.dart';
import 'produits_page.dart';

enum _Onglet { boutiques, categories }

/// Onglet « Explorer » du client : les BOUTIQUES d'abord — SaamBiz présente
/// des boutiques avant des produits — puis les catégories.
///
/// - Boutiques : toutes les boutiques en ligne (les plus récentes d'abord),
///   ou celles qui correspondent à la recherche (nom, slogan, catégorie,
///   ville), chargées page par page au défilement.
/// - Catégories : grille de tuiles filtrée sur place au fil de la frappe.
///   « Promotions » ouvre les promotions en cours.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _ctrl = TextEditingController();
  _Onglet _onglet = _Onglet.boutiques;

  // Catégories
  List<Categorie> _categories = const [];
  bool _chargement = true;
  String _filtre = '';

  // Boutiques
  final _ds = CatalogueRemoteDataSource(sl<Dio>());
  final _defilement = ScrollController();
  final List<Map<String, dynamic>> _boutiques = [];
  bool _chargementBoutiques = true;
  bool _chargementSuite = false;
  String? _erreurBoutiques;
  int _page = 1;
  int _pages = 1;
  int _total = 0;
  Timer? _attenteFrappe;

  /// Numéro de la dernière requête : une réponse lente d'une recherche
  /// abandonnée n'écrase pas la plus récente.
  int _requete = 0;

  @override
  void initState() {
    super.initState();
    _defilement.addListener(_surDefilement);
    _charger();
    _chargerBoutiques();
  }

  @override
  void dispose() {
    _attenteFrappe?.cancel();
    _defilement.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _surDefilement() {
    if (_defilement.position.pixels >
        _defilement.position.maxScrollExtent - 400) {
      _chargerSuite();
    }
  }

  Future<void> _chargerBoutiques() async {
    final numero = ++_requete;
    setState(() {
      _chargementBoutiques = true;
      _erreurBoutiques = null;
    });
    try {
      final res = await _ds.listerBoutiques(recherche: _filtre);
      if (!mounted || numero != _requete) return;
      setState(() {
        _boutiques
          ..clear()
          ..addAll(res.boutiques);
        _page = 1;
        _pages = res.pages;
        _total = res.total;
        _chargementBoutiques = false;
      });
    } catch (_) {
      if (!mounted || numero != _requete) return;
      setState(() {
        _erreurBoutiques =
            'Impossible de charger les boutiques. Vérifiez votre connexion.';
        _chargementBoutiques = false;
      });
    }
  }

  Future<void> _chargerSuite() async {
    if (_onglet != _Onglet.boutiques ||
        _chargementSuite ||
        _chargementBoutiques ||
        _page >= _pages) {
      return;
    }
    final numero = _requete;
    setState(() => _chargementSuite = true);
    try {
      final res = await _ds.listerBoutiques(
        recherche: _filtre,
        page: _page + 1,
      );
      if (!mounted || numero != _requete) return;
      setState(() {
        _page += 1;
        _pages = res.pages;
        _total = res.total;
        _boutiques.addAll(res.boutiques);
      });
    } catch (_) {
      // La suite se rechargera au prochain défilement.
    } finally {
      if (mounted) setState(() => _chargementSuite = false);
    }
  }

  void _surFrappe(String texte) {
    setState(() => _filtre = texte);
    // Les catégories se filtrent sur place ; les boutiques attendent que la
    // frappe se pose avant d'interroger le serveur.
    _attenteFrappe?.cancel();
    _attenteFrappe = Timer(
      const Duration(milliseconds: 350),
      _chargerBoutiques,
    );
  }

  void _changerOnglet(_Onglet onglet) {
    if (onglet == _onglet) return;
    setState(() => _onglet = onglet);
  }

  Future<void> _charger({bool forcer = false}) async {
    final liste = await CategoriesRemoteDataSource(
      sl<Dio>(),
    ).lister(forcer: forcer);
    if (!mounted) return;
    setState(() {
      _categories = liste;
      _chargement = false;
    });
  }

  bool _correspond(String nom) => contientRecherche(nom, _filtre);

  void _effacerFiltre() {
    _ctrl.clear();
    _attenteFrappe?.cancel();
    setState(() => _filtre = '');
    _chargerBoutiques();
  }

  void _ouvrir(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return FondDegradeSubtil(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const AppAppBar(
          title: 'Explorer',
          centerTitle: true,
          implyLeading: false,
          couleurFond: Colors.transparent,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: ChampRecherche(
                controleur: _ctrl,
                indication: _onglet == _Onglet.boutiques
                    ? 'Rechercher une boutique, une ville…'
                    : 'Rechercher une catégorie',
                surFondClair: true,
                onChanged: _surFrappe,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _SelecteurOnglet(
                onglet: _onglet,
                onChanged: _changerOnglet,
              ),
            ),
            Expanded(
              child: _onglet == _Onglet.boutiques
                  ? _corpsBoutiques()
                  : _corps(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corpsBoutiques() {
    final recherche = _filtre.trim();
    if (_chargementBoutiques && _boutiques.isEmpty) {
      return Reflet(
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          itemCount: 7,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const Os(hauteur: 84, rayon: 16),
        ),
      );
    }
    if (_erreurBoutiques != null && _boutiques.isEmpty) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Boutiques indisponibles',
        subtitle: _erreurBoutiques!,
        actionLabel: 'Réessayer',
        onAction: _chargerBoutiques,
      );
    }
    if (_boutiques.isEmpty) {
      return recherche.isEmpty
          ? EmptyState(
              icon: Icons.storefront_outlined,
              title: 'Boutiques en préparation',
              subtitle: 'De nouvelles boutiques ouvrent chaque semaine.',
              actionLabel: 'Réessayer',
              onAction: _chargerBoutiques,
            )
          : EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Aucune boutique trouvée',
              subtitle: 'Aucune boutique ne correspond à « $recherche ».',
              actionLabel: 'Effacer la recherche',
              onAction: _effacerFiltre,
            );
    }
    return RefreshIndicator(
      color: AppColor.kPrimary,
      onRefresh: _chargerBoutiques,
      child: ListView.separated(
        controller: _defilement,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, kEspaceBarreBas),
        itemCount: _boutiques.length + 2,
        separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 12 : 10),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Text(
              recherche.isEmpty
                  ? (_total > 1 ? '$_total boutiques' : '$_total boutique')
                  : '$_total résultat${_total > 1 ? 's' : ''} pour « $recherche »',
              style: texteDiscret(12.5),
            );
          }
          if (i == _boutiques.length + 1) {
            return _chargementSuite
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColor.kPrimary,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }
          return Apparition(
            rang: (i - 1) % 20,
            child: LigneBoutique(donnees: _boutiques[i - 1]),
          );
        },
      ),
    );
  }

  Widget _corps() {
    if (_chargement) {
      return Reflet(
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
          ),
          itemCount: 12,
          itemBuilder: (_, __) => const Os(hauteur: double.infinity, rayon: 16),
        ),
      );
    }
    if (_categories.isEmpty) {
      return EmptyState(
        icon: Icons.category_outlined,
        title: 'Catégories en préparation',
        subtitle: 'Les catégories arrivent très bientôt.',
        actionLabel: 'Réessayer',
        onAction: () => _charger(forcer: true),
      );
    }
    final promotionsVisible = _correspond('Promotions');
    final visibles = _categories.where((c) => _correspond(c.nom)).toList();
    if (!promotionsVisible && visibles.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Aucune catégorie trouvée',
        subtitle: 'Aucune catégorie ne correspond à « ${_filtre.trim()} ».',
        actionLabel: 'Effacer la recherche',
        onAction: _effacerFiltre,
      );
    }
    return RefreshIndicator(
      color: AppColor.kPrimary,
      onRefresh: () => _charger(forcer: true),
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, kEspaceBarreBas),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.1,
              ),
              delegate: SliverChildListDelegate([
                if (promotionsVisible)
                  _tuile(
                    rang: 0,
                    nom: 'Promotions',
                    icone: Icons.local_offer_rounded,
                    mise: true,
                    onTap: () => _ouvrir(
                      const ProduitsPage(titre: 'Promotions', promotions: true),
                    ),
                  ),
                for (final (i, c) in visibles.indexed)
                  _tuile(
                    rang: i + 1,
                    nom: c.nom,
                    nombre: c.nombreProduits,
                    icone: iconeCategorie(c.icone),
                    onTap: () =>
                        _ouvrir(ProduitsPage(titre: c.nom, categorie: c)),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Tuile d'une catégorie : icône en haut, nom en bas. [mise] : tuile dorée mise en avant (promotions).
  Widget _tuile({
    required int rang,
    required String nom,
    required IconData icone,
    required VoidCallback onTap,
    int? nombre,
    bool mise = false,
  }) {
    return Apparition(
      rang: rang,
      child: Pressable(
        child: _contenuTuile(
          nom: nom,
          nombre: nombre,
          icone: icone,
          onTap: onTap,
          mise: mise,
        ),
      ),
    );
  }

  Widget _contenuTuile({
    required String nom,
    required IconData icone,
    required VoidCallback onTap,
    int? nombre,
    bool mise = false,
  }) {
    return Material(
      color: AppColor.kWhite,
      borderRadius: BorderRadius.circular(16),
      shadowColor: AppColor.kPrimary.withValues(alpha: 0.12),
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: mise ? AppColor.kSecondary : AppColor.kPrimaryLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icone, color: AppColor.kPrimary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 13.5,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    // Nombre de produits en vente, sous le nom.
                    if (nombre != null || mise) ...[
                      const SizedBox(height: 2),
                      Text(
                        mise
                            ? 'Offres en cours'
                            : nombre == 0
                            ? 'Bientôt des produits'
                            : '$nombre produit${nombre! > 1 ? 's' : ''}',
                        maxLines: 1,
                        style: texteDiscret(11.5),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « Boutiques | Catégories » sous le champ de recherche.
class _SelecteurOnglet extends StatelessWidget {
  const _SelecteurOnglet({required this.onglet, required this.onChanged});

  final _Onglet onglet;
  final ValueChanged<_Onglet> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.kLine),
      ),
      child: Row(
        children: [
          _bouton(_Onglet.boutiques, Icons.storefront_rounded, 'Boutiques'),
          _bouton(_Onglet.categories, Icons.grid_view_rounded, 'Catégories'),
        ],
      ),
    );
  }

  Widget _bouton(_Onglet valeur, IconData icone, String libelle) {
    final actif = valeur == onglet;
    return Expanded(
      child: Semantics(
        selected: actif,
        button: true,
        child: GestureDetector(
          onTap: () => onChanged(valeur),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 38,
            decoration: BoxDecoration(
              color: actif ? AppColor.kPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icone,
                  size: 18,
                  color: actif ? AppColor.kWhite : AppColor.kGrayscale40,
                ),
                const SizedBox(width: 6),
                Text(
                  libelle,
                  style: TextStyle(
                    fontFamily: kPolice,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: actif ? AppColor.kWhite : AppColor.kGrayscale40,
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
