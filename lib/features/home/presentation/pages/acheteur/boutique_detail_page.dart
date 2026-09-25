import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/boutique_model.dart';
import '../../../data/models/produit_model.dart';
import '../../../data/datasources/produit_remote_datasource.dart';
import '../../../../../injection_container.dart';
import '../../../../promotions/data/datasources/promotions_remote_datasource.dart';
import '../../../../promotions/data/models/promotion_model.dart';

class _C {
  static const green   = Color(0xFF1B3A6B);
  static const navyDk  = Color(0xFF0F2547);
  static const gold    = Color(0xFFD4A72C);
  static const black   = Color(0xFF1A1A1A);
  static const white   = Color(0xFFFFFFFF);
  static const bg      = Color(0xFFF7F8FA);
  static const sub     = Color(0xFF7A8473);
  static const label   = Color(0xFF9EAA94);
  static const border  = Color(0xFFE6EAF0);
  static const greenLight = Color(0xFFE8EEF7);
  static const surface = Color(0xFFF2F4F7);
}

class BoutiqueDetailPage extends StatefulWidget {
  final BoutiqueModel boutique;
  final ProduitRemoteDataSource? dataSource;

  const BoutiqueDetailPage({super.key, required this.boutique, this.dataSource});

  @override
  State<BoutiqueDetailPage> createState() => _BoutiqueDetailPageState();
}

class _BoutiqueDetailPageState extends State<BoutiqueDetailPage> {
  int _tab = 0; // 0 Produits, 1 Promotions, 2 Avis
  bool _suivi = false;

  List<ProduitModel> _produits = [];
  List<PromotionModel> _promos = [];
  bool _loading = true;
  String? _error;

  // ⭐ Avis
  List<dynamic> _avis = [];
  double _avisMoyenne = 0;
  int _avisTotal = 0;

