import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';
import '../../bloc/produit_bloc.dart';
import '../../bloc/produit_event.dart';
import '../../bloc/produit_state.dart';
import '../../../data/datasources/produit_remote_datasource.dart';
import '../../../data/models/produit_model.dart';
import '../../../../../injection_container.dart';

class _C {
  static const green      = Color(0xFF1B3A6B);
  static const greenLight = Color(0xFFE8EEF7);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7F2);
  static const surface    = Color(0xFFF7F9F5);
  static const border     = Color(0xFFF0F4EC);
  static const label      = Color(0xFF9EAA94);
  static const sub        = Color(0xFF7A8473);
  static const orange     = Color(0xFFFF5722);
  static const whatsapp   = Color(0xFF25D366);
}

// ══════════════════════════════════════════════════════════════════════════════
class ProduitPage extends StatefulWidget {
  final User? user;
  const ProduitPage({super.key, this.user});

  @override
  State<ProduitPage> createState() => _ProduitPageState();
}

class _ProduitPageState extends State<ProduitPage> {
  String           _search     = '';
  final Set<String> _favoris   = {};
  final _searchCtrl            = TextEditingController();
  ProduitRemoteDataSource? _dataSource;
  ProduitBloc?             _produitBloc;

  @override
  void initState() {
    super.initState();
    _initBloc();
  }

  Future<void> _initBloc() async {
    try {
      // Récupérés via l'injection de dépendances (Dio partagé + API_BASE_URL du .env)
      final dataSource = sl<ProduitRemoteDataSource>();
      final bloc       = sl<ProduitBloc>();
      bloc.add(LoadProduits());
      if (mounted) {
        setState(() {
          _dataSource  = dataSource;
          _produitBloc = bloc;
        });
      }
    } catch (e) {
      debugPrint('Erreur init bloc ProduitPage: $e');
    }
  }

  // ── Appel WhatsApp ─────────────────────────────────────────────
  Future<void> _contactWhatsapp(String produitId) async {
    if (_dataSource == null) return; // ✅ _dataSource pas widget.dataSource

    try {
      final url = await _dataSource!.getWhatsappUrl(produitId);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('WhatsApp non disponible',
                style: GoogleFonts.dmSans(color: _C.white)),
            backgroundColor: _C.orange,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: ${e.toString()}',
              style: GoogleFonts.dmSans(color: _C.white)),
          backgroundColor: _C.orange,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }


  @override
  void dispose() {
    _searchCtrl.dispose();
    _produitBloc?.close();
    super.dispose();
  }

  void _toggleFavori(String id) {
    setState(() {
      _favoris.contains(id) ? _favoris.remove(id) : _favoris.add(id);
    });
  }

