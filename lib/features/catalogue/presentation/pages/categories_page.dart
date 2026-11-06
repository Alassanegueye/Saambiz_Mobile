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
import 'produits_page.dart';

/// Onglet « Catégories » : champ de recherche, puis les catégories en
/// grille de tuiles (icône, nom). « Promotions » ouvre les promotions en
/// cours.
///
/// Le champ filtre la grille sur place, au fil de la frappe : il ne cherche
/// que parmi les catégories. La recherche de produits et de boutiques vit
/// sur l'accueil.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _ctrl = TextEditingController();
  List<Categorie> _categories = const [];
  bool _chargement = true;
  String _filtre = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
    setState(() => _filtre = '');
  }

  void _ouvrir(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return FondDegradeSubtil(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const AppAppBar(
          title: 'Catégories',
          centerTitle: true,
          implyLeading: false,
          couleurFond: Colors.transparent,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: ChampRecherche(
                controleur: _ctrl,
                indication: 'Rechercher une catégorie',
                surFondClair: true,
                onChanged: (texte) => setState(() => _filtre = texte),
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
            Expanded(child: _corps()),
          ],
        ),
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
