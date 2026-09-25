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
import '../../../data/models/boutique_model.dart';
import '../../../../../injection_container.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../vendeur/domain/usecases/get_vendeur_dashboard.dart';
import '../../../../commande/data/datasources/commande_remote_datasource.dart';
import '../../../../commande/data/models/commande_model.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';


class _C {
  static const green       = Color(0xFF1B3A6B); // navy (héritage de nom)
  static const navyDk      = Color(0xFF0F2547);
  static const gold        = Color(0xFFD4A72C);
  static const greenLight  = Color(0xFFE8EEF7);
  static const black       = Color(0xFF1A1A1A);
  static const white       = Color(0xFFFFFFFF);
  static const success     = Color(0xFF1E9E62);
  static const bg          = Color(0xFFF7F8FA);
  static const surface     = Color(0xFFF7F9F5);
  static const border      = Color(0xFFF0F4EC);
  static const label       = Color(0xFF9EAA94);
  static const sub         = Color(0xFF7A8473);
  static const orange      = Color(0xFFFF5722);
  static const amber       = Color(0xFFFF9800);
  static const whatsapp    = Color(0xFF25D366);
}

class HomePage extends StatefulWidget {
  final User? user;
  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _loading     = false;
  int  _nbCommandes = 0;
  int  _nbFavoris   = 0;

  // ── Tableau de bord (données réelles via /vendeur/dashboard) ──
  String _ventes  = '—';
  String _visites = '—';
  String _clients = '—';
  int    _commandesCount = 0;
  int    _notifNonLues = 0; // 🔔 notifications non lues (via dashboard)
  List<CommandeModel> _recentOrders = [];

  List<BoutiqueModel> _boutiques      = [];
  bool                _boutiquesLoad  = false;
  String?             _boutiquesError;

  late AnimationController _headerCtrl;
  late Animation<double>   _headerFade;
  late Animation<Offset>   _headerSlide;

  late AnimationController _contentCtrl;
  late Animation<double>   _contentFade;

  ProduitRemoteDataSource? _dataSource;
  ProduitBloc?             _produitBloc;

