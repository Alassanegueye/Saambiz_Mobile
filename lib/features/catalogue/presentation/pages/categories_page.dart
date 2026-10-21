import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/barre_navigation_verre.dart' show kEspaceBarreBas;
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../categories/data/categorie.dart';
import '../../../categories/presentation/icones_categories.dart';
import 'produits_page.dart';

/// Onglet « Catégories » — même écran que Yobante Boutique : titre centré,
/// champ de recherche, puis la liste des catégories en lignes (pastille
/// d'icône, nom, chevron). « Promotions » ouvre les promotions en cours.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _ctrl = TextEditingController();
  List<Categorie> _categories = const [];
  bool _chargement = true;

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
    final liste = await CategoriesRemoteDataSource(sl<Dio>()).lister(forcer: forcer);
    if (!mounted) return;
    setState(() {
      _categories = liste;
      _chargement = false;
    });
  }

  void _rechercher(String texte) {
    if (texte.trim().isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProduitsPage(titre: 'Résultats', recherche: texte.trim()),
    ));
  }

  void _ouvrir(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: const AppAppBar(title: 'Catégories', implyLeading: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: ChampRecherche(
              controleur: _ctrl,
              surFondClair: true,
              onSubmitted: _rechercher,
            ),
          ),
          Expanded(child: _corps()),
        ],
      ),
    );
  }

  Widget _corps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
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
    return RefreshIndicator(
      color: AppColor.kPrimary,
      onRefresh: () => _charger(forcer: true),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, kEspaceBarreBas),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const EnteteSection('Nos catégories'),
          const SizedBox(height: 10),
          _ligne(
            nom: 'Promotions',
            icone: Icons.local_offer_outlined,
            onTap: () => _ouvrir(const ProduitsPage(titre: 'Promotions', promotions: true)),
          ),
          const SizedBox(height: 8),
          for (final c in _categories) ...[
            _ligne(
              nom: c.nom,
              icone: iconeCategorie(c.icone),
              onTap: () => _ouvrir(ProduitsPage(titre: c.nom, categorie: c)),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  /// Ligne d'une catégorie : pastille d'icône, nom, flèche.
  Widget _ligne({required String nom, required IconData icone, required VoidCallback onTap}) {
    return Material(
      color: AppColor.kWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColor.kPrimaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: AppColor.kPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nom.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColor.kGrayscale40),
            ],
          ),
        ),
      ),
    );
  }
}
