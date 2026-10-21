import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../injection_container.dart';
import '../../../home/data/models/produit_model.dart';
import '../bloc/vendeur_produit_bloc.dart';
import 'produit_form_page.dart';
import 'package:saambiz/core/utils/image_url.dart';

class _C {
  static const green   = Color(0xFF0D1B3D);
  static const navyDk  = Color(0xFF060F26);
  static const gold    = Color(0xFFF2B705);
  static const black   = Color(0xFF0D1B3D);
  static const white   = Color(0xFFFFFFFF);
  static const bg      = Color(0xFFF7F8FA);
  static const sub     = Color(0xFF5B6C8A);
  static const border  = Color(0xFFE6EAF0);
  static const success = Color(0xFF1E9E62);
  static const danger  = Color(0xFFD64533);
  static const greenLight = Color(0xFFE8EEF7);
}

class MesProduitsPage extends StatelessWidget {
  const MesProduitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VendeurProduitBloc>()..add(LoadMesProduits()),
      child: const _MesProduitsView(),
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: BlocConsumer<VendeurProduitBloc, VendeurProduitState>(
                listener: (context, state) {
                  if (state is VendeurProduitError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: _C.danger),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is VendeurProduitLoading) {
                    return const Center(child: CircularProgressIndicator(color: _C.green));
                  }
                  if (state is VendeurProduitError) {
                    return _buildError(context, state.message);
                  }
                  if (state is VendeurProduitLoaded) {
                    final all = state.produits;
                    final enLigne = all.where(_enLigne).toList();
                    final horsLigne = all.where((p) => !_enLigne(p)).toList();
                    final shown = _tab == 1 ? enLigne : _tab == 2 ? horsLigne : all;

                    return Column(
                      children: [
                        _buildTabs(all.length, enLigne.length, horsLigne.length),
                        Expanded(
                          child: shown.isEmpty
                              ? _buildEmpty()
                              : RefreshIndicator(
                                  color: _C.green,
                                  onRefresh: () async => context
                                      .read<VendeurProduitBloc>()
                                      .add(LoadMesProduits()),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                    itemCount: shown.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (_, i) => _buildCard(context, shown[i]),
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
            _buildAddButton(context),
          ],
        ),
      ),
    );
  }

  // ── Barre du haut : titre + recherche ─────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _C.black),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text('Mes produits',
                style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: _C.black)),
          ),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.search_rounded, color: _C.green, size: 21),
          ),
        ],
      ),
    );
  }

  // ── Onglets Tous / En ligne / Hors ligne ──────────────────────────────────
  Widget _buildTabs(int total, int enLigne, int horsLigne) {
    final tabs = [
      'Tous ($total)',
      'En ligne ($enLigne)',
      'Hors ligne ($horsLigne)',
    ];
    return Container(
      color: _C.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? _C.green : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? _C.green : _C.sub,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Carte produit ─────────────────────────────────────────────────────────
  Widget _buildCard(BuildContext context, ProduitModel p) {
    final enLigne = _enLigne(p);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: p.image.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageOptimisee(p.image),
                    width: 58, height: 58, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _imgFallback(),
                  )
                : _imgFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nom,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: _C.black)),
                const SizedBox(height: 3),
                Text('${p.prix} FCFA',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: _C.sub)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: enLigne ? _C.success : _C.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(enLigne ? 'En ligne' : 'Hors ligne',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: enLigne ? _C.success : _C.danger)),
                ]),
              ],
            ),
          ),
          Switch.adaptive(
            value: enLigne,
            activeColor: _C.green,
            onChanged: (_) => context.read<VendeurProduitBloc>().add(ToggleDispoProduit(p.id)),
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

  // ── Bouton « Ajouter un produit » ─────────────────────────────────────────
  Widget _buildAddButton(BuildContext context) {
    return Container(
      color: _C.white,
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _ouvrirForm(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text('Ajouter un produit',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.green,
            foregroundColor: _C.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.inventory_2_outlined, color: _C.sub, size: 46),
        const SizedBox(height: 12),
        Text('Aucun produit ici',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _C.sub)),
      ]),
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
            child: Text(message, textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: _C.sub)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.read<VendeurProduitBloc>().add(LoadMesProduits()),
            child: Text('Réessayer', style: GoogleFonts.plusJakartaSans(color: _C.green, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmerSuppression(BuildContext context, VendeurProduitBloc bloc, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
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
        width: 58, height: 58, color: _C.greenLight,
        child: const Icon(Icons.image_not_supported_outlined, color: _C.sub),
      );
}
