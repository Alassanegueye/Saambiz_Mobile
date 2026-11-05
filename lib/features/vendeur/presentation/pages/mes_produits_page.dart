import 'package:saambiz/core/widgets/onglets_conserves.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/widgets/ui_kit.dart';
import '../../../catalogue/presentation/widgets/produit_card.dart'
    show formaterPrix;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../injection_container.dart';
import '../../../home/data/models/produit_model.dart';
import '../bloc/vendeur_produit_bloc.dart';
import 'produit_form_page.dart';
import 'package:saambiz/core/utils/image_url.dart';
import 'package:saambiz/core/utils/texte.dart';

class _C {
  static const green = Color(0xFF01154B);
  static const navyDk = Color(0xFF060F26);
  static const gold = Color(0xFFFBB900);
  static const black = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F8);
  static const sub = Color(0xFF5B6C8A);
  static const border = Color(0xFFE6EAF0);
  static const success = Color(0xFF1E9E62);
  static const danger = Color(0xFFD64533);
  static const greenLight = Color(0xFFE8EEF7);
}

class MesProduitsPage extends StatelessWidget {
  const MesProduitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VendeurProduitBloc>()..add(LoadMesProduits()),
      child: ActualiserAuRetour(
        onRetour: (context) =>
            context.read<VendeurProduitBloc>().add(LoadMesProduits()),
        child: const _MesProduitsView(),
      ),
    );
  }
}

class _MesProduitsView extends StatefulWidget {
  const _MesProduitsView();

  @override
  State<_MesProduitsView> createState() => _MesProduitsViewState();
}

class _MesProduitsViewState extends State<_MesProduitsView> {
  int _tab = 0; // 0 = Tous, 1 = En ligne, 2 = Hors ligne
  bool _rechercheOuverte = false;
  String _recherche = '';

  // Un produit est "en ligne" s'il a du stock disponible.
  bool _enLigne(ProduitModel p) => p.quantite > 0;

  Future<void> _ouvrirForm(BuildContext context, {dynamic produit}) async {
    final bloc = context.read<VendeurProduitBloc>();
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProduitFormPage(produit: produit)),
    );
    if (res == true) bloc.add(LoadMesProduits());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ouvrirForm(context),
        backgroundColor: AppColor.kSecondary,
        foregroundColor: AppColor.kPrimary,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Ajouter',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: BlocConsumer<VendeurProduitBloc, VendeurProduitState>(
                buildWhen: (avant, apres) =>
                    !(apres is VendeurProduitLoading &&
                        avant is VendeurProduitLoaded),
                listener: (context, state) {
                  if (state is VendeurProduitError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: _C.danger,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is VendeurProduitLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: _C.green),
                    );
                  }
                  if (state is VendeurProduitError) {
                    return _buildError(context, state.message);
                  }
                  if (state is VendeurProduitLoaded) {
                    final all = state.produits;
                    final enLigne = all.where(_enLigne).toList();
                    final horsLigne = all.where((p) => !_enLigne(p)).toList();
                    final shown =
                        (_tab == 1
                                ? enLigne
                                : _tab == 2
                                ? horsLigne
                                : all)
                            .where((p) => contientRecherche(p.nom, _recherche))
                            .toList();

                    return Column(
                      children: [
                        _buildTabs(
                          all.length,
                          enLigne.length,
                          horsLigne.length,
                        ),
                        Expanded(
                          child: shown.isEmpty
                              ? _buildEmpty()
                              : RefreshIndicator(
                                  color: _C.green,
                                  onRefresh: () async => context
                                      .read<VendeurProduitBloc>()
                                      .add(LoadMesProduits()),
                                  child: ListView.separated(
                                    // Le bas laisse la place au bouton Ajouter.
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      4,
                                      16,
                                      88,
                                    ),
                                    itemCount: shown.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (_, i) =>
                                        _buildCard(context, shown[i]),
                                  ),
                                ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Barre du haut, bleu foncé comme les autres écrans : titre + recherche
  Widget _buildTopBar(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        color: AppColor.kPrimary,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                if (Navigator.of(context).canPop())
                  const BackButton(color: AppColor.kWhite)
                else
                  const SizedBox(width: 16),
                Expanded(
                  child: _rechercheOuverte
                      ? TextField(
                          autofocus: true,
                          onChanged: (v) => setState(() => _recherche = v),
                          cursorColor: AppColor.kSecondary,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColor.kWhite,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un produit',
                            hintStyle: GoogleFonts.inter(
                              color: AppColor.kWhite.withValues(alpha: 0.6),
                            ),
                            isDense: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        )
                      : Text(
                          'Mes produits',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColor.kWhite,
                          ),
                        ),
                ),
                IconButton(
                  tooltip: _rechercheOuverte
                      ? 'Fermer la recherche'
                      : 'Rechercher',
                  onPressed: () => setState(() {
                    _rechercheOuverte = !_rechercheOuverte;
                    if (!_rechercheOuverte) _recherche = '';
                  }),
                  icon: Icon(
                    _rechercheOuverte
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                    color: AppColor.kWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Filtres Tous / En ligne / Hors ligne
  Widget _buildTabs(int total, int enLigne, int horsLigne) {
    final filtres = [
      'Tous ($total)',
      'En ligne ($enLigne)',
      'Hors ligne ($horsLigne)',
    ];
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        children: [
          for (var i = 0; i < filtres.length; i++) ...[
            PuceFiltre(
              libelle: filtres[i],
              active: _tab == i,
              onTap: () => setState(() => _tab = i),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  // Carte produit
  Widget _buildCard(BuildContext context, ProduitModel p) {
    final enLigne = _enLigne(p);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: p.image.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageOptimisee(p.image),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _imgFallback(),
                  )
                : _imgFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formaterPrix(double.tryParse(p.prix) ?? 0),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.green,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  enLigne
                      ? 'En ligne · ${p.quantite} en stock'
                      : 'Hors ligne · rupture de stock',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: enLigne ? _C.success : _C.sub,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enLigne,
            activeColor: _C.green,
            onChanged: (_) => context.read<VendeurProduitBloc>().add(
              ToggleDispoProduit(p.id),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: _C.sub, size: 20),
            onSelected: (v) {
              final bloc = context.read<VendeurProduitBloc>();
              if (v == 'edit') {
                _ouvrirForm(context, produit: p);
              } else if (v == 'delete') {
                _confirmerSuppression(context, bloc, p.id);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Modifier')),
              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, color: _C.sub, size: 46),
          const SizedBox(height: 12),
          Text(
            'Aucun produit ici',
            style: GoogleFonts.inter(fontSize: 14, color: _C.sub),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: _C.danger, size: 44),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _C.sub),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                context.read<VendeurProduitBloc>().add(LoadMesProduits()),
            child: Text(
              'Réessayer',
              style: GoogleFonts.inter(
                color: _C.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmerSuppression(
    BuildContext context,
    VendeurProduitBloc bloc,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(SupprimerProduit(id));
            },
            child: const Text('Supprimer', style: TextStyle(color: _C.danger)),
          ),
        ],
      ),
    );
  }

  Widget _imgFallback() => Container(
    width: 58,
    height: 58,
    color: _C.greenLight,
    child: const Icon(Icons.image_not_supported_outlined, color: _C.sub),
  );
}