  double get _effNote  => _avisTotal > 0 ? _avisMoyenne : b.note;
  int    get _effTotal => _avisTotal > 0 ? _avisTotal : b.nombreAvis;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.dataSource == null) {
      setState(() { _loading = false; _error = 'Source de données indisponible'; });
      return;
    }
    try {
      final list = await widget.dataSource!.getProduitsByBoutique(widget.boutique.id);
      if (mounted) setState(() { _produits = list; _loading = false; });

      // Promotions actives filtrées sur les produits de cette boutique
      try {
        final promos = await sl<PromotionsRemoteDataSource>().promotionsActives();
        final ids = list.map((p) => p.id).toSet();
        if (mounted) {
          setState(() => _promos = promos.where((pr) => ids.contains(pr.produitId)).toList());
        }
      } catch (_) {/* non bloquant */}

      // Avis de la boutique
      await _loadAvis();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadAvis() async {
    if (widget.dataSource == null) return;
    try {
      final data = await widget.dataSource!.getAvisBoutique(widget.boutique.id);
      if (!mounted) return;
      setState(() {
        _avisMoyenne = (data['moyenne'] is num) ? (data['moyenne'] as num).toDouble() : 0;
        _avisTotal   = (data['total'] is num) ? (data['total'] as num).toInt() : 0;
        _avis        = (data['avis'] is List) ? data['avis'] as List : [];
      });
    } catch (_) {/* non bloquant */}
  }

  BoutiqueModel get b => widget.boutique;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildTabs()),
          SliverToBoxAdapter(child: _buildTabContent()),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  // ── En-tête (cover + infos boutique) ──────────────────────────────────────
  Widget _buildHeader() {
    final hasLogo = b.logo != null && b.logo!.isNotEmpty;
    return Column(
      children: [
        // Cover + barre d'actions
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 170,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_C.green, _C.navyDk],
                ),
              ),
              child: (hasLogo)
                  ? Opacity(opacity: 0.25, child: Image.network(b.logo!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox()))
                  : null,
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    _circleBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.of(context).pop()),
                    Expanded(
                      child: Text('Boutique', textAlign: TextAlign.center,
                          style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: _C.white)),
                    ),
                    _circleBtn(Icons.share_outlined, () {}),
                    const SizedBox(width: 6),
                    _circleBtn(Icons.more_vert_rounded, () {}),
                  ],
                ),
              ),
            ),
            // Logo rond à cheval
            Positioned(
              bottom: -44, left: 20,
              child: Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: _C.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.white, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                clipBehavior: Clip.antiAlias,
                child: hasLogo
                    ? Image.network(b.logo!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: _C.green, size: 36))
                    : const Icon(Icons.storefront_rounded, color: _C.green, size: 36),
              ),
            ),
          ],
        ),
        const SizedBox(height: 54),

        // Infos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.nom,
                  style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800, color: _C.black)),
              const SizedBox(height: 6),
              Row(children: [
                if (_effTotal > 0) ...[
                  const Icon(Icons.star_rounded, color: _C.gold, size: 17),
                  const SizedBox(width: 3),
                  Text(_effNote.toStringAsFixed(1),
                      style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: _C.black)),
                  const SizedBox(width: 4),
                  Text('($_effTotal avis)', style: GoogleFonts.dmSans(fontSize: 13, color: _C.sub)),
                ] else ...[
                  const Icon(Icons.star_border_rounded, color: _C.label, size: 17),
                  const SizedBox(width: 3),
                  Text('Nouveau', style: GoogleFonts.dmSans(fontSize: 13, color: _C.sub)),
                ],
                if (b.localisation.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('•', style: GoogleFonts.dmSans(fontSize: 13, color: _C.label)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(b.localisation,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(fontSize: 13, color: _C.sub)),
                  ),
                ],
              ]),
              if (b.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(b.description,
                    style: GoogleFonts.dmSans(fontSize: 13.5, height: 1.4, color: _C.sub)),
              ],
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                    label: Text('Message', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.green,
                      side: const BorderSide(color: _C.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _suivi = !_suivi),
                    icon: Icon(_suivi ? Icons.check_rounded : Icons.add_rounded, size: 18),
                    label: Text(_suivi ? 'Suivi' : 'Suivre',
                        style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.green,
                      foregroundColor: _C.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
        child: Icon(icon, color: _C.white, size: 18),
      ),
    );
  }

  // ── Onglets ───────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    const tabs = ['Produits', 'Promotions', 'Avis'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: active ? _C.green : _C.border, width: active ? 2.5 : 1),
                  ),
                ),
                child: Text(tabs[i], textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? _C.green : _C.sub)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 1:
        return _buildPromotions();
      case 2:
        return _buildAvis();
      default:
        return _buildProduits();
    }
  }

  // ── Onglet Produits ───────────────────────────────────────────────────────
  Widget _buildProduits() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Center(child: Text(_error!, style: GoogleFonts.dmSans(color: _C.sub))),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Produits populaires'),
        if (_produits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Text('Aucun produit disponible', style: GoogleFonts.dmSans(color: _C.label)),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.78),
              itemCount: _produits.length,
              itemBuilder: (_, i) => _productCard(_produits[i]),
            ),
          ),
      ],
    );
  }

  Widget _productCard(ProduitModel p) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                image: p.image.isNotEmpty
                    ? DecorationImage(image: NetworkImage(p.image), fit: BoxFit.cover)
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _C.black)),
                const SizedBox(height: 4),
                Text('${p.prix} FCFA',
                    style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Onglet Promotions (données réelles) ───────────────────────────────────
  Widget _buildPromotions() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5)),
      );
    }
    if (_promos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
        child: Center(
          child: Column(children: [
            const Icon(Icons.local_offer_outlined, color: _C.label, size: 44),
            const SizedBox(height: 12),
            Text('Aucune promotion en cours',
                style: GoogleFonts.dmSans(fontSize: 14, color: _C.sub)),
          ]),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Promotions en cours'),
        ..._promos.map((promo) => Container(
          margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_C.green, _C.navyDk]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(promo.titre,
                        style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w800, color: _C.gold)),
                    if ((promo.produitNom ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(promo.produitNom!,
                          style: GoogleFonts.dmSans(fontSize: 13, color: _C.white.withOpacity(0.9))),
                    ],
                    const SizedBox(height: 6),
                    Text('${promo.prixPromo.toStringAsFixed(0)} FCFA',
                        style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800, color: _C.white)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: _C.gold, borderRadius: BorderRadius.circular(11)),
                      child: Text("Profiter de l'offre",
                          style: GoogleFonts.sora(fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.navyDk)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.local_offer_rounded, color: Colors.white24, size: 60),
            ],
          ),
        )),
      ],
    );
  }

  // ── Onglet Avis (données réelles) ─────────────────────────────────────────
  Widget _buildAvis() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé note moyenne
          Row(
            children: [
              Text(_effTotal > 0 ? _effNote.toStringAsFixed(1) : '—',
                  style: GoogleFonts.sora(fontSize: 34, fontWeight: FontWeight.w800, color: _C.black)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: List.generate(5, (i) => Icon(
                    i < _effNote.round() ? Icons.star_rounded : Icons.star_border_rounded,
                    color: _C.gold, size: 18,
                  ))),
                  const SizedBox(height: 2),
                  Text('$_effTotal avis',
                      style: GoogleFonts.dmSans(fontSize: 13, color: _C.sub)),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _ouvrirFormAvis,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(12)),
                  child: Text('Donner mon avis',
                      style: GoogleFonts.sora(fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_avis.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Aucun avis pour le moment. Soyez le premier !',
                    style: GoogleFonts.dmSans(fontSize: 14, color: _C.sub)),
              ),
            )
          else
            ..._avis.map((a) => _avisCard(a as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _avisCard(Map<String, dynamic> a) {
    final acheteur = (a['acheteur'] as Map?) ?? const {};
    final nom = '${acheteur['prenom'] ?? ''} ${acheteur['nom'] ?? ''}'.trim();
    final note = (a['note'] is num) ? (a['note'] as num).toInt() : 0;
    final commentaire = (a['commentaire'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: const BoxDecoration(color: _C.greenLight, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, color: _C.green, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(nom.isEmpty ? 'Client' : nom,
                  style: GoogleFonts.sora(fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.black)),
            ),
            Row(children: List.generate(5, (i) => Icon(
              i < note ? Icons.star_rounded : Icons.star_border_rounded,
              color: _C.gold, size: 14,
            ))),
          ]),
          if (commentaire.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(commentaire,
                style: GoogleFonts.dmSans(fontSize: 13, height: 1.4, color: _C.sub)),
          ],
        ],
      ),
    );
  }

  Future<void> _ouvrirFormAvis() async {
    int note = 5;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Votre avis', style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  onPressed: () => setLocal(() => note = i + 1),
                  icon: Icon(i < note ? Icons.star_rounded : Icons.star_border_rounded,
                      color: _C.gold, size: 30),
                )),
              ),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Votre commentaire (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.green, foregroundColor: _C.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Publier'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || widget.dataSource == null) return;
    try {
      await widget.dataSource!.laisserAvis(widget.boutique.id, note, ctrl.text.trim());
      await _loadAvis();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merci pour votre avis !')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connectez-vous pour laisser un avis.')),
        );
      }
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: _C.black)),
          Text('Voir tout', style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: _C.green)),
        ],
      ),
    );
  }
}