  @override
  void initState() {
    super.initState();
    _headerCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 250), () { if (mounted) _contentCtrl.forward(); });
    _loadStats();
    _initBloc();
  }

  Future<void> _initBloc() async {
    try {
      // Récupérés via l'injection de dépendances (Dio partagé + API_BASE_URL du .env)
      final dataSource = sl<ProduitRemoteDataSource>();
      final bloc       = sl<ProduitBloc>();
      bloc.add(LoadProduits());
      if (mounted) {
        setState(() { _dataSource = dataSource; _produitBloc = bloc; });
        _fetchBoutiques();
      }
    } catch (e) {
      debugPrint('Erreur init bloc: $e');
    }
  }

  Future<void> _fetchBoutiques() async {
    if (_dataSource == null) return;
    setState(() { _boutiquesLoad = true; _boutiquesError = null; });
    try {
      final list = await _dataSource!.getBoutiques();
      if (mounted) setState(() { _boutiques = list; _boutiquesLoad = false; });
    } catch (e) {
      if (mounted) setState(() { _boutiquesError = e.toString(); _boutiquesLoad = false; });
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _contentCtrl.dispose();
    _produitBloc?.close();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    // 1) Stats du tableau de bord (chiffre d'affaires, commandes, vues, abonnés)
    try {
      final res = await sl<GetVendeurDashboard>().call();
      res.fold((_) {}, (data) {
        final stats = (data['stats'] as Map?) ?? const {};
        if (!mounted) return;
        setState(() {
          _ventes         = _fmtNombre(stats['chiffreAffaires']);
          _commandesCount = _toInt(stats['nombreCommandes']);
          _nbCommandes    = _commandesCount;
          _visites        = _toInt(stats['totalVues']).toString();
          _clients        = _toInt(stats['nombreAbonnes']).toString();
          _notifNonLues   = _toInt(data['notificationsNonLues']);
        });
      });
    } catch (e) {
      debugPrint('dashboard stats error: $e');
    }
    // 2) Commandes récentes (3 dernières)
    try {
      final orders = await sl<CommandeRemoteDataSource>().commandesVendeur();
      if (mounted) setState(() => _recentOrders = orders.take(3).toList());
    } catch (e) {
      debugPrint('commandes récentes error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString().split('.').first) ?? 0;
  }

  // Formate 125000 -> "125 000"
  String _fmtNombre(dynamic v) {
    final n = _toInt(v);
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _timeAgo(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  ({String label, Color color}) _statutInfo(String statut) {
    switch (statut.toLowerCase()) {
      case 'livree':
        return (label: 'Livrée', color: _C.success);
      case 'confirmee':
        return (label: 'Confirmée', color: _C.green);
      case 'annulee':
        return (label: 'Annulée', color: _C.orange);
      case 'en_cours':
        return (label: 'En cours', color: _C.amber);
      case 'en_attente':
      default:
        return (label: 'En attente', color: _C.amber);
    }
  }

  void _openNotifications() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const NotificationsPage(),
    ));
    _loadStats(); // rafraîchir le badge (notificationsNonLues) au retour
  }

  // ── Ouvrir la bottom sheet d'une boutique ─────────────────────────────────
  void _openBoutiqueSheet(BoutiqueModel boutique) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BoutiqueSheet(
        boutique: boutique,
        dataSource: _dataSource,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: RefreshIndicator(
        onRefresh: () async {
          _produitBloc?.add(LoadProduits());
          await Future.wait([_loadStats(), _fetchBoutiques()]);
        },
        color: _C.green,
        backgroundColor: _C.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(position: _headerSlide, child: _buildDashHeader()),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _contentFade,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDashTitle(),
                    _buildStatCards(),
                    _buildRecentOrders(),
                    _buildNewProductButton(),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── En-tête tableau de bord (navy) ────────────────────────────────────────
  Widget _buildDashHeader() {
    final boutiqueNom = _boutiques.isNotEmpty
        ? _boutiques.first.nom
        : 'Ma boutique';
    final hasLogo = _boutiques.isNotEmpty &&
        _boutiques.first.logo != null &&
        _boutiques.first.logo!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.green, _C.navyDk],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 18, 26),
          child: Row(
            children: [
              // Logo boutique
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: _C.white,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: hasLogo
                    ? Image.network(_boutiques.first.logo!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.storefront_rounded, color: _C.green, size: 26))
                    : const Icon(Icons.storefront_rounded, color: _C.green, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(boutiqueNom,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w800, color: _C.white)),
                    const SizedBox(height: 3),
                    GestureDetector(
                      onTap: () {
                        if (_boutiques.isNotEmpty) _openBoutiqueSheet(_boutiques.first);
                      },
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Voir ma boutique',
                            style: GoogleFonts.dmSans(fontSize: 13, color: _C.gold, fontWeight: FontWeight.w600)),
                        const Icon(Icons.chevron_right_rounded, color: _C.gold, size: 18),
                      ]),
                    ),
                  ],
                ),
              ),
              // Cloche cliquable + badge non-lues
              GestureDetector(
                onTap: _openNotifications,
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.notifications_none_rounded, color: _C.white, size: 22),
                  ),
                  if (_notifNonLues > 0)
                    Positioned(
                      top: -4, right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD64533),
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.navyDk, width: 2),
                        ),
                        child: Text(
                          _notifNonLues > 99 ? '99+' : '$_notifNonLues',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Titre + période ───────────────────────────────────────────────────────
  Widget _buildDashTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Tableau de bord',
              style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: _C.black)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _C.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text("Aujourd'hui",
                  style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: _C.sub)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _C.sub),
            ]),
          ),
        ],
      ),
    );
  }

  // ── 4 cartes de statistiques (2×2) ────────────────────────────────────────
  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _statCard('Ventes', _ventes, 'FCFA', null)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Commandes', _commandesCount.toString(), null, null)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _statCard('Visites', _visites, null, null)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Clients', _clients, null, null)),
          ]),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String? unit, String? delta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: _C.sub, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(value,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w800, color: _C.black)),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(unit, style: GoogleFonts.dmSans(fontSize: 11, color: _C.sub)),
              ],
            ],
          ),
          if (delta != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.arrow_upward_rounded, size: 13, color: _C.success),
              const SizedBox(width: 2),
              Text(delta, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: _C.success)),
            ]),
          ],
        ],
      ),
    );
  }

  // ── Commandes récentes ────────────────────────────────────────────────────
  Widget _buildRecentOrders() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commandes récentes',
                  style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: _C.black)),
              Text('Voir tout',
                  style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: _C.green)),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentOrders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _C.border),
              ),
              child: Text('Aucune commande récente',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 13, color: _C.label)),
            )
          else
            ..._recentOrders.map((o) {
              final st = _statutInfo(o.statut);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _C.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: _C.greenLight,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: _C.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('#${o.referenceCommande}',
                                style: GoogleFonts.sora(fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.black)),
                            const SizedBox(width: 8),
                            Text('${_fmtNombre(o.montantTotal)} FCFA',
                                style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _C.green)),
                          ]),
                          const SizedBox(height: 3),
                          Row(children: [
                            Flexible(
                              child: Text(o.acheteurNom ?? 'Client',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(fontSize: 12, color: _C.sub)),
                            ),
                            const SizedBox(width: 6),
                            Text('•', style: GoogleFonts.dmSans(fontSize: 12, color: _C.label)),
                            const SizedBox(width: 6),
                            Text(st.label,
                                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: st.color)),
                          ]),
                        ],
                      ),
                    ),
                    Text(_timeAgo(o.createdAt),
                        style: GoogleFonts.dmSans(fontSize: 10.5, color: _C.label)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Bouton nouveau produit ────────────────────────────────────────────────
  Widget _buildNewProductButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text('Nouveau produit',
              style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700)),
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

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(String prenom, String initiales) {
    return Container(
      color: _C.black,
      child: Stack(
        children: [
          Positioned(top: -50, right: -30,
              child: Container(width: 160, height: 160,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _C.green.withOpacity(0.07)))),
          Positioned(bottom: -30, left: -20,
              child: Container(width: 120, height: 120,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _C.green.withOpacity(0.05)))),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _C.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: _C.green.withOpacity(0.3), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: (widget.user?.photoProfil != null && widget.user!.photoProfil!.isNotEmpty)
                              ? Image.network(
                            widget.user!.photoProfil!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              // Si l'image ne charge pas, afficher les initiales
                              return Center(
                                child: Text(
                                  initiales,
                                  style: GoogleFonts.sora(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _C.green,
                                  ),
                                ),
                              );
                            },
                          )
                              : Center(
                            child: Text(
                              initiales,
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _C.green,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$prenom ${widget.user?.nom ?? ''}',
                                style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: _C.white, letterSpacing: -0.4)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.email_outlined, size: 12, color: _C.green.withOpacity(0.7)),
                              const SizedBox(width: 4),
                              Text(widget.user?.email ?? 'email@exemple.com',
                                  style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w500,
                                      color: _C.white.withOpacity(0.6), letterSpacing: -0.2)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bannière promo ────────────────────────────────────────────────────────
  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: _C.black, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Positioned(right: -10, top: -20,
              child: Container(width: 90, height: 90,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _C.green.withOpacity(0.12)))),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _C.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text('OFFRE SPÉCIALE', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: _C.green, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 8),
                    RichText(text: TextSpan(children: [
                      TextSpan(text: 'Livraison ',  style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800, color: _C.white)),
                      TextSpan(text: 'offerte\n',   style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800, color: _C.green)),
                      TextSpan(text: 'ce week-end !', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800, color: _C.white)),
                    ])),
                    const SizedBox(height: 4),
                    Text('Sur toutes vos commandes', style: GoogleFonts.dmSans(fontSize: 11, color: _C.label)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(12)),
                child: Text('En profiter', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: _C.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Statistiques ──────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        children: [
          Expanded(child: _buildStatChip(icon: Icons.receipt_long_rounded,   label: 'Commandes', value: _nbCommandes.toString(), color: _C.green)),
          const SizedBox(width: 10),
          Expanded(child: _buildStatChip(icon: Icons.favorite_border_rounded, label: 'Favoris',   value: _nbFavoris.toString(),   color: const Color(0xFFE53935))),
          const SizedBox(width: 10),
          Expanded(child: _buildStatChip(icon: Icons.local_shipping_outlined,  label: 'En transit', value: '—',                   color: _C.amber)),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)),
      child: Column(
        children: [
          Container(width: 34, height: 34,
              decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: color)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: _C.black)),
          Text(label,  style: GoogleFonts.dmSans(fontSize: 10, color: _C.label, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── En-tête section ───────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: _C.black)),
          Text('Voir tout', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: _C.green)),
        ],
      ),
    );
  }

  // ── Liste boutiques dynamique ─────────────────────────────────────────────
  Widget _buildShopList() {
    if (_dataSource == null || _boutiquesLoad) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5)),
      );
    }
    if (_boutiquesError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: _C.orange, size: 40),
            const SizedBox(height: 8),
            Text('Erreur: $_boutiquesError', style: GoogleFonts.dmSans(color: _C.orange), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _fetchBoutiques,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: _C.black, borderRadius: BorderRadius.circular(12)),
                child: Text('Réessayer', style: GoogleFonts.dmSans(color: _C.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }
    if (_boutiques.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text('Aucune boutique disponible', style: GoogleFonts.dmSans(color: _C.label))),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(children: _boutiques.map(_buildShopItem).toList()),
    );
  }

  Widget _buildShopItem(BoutiqueModel boutique) {
    final hasLogo   = boutique.logo != null && boutique.logo!.isNotEmpty;
    final horaires  = boutique.horaires;
    final sousTitre = boutique.localisation.isNotEmpty ? boutique.localisation : boutique.description;

    return GestureDetector(
      onTap: () => _openBoutiqueSheet(boutique),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _C.greenLight,
                borderRadius: BorderRadius.circular(12),
                image: hasLogo
                    ? DecorationImage(image: NetworkImage(boutique.logo!), fit: BoxFit.cover)
                    : null,
              ),
              child: hasLogo ? null : const Icon(Icons.storefront_rounded, color: _C.green, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(boutique.nom,
                      style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _C.black)),
                  Text(sousTitre,
                      style: GoogleFonts.dmSans(fontSize: 11, color: _C.label),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (horaires.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 10, color: _C.green),
                      const SizedBox(width: 3),
                      Text(horaires, style: GoogleFonts.dmSans(fontSize: 10, color: _C.green)),
                    ]),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(10)),
              child: Text(boutique.vendeurNomComplet,
                  style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: _C.sub),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            // ── Icône ouvrir boutique ──────────────────────────────────────
            GestureDetector(
              onTap: () => _openBoutiqueSheet(boutique),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _C.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chevron_right_rounded, color: _C.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grille produits dynamique via Bloc ────────────────────────────────────
  Widget _buildProductGrid() {
    if (_produitBloc == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: BlocBuilder<ProduitBloc, ProduitState>(
        bloc: _produitBloc,
        builder: (context, state) {
          if (state is ProduitLoading) {
            return const Center(child: Padding(padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5)));
          } else if (state is ProduitLoaded) {
            final produits = state.produits;
            if (produits.isEmpty) {
              return Center(child: Padding(padding: const EdgeInsets.all(32),
                  child: Text('Aucun produit disponible', style: GoogleFonts.dmSans(color: _C.label))));
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.80),
              itemCount: produits.length,
              itemBuilder: (_, i) => _buildProductCard(produits[i]),
            );
          } else if (state is ProduitError) {
            return Center(child: Padding(padding: const EdgeInsets.all(32),
                child: Column(children: [
                  const Icon(Icons.error_outline_rounded, color: _C.orange, size: 40),
                  const SizedBox(height: 8),
                  Text('Erreur: ${state.message}', style: GoogleFonts.dmSans(color: _C.orange), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _produitBloc?.add(LoadProduits()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: _C.black, borderRadius: BorderRadius.circular(12)),
                      child: Text('Réessayer', style: GoogleFonts.dmSans(color: _C.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ])));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProductCard(ProduitModel produit) {
    return Container(
      decoration: BoxDecoration(
          color: _C.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                image: produit.image.isNotEmpty
                    ? DecorationImage(image: NetworkImage(produit.image), fit: BoxFit.cover)
                    : null,
              ),
              child: Stack(children: [
                Positioned(top: 8, right: 8,
                    child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                        child: const Icon(Icons.favorite_border_rounded, size: 14, color: _C.label))),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produit.nom, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: _C.black),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(produit.ville, style: GoogleFonts.dmSans(fontSize: 10, color: _C.label)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(text: TextSpan(children: [
                      TextSpan(text: produit.prix, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w800, color: _C.black)),
                      TextSpan(text: ' F',         style: GoogleFonts.dmSans(fontSize: 10, color: _C.label)),
                    ])),
                    Container(width: 28, height: 28,
                        decoration: BoxDecoration(color: _C.black, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.add_rounded, color: _C.white, size: 16)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _getInitiales(User? user) {
    if (user == null) return '?';
    final p = user.prenom?.isNotEmpty == true ? user.prenom![0] : '';
    final n = user.nom?.isNotEmpty    == true ? user.nom![0]    : '';
    return '$p$n'.toUpperCase();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Bottom Sheet — Produits d'une boutique
// ════════════════════════════════════════════════════════════════════════════
class _BoutiqueSheet extends StatefulWidget {
  final BoutiqueModel            boutique;
  final ProduitRemoteDataSource? dataSource;

  const _BoutiqueSheet({required this.boutique, required this.dataSource});

  @override
  State<_BoutiqueSheet> createState() => _BoutiqueSheetState();
}

class _BoutiqueSheetState extends State<_BoutiqueSheet> {
  List<ProduitModel> _produits = [];
  bool               _loading  = true;
  String?            _error;

  @override
  void initState() {
    super.initState();
    _loadProduits();
  }

  Future<void> _loadProduits() async {
    if (widget.dataSource == null) {
      setState(() { _loading = false; _error = 'Source de données indisponible'; });
      return;
    }
    try {
      final list = await widget.dataSource!.getProduitsByBoutique(widget.boutique.id);
      if (mounted) setState(() { _produits = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Appel WhatsApp ─────────────────────────────────────────────
  Future<void> _contactWhatsapp(String produitId) async {
    if (widget.dataSource == null) return;

    try {
      // 1️⃣ Récupère l'URL depuis le backend
      final url = await widget.dataSource!.getWhatsappUrl(produitId);
      logDebug('🔗 URL WhatsApp finale: $url');

      // 2️⃣ Parse l'URL
      final uri = Uri.parse(url);

      // 3️⃣ Vérifie si l'appareil peut ouvrir le lien
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // 4️⃣ Affiche un message si WhatsApp n'est pas installé
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Impossible d\'ouvrir WhatsApp. Veuillez vérifier que l\'application est installée.',
                style: GoogleFonts.dmSans(color: _C.white),
              ),
              backgroundColor: _C.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString()}',
              style: GoogleFonts.dmSans(color: _C.white),
            ),
            backgroundColor: _C.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = widget.boutique.logo != null && widget.boutique.logo!.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Drag handle
            const SizedBox(height: 10),
            Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),

            // ── En-tête boutique
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _C.greenLight, borderRadius: BorderRadius.circular(14),
                      image: hasLogo
                          ? DecorationImage(image: NetworkImage(widget.boutique.logo!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: hasLogo ? null : const Icon(Icons.storefront_rounded, color: _C.green, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.boutique.nom,
                            style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800, color: _C.black)),
                        if (widget.boutique.localisation.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: _C.green),
                            const SizedBox(width: 3),
                            Text(widget.boutique.localisation,
                                style: GoogleFonts.dmSans(fontSize: 11, color: _C.label)),
                          ]),
                        if (widget.boutique.horaires.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: _C.green),
                            const SizedBox(width: 3),
                            Text(widget.boutique.horaires,
                                style: GoogleFonts.dmSans(fontSize: 11, color: _C.green)),
                          ]),
                        const SizedBox(height: 4),
                        if (widget.boutique.vendeurNomComplet.isNotEmpty || widget.boutique.vendeurNumero.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.person_outline, size: 12, color: _C.green),
                            const SizedBox(width: 3),
                            Text('${widget.boutique.vendeurNomComplet} (${widget.boutique.vendeurNumero})',
                                style: GoogleFonts.dmSans(fontSize: 11, color: _C.label)),
                          ]),
                      ],
                    ),
                  ),
                  // Fermer
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.close_rounded, size: 18, color: _C.sub)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Divider(color: _C.border, thickness: 1, height: 1),
            const SizedBox(height: 4),

            // ── Compteur produits
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(children: [
                  Text('${_produits.length} produit${_produits.length > 1 ? 's' : ''}',
                      style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _C.black)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(8)),
                    child: Text('En stock', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: _C.green)),
                  ),
                ]),
              ),

            const SizedBox(height: 12),

            // ── Corps : grille ou états
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5))
                  : _error != null
                  ? _buildError()
                  : _produits.isEmpty
                  ? _buildEmpty()
                  : GridView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12,
                    mainAxisSpacing: 12, childAspectRatio: 0.75),
                itemCount: _produits.length,
                itemBuilder: (_, i) => _buildProductCard(_produits[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, color: _C.orange, size: 40),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(_error!, style: GoogleFonts.dmSans(color: _C.orange), textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () { setState(() { _loading = true; _error = null; }); _loadProduits(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: _C.black, borderRadius: BorderRadius.circular(12)),
            child: Text('Réessayer', style: GoogleFonts.dmSans(color: _C.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.inventory_2_outlined, color: _C.label, size: 48),
        const SizedBox(height: 12),
        Text('Aucun produit dans cette boutique',
            style: GoogleFonts.dmSans(fontSize: 14, color: _C.label)),
      ]),
    );
  }

  // ── Carte produit avec bouton WhatsApp ────────────────────────────────────
  Widget _buildProductCard(ProduitModel produit) {
    return Container(
      decoration: BoxDecoration(
          color: _C.bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                image: produit.image.isNotEmpty
                    ? DecorationImage(image: NetworkImage(produit.image), fit: BoxFit.cover)
                    : null,
              ),
              child: Stack(children: [
                Positioned(top: 8, right: 8,
                    child: Container(width: 28, height: 28,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                        child: const Icon(Icons.favorite_border_rounded, size: 14, color: _C.label))),
              ]),
            ),
          ),
          // Infos + boutons
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produit.nom, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: _C.black),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(produit.ville, style: GoogleFonts.dmSans(fontSize: 10, color: _C.label)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(text: TextSpan(children: [
                      TextSpan(text: produit.prix, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w800, color: _C.black)),
                      TextSpan(text: ' F',         style: GoogleFonts.dmSans(fontSize: 10, color: _C.label)),
                    ])),
                    // ── Bouton WhatsApp ──────────────────────────────────
                    GestureDetector(
                      onTap: () => _contactWhatsapp(produit.id),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _C.whatsapp,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.chat_rounded, color: _C.white, size: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}