  void _openModal(ProduitModel p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProduitModal(
        produit:        p,
        isFavori:       _favoris.contains(p.id),
        onToggleFavori: () => _toggleFavori(p.id),
        dataSource:     _dataSource,
      ),
    );
  }

  List<ProduitModel> _filter(List<ProduitModel> produits) {
    if (_search.isEmpty) return produits;
    return produits.where((p) =>
    p.nom.toLowerCase().contains(_search.toLowerCase()) ||
        p.ville.toLowerCase().contains(_search.toLowerCase()),
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildResultCount(),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _C.black,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Décoration cercle
          Stack(
            children: [
              Positioned(
                right: -10, top: -10,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.green.withOpacity(0.07),
                  ),
                ),
              ),
              // Titre
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'Les ',
                    style: GoogleFonts.sora(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: _C.white, letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Produits',
                    style: GoogleFonts.sora(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: _C.green, letterSpacing: -0.5,
                    ),
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de recherche améliorée
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.dmSans(fontSize: 15, color: _C.white),
              cursorColor: _C.green,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.4),
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: _C.green, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _C.green, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: _C.green, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Compteur résultats ─────────────────────────────────────────────────────
  Widget _buildResultCount() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Produits',
            style: GoogleFonts.sora(
              fontSize: 14, fontWeight: FontWeight.w700, color: _C.black,
            ),
          ),
          GestureDetector(
            onTap: () => _produitBloc?.add(LoadProduits()),
            child: Row(
              children: [
                Text('Actualiser',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: _C.green,
                    )),
                const SizedBox(width: 3),
                const Icon(Icons.refresh_rounded, color: _C.green, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Grille produits ────────────────────────────────────────────────────────
  Widget _buildGrid() {
    if (_produitBloc == null) {
      return const Center(
        child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5),
      );
    }

    return BlocBuilder<ProduitBloc, ProduitState>(
      bloc: _produitBloc,
      builder: (context, state) {
        if (state is ProduitLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5),
          );
        }

        if (state is ProduitError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: _C.orange, size: 48),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Erreur: ${state.message}',
                    style: GoogleFonts.dmSans(color: _C.orange),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _produitBloc?.add(LoadProduits()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _C.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Réessayer',
                        style: GoogleFonts.dmSans(
                            color: _C.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is ProduitLoaded) {
          final list = _filter(state.produits);

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, color: _C.label, size: 48),
                  const SizedBox(height: 12),
                  Text('Aucun produit trouvé',
                      style: GoogleFonts.sora(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: _C.label,
                      )),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _produitBloc?.add(LoadProduits()),
            color: _C.green,
            backgroundColor: _C.white,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   2,
                crossAxisSpacing: 12,
                mainAxisSpacing:  12,
                childAspectRatio: 0.78,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) => _buildCard(list[i]),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ── Carte produit ──────────────────────────────────────────────────────────
  Widget _buildCard(ProduitModel p) {
    return GestureDetector(
      onTap: () => _openModal(p),
      child: Container(
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                  image: p.image.isNotEmpty
                      ? DecorationImage(image: NetworkImage(p.image), fit: BoxFit.cover)
                      : null,
                ),
                child: Stack(children: [
                  if (p.image.isEmpty)
                    const Center(
                      child: Icon(Icons.storefront_rounded, size: 44, color: Colors.white54),
                    ),

                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nom,
                      style: GoogleFonts.sora(
                          fontSize: 12, fontWeight: FontWeight.w700, color: _C.black),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(p.ville,
                      style: GoogleFonts.dmSans(fontSize: 10, color: _C.label)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: p.prix,
                            style: GoogleFonts.sora(
                                fontSize: 13, fontWeight: FontWeight.w800, color: _C.black),
                          ),
                          TextSpan(
                            text: ' F',
                            style: GoogleFonts.dmSans(fontSize: 10, color: _C.label),
                          ),
                        ]),
                      ),
                      Row(
                        children: [
                          // ── Bouton WhatsApp ──────────────────────────
                          GestureDetector(
                            onTap: () => _contactWhatsapp(p.id),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: _C.whatsapp,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.chat_rounded, color: _C.white, size: 15),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // ── Bouton détail ────────────────────────────
                          GestureDetector(
                            onTap: () => _openModal(p),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: _C.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_rounded, color: _C.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODAL DÉTAIL PRODUIT
// ══════════════════════════════════════════════════════════════════════════════
// ══════════════════════════════════════════════════════════════════════════════
// MODAL DÉTAIL PRODUIT
// ══════════════════════════════════════════════════════════════════════════════
// ══════════════════════════════════════════════════════════════════════════════
// MODAL DÉTAIL PRODUIT
// ══════════════════════════════════════════════════════════════════════════════
class _ProduitModal extends StatefulWidget {
  final ProduitModel             produit;
  final bool                     isFavori;
  final VoidCallback             onToggleFavori;
  final ProduitRemoteDataSource? dataSource;

  const _ProduitModal({
    required this.produit,
    required this.isFavori,
    required this.onToggleFavori,
    required this.dataSource,
  });

  @override
  State<_ProduitModal> createState() => _ProduitModalState();
}

class _ProduitModalState extends State<_ProduitModal> {
  late bool _fav;

  @override
  void initState() {
    super.initState();
    _fav = widget.isFavori;
  }

  Future<void> _contactWhatsApp() async {
    if (widget.dataSource == null) return;
    try {
      final url = await widget.dataSource!.getWhatsappUrl(widget.produit.id);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('WhatsApp non disponible',
                style: GoogleFonts.dmSans(color: _C.white)),
            backgroundColor: _C.black,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: ${e.toString()}',
              style: GoogleFonts.dmSans(color: _C.white)),
          backgroundColor: _C.orange,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produit;
    // Prix : on le laisse tel quel, pas de calcul de total
    final prixUnitaire = p.prix;

    return Container(
      decoration: const BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3EAD0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Container(
                    height: 200,
                    margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(20),
                      image: p.image.isNotEmpty
                          ? DecorationImage(image: NetworkImage(p.image), fit: BoxFit.cover)
                          : null,
                    ),
                    child: Stack(children: [
                      if (p.image.isEmpty)
                        const Center(
                          child: Icon(Icons.storefront_rounded, size: 72, color: Colors.white38),
                        ),
                      Positioned(
                        top: 10, right: 10,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 16, color: _C.black),
                          ),
                        ),
                      ),
                    ]),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom + favori
                        Row(
                          children: [
                            Expanded(
                              child: Text(p.nom,
                                  style: GoogleFonts.sora(
                                    fontSize: 20, fontWeight: FontWeight.w800,
                                    color: _C.black, letterSpacing: -0.5,
                                  )),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() => _fav = !_fav);
                                widget.onToggleFavori();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: _fav
                                      ? const Color(0xFFFEF3F2)
                                      : const Color(0xFFF5F7F2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 18,
                                  color: _fav ? const Color(0xFFE53935) : _C.label,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Catégorie (chip)
                        if (p.categorie != null && p.categorie!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _C.greenLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              p.categorie!,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _C.green,
                              ),
                            ),
                          ),

                        // Ville
                        Row(children: [
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: _C.greenLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on_outlined, color: _C.green, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Text(p.ville,
                              style: GoogleFonts.dmSans(fontSize: 13, color: _C.label)),
                        ]),
                        const SizedBox(height: 16),

                        // Description
                        if (p.description != null && p.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              p.description!,
                              style: GoogleFonts.dmSans(fontSize: 13, color: _C.sub),
                            ),
                          ),

                        // Quantité en stock (si disponible)
                        if (p.quantite != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 26, height: 26,
                                  decoration: BoxDecoration(
                                    color: _C.greenLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.inventory_2_rounded, color: _C.green, size: 14),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Stock disponible : ${p.quantite}',
                                  style: GoogleFonts.dmSans(fontSize: 13, color: _C.label),
                                ),
                              ],
                            ),
                          ),

                        // INFOS VENDEUR
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _C.bg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _C.greenLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.storefront_rounded, color: _C.green, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.vendeurNom,
                                      style: GoogleFonts.sora(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _C.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Vendeur',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: _C.label,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final uri = Uri.parse('tel:${p.vendeurNumero}');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone_rounded, size: 14, color: _C.green),
                                    const SizedBox(width: 4),
                                    Text(p.vendeurNumero,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _C.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Prix unitaire (sans total)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _C.bg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('PRIX UNITAIRE',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 9.5, fontWeight: FontWeight.w700,
                                          color: _C.label, letterSpacing: 0.6,
                                        )),
                                    const SizedBox(height: 3),
                                    RichText(
                                      text: TextSpan(children: [
                                        TextSpan(
                                          text: '$prixUnitaire ',
                                          style: GoogleFonts.sora(
                                            fontSize: 22, fontWeight: FontWeight.w800,
                                            color: _C.black,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'FCFA',
                                          style: GoogleFonts.dmSans(fontSize: 12, color: _C.label),
                                        ),
                                      ]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Boutons d'action
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _contactWhatsApp,
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _C.whatsapp,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _C.whatsapp.withOpacity(0.35),
                          blurRadius: 12, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.chat_rounded, color: _C.white, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _C.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'Fermer',
                          style: GoogleFonts.dmSans(
                            color: _C.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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