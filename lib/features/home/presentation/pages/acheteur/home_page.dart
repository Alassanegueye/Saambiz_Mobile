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
import '../../../../promotions/presentation/bloc/promotions_bloc.dart';
import '../../../../promotions/presentation/bloc/promotions_event.dart';
import '../../../../promotions/presentation/bloc/promotions_state.dart';
import '../../../../promotions/presentation/pages/promotions_actives_page.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../../core/routes/app_router.dart';
import 'profil_page.dart';
import 'guest_profil_page.dart';
import '../../../../catalogue/data/produit_catalogue.dart' show BoutiqueResume;
import '../../../../catalogue/presentation/pages/boutique_publique_page.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:saambiz/core/utils/image_url.dart';


class _C {
  static const green       = Color(0xFF0D1B3D); // navy (héritage de nom)
  static const navyDk      = Color(0xFF060F26);
  static const gold        = Color(0xFFF2B705);
  static const greenLight  = Color(0xFFE8EEF7);
  static const black       = Color(0xFF0D1B3D);
  static const white       = Color(0xFFFFFFFF);
  static const bg          = Color(0xFFF7F8FA);
  static const surface     = Color(0xFFF7F9FC);
  static const border      = Color(0xFFE8EDF7);
  static const label       = Color(0xFF93A1B8);
  static const sub         = Color(0xFF5B6C8A);
  static const orange      = Color(0xFFFF5722);
  static const amber       = Color(0xFFFF9800);
  static const whatsapp    = Color(0xFF25D366);
}

class HomePage extends StatefulWidget {
  final User? user;
  final bool isGuest;
  const HomePage({super.key, this.user, this.isGuest = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _loading     = false;
  int  _nbCommandes = 0;
  int  _nbFavoris   = 0;
  int  _nonLues     = 0; // 🔔 notifications non lues

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
  late final PromotionsBloc _promotionsBloc;

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
    _promotionsBloc = sl<PromotionsBloc>()..add(LoadPromotionsActives());
    _loadNonLues();
  }

  // 🔔 Nombre de notifications non lues (ignoré si non connecté)
  Future<void> _loadNonLues() async {
    if (widget.isGuest) return;
    try {
      final n = await sl<NotificationsRemoteDataSource>().nombreNonLues();
      if (mounted) setState(() => _nonLues = n);
    } catch (_) {/* non connecté / erreur : badge masqué */}
  }

  void _openNotifications() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const NotificationsPage(),
    ));
    _loadNonLues(); // rafraîchir le badge au retour
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
    _promotionsBloc.close();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() { _nbCommandes = 4; _nbFavoris = 7; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ── Ouvrir la bottom sheet d'une boutique ─────────────────────────────────
  void _openBoutiqueSheet(BoutiqueModel boutique) {
    Navigator.of(context).push(MaterialPageRoute(
      // La même page que le site de la boutique.
      builder: (_) => BoutiquePubliquePage(
        boutiqueId: boutique.id,
        apercu: BoutiqueResume(
          id: boutique.id,
          nom: boutique.nom,
          logo: boutique.logo,
          localisation: boutique.localisation,
          telephone: boutique.telephone ?? '',
        ),
      ),
    ));
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
                child: SlideTransition(position: _headerSlide, child: _buildGreetingHeader()),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _contentFade,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPromoBanner(),
                    _buildSectionHeader('Boutiques populaires'),
                    _buildBoutiquesPopulaires(),
                    _buildSectionHeader('Catégories'),
                    _buildCategories(),
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
                                  style: GoogleFonts.plusJakartaSans(
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
                              style: GoogleFonts.plusJakartaSans(
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
                            Text(
                                widget.isGuest ? 'Bienvenue 👋' : '$prenom ${widget.user?.nom ?? ''}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: _C.white, letterSpacing: -0.4)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(widget.isGuest ? Icons.storefront_outlined : Icons.email_outlined,
                                  size: 12, color: _C.green.withOpacity(0.7)),
                              const SizedBox(width: 4),
                              Text(
                                  widget.isGuest ? 'Explorez la boutique' : (widget.user?.email ?? 'email@exemple.com'),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500,
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

  // ── En-tête : salutation + cloche ─────────────────────────────────────────
  Widget _buildGreetingHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 8),
        child: Row(
          children: [
            // Logo à gauche
            Image.asset('assets/images/picto_navy.png', height: 36), // Pictogramme SaamBiz — fond clair
            const Spacer(),
            // À droite : bouton « Se connecter » (invité) ou cloche (connecté)
            if (widget.isGuest) ...[
              _buildSeConnecter(),
              const SizedBox(width: 10),
            ] else ...[
              _buildBell(),
              const SizedBox(width: 10),
            ],
            // Icône profil (toujours)
            _buildProfileIcon(),
          ],
        ),
      ),
    );
  }

  // Bouton « Se connecter » (mode invité)
  Widget _buildSeConnecter() {
    return GestureDetector(
      onTap: _openLogin,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(color: _C.gold, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.login_rounded, size: 15, color: _C.black),
          const SizedBox(width: 5),
          Text('Se connecter',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.black)),
        ]),
      ),
    );
  }

  // Icône profil → page profil (invité ou connecté)
  Widget _buildProfileIcon() {
    return GestureDetector(
      onTap: _openProfile,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: const Icon(Icons.person_outline_rounded, color: _C.green, size: 24),
      ),
    );
  }

  // Cloche notifications (utilisateur connecté)
  Widget _buildBell() {
    return GestureDetector(
      onTap: _openNotifications,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.border),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: _C.green, size: 22),
          ),
          if (_nonLues > 0)
            Positioned(
              top: -4, right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD64533),
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.bg, width: 2),
                ),
                child: Text(
                  _nonLues > 99 ? '99+' : '$_nonLues',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openLogin() => Navigator.of(context).pushNamed(AppRouter.loginRoute);

  void _openProfile() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => widget.isGuest ? const GuestProfilPage() : ProfilPage(user: widget.user),
    ));
  }

  // ── Barre de recherche + filtre ───────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: _C.label, size: 21),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Rechercher une boutique, un produit...',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: _C.label)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _C.green,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.tune_rounded, color: _C.white, size: 21),
          ),
        ],
      ),
    );
  }

  // ── Boutiques populaires (défilement horizontal) ──────────────────────────
  Widget _buildBoutiquesPopulaires() {
    if (_dataSource == null || _boutiquesLoad) {
      return const SizedBox(
        height: 176,
        child: Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5)),
      );
    }
    if (_boutiques.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('Aucune boutique disponible',
            style: GoogleFonts.plusJakartaSans(color: _C.label)),
      );
    }
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _boutiques.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _buildBoutiquePopCard(_boutiques[i]),
      ),
    );
  }

  Widget _buildBoutiquePopCard(BoutiqueModel b) {
    return GestureDetector(
      onTap: () => _openBoutiqueSheet(b),
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: _C.greenLight,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: (b.logo != null && b.logo!.isNotEmpty)
                  ? CachedNetworkImage(imageUrl: imageOptimisee(b.logo!), fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.storefront_rounded, color: _C.green, size: 26))
                  : const Icon(Icons.storefront_rounded, color: _C.green, size: 26),
            ),
            const SizedBox(height: 10),
            Text(b.nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.black)),
            const SizedBox(height: 2),
            Text(b.localisation.isNotEmpty ? b.localisation : 'Boutique',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: _C.sub)),
            const SizedBox(height: 6),
            Row(children: [
              Icon(b.nombreAvis > 0 ? Icons.star_rounded : Icons.star_border_rounded,
                  color: b.nombreAvis > 0 ? _C.gold : _C.label, size: 15),
              const SizedBox(width: 3),
              Text(b.nombreAvis > 0 ? b.note.toStringAsFixed(1) : 'Nouveau',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _C.black)),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Catégories (cercles) ──────────────────────────────────────────────────
  Widget _buildCategories() {
    const cats = <List<Object>>[
      [Icons.checkroom_rounded, 'Mode'],
      [Icons.spa_rounded, 'Beauté'],
      [Icons.chair_rounded, 'Maison'],
      [Icons.devices_rounded, 'Électronique'],
      [Icons.restaurant_rounded, 'Alimentaire'],
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (_, i) {
          final c = cats[i];
          return Column(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: _C.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.border),
                ),
                child: Icon(c[0] as IconData, color: _C.green, size: 26),
              ),
              const SizedBox(height: 8),
              Text(c[1] as String,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: _C.black)),
            ],
          );
        },
      ),
    );
  }

  // ── Bandeau "Promotions actives" (réel, via PromotionsBloc) ────────────────
  Widget _buildActivePromotionsBanner() {
    return BlocProvider<PromotionsBloc>.value(
      value: _promotionsBloc,
      child: BlocBuilder<PromotionsBloc, PromotionsState>(
        builder: (context, state) {
          if (state is! PromotionsLoaded || state.promotions.isEmpty) {
            // Masqué tant qu'il n'y a pas de promotion active (ou en cas
            // de chargement/erreur) : bandeau additif, non bloquant.
            return const SizedBox.shrink();
          }
          final promotions = state.promotions;
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Promotions actives',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w700, color: _C.black)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const PromotionsActivesPage(),
                      )),
                      child: Text('Tout voir',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, fontWeight: FontWeight.w600, color: _C.green)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: promotions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final promo = promotions[i];
                      return Container(
                        width: 220,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _C.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(promo.titre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: _C.white)),
                            if ((promo.produitNom ?? '').isNotEmpty)
                              Text(promo.produitNom!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _C.label)),
                            Text('${promo.prixPromo.toStringAsFixed(0)} FCFA',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14, fontWeight: FontWeight.w800, color: _C.green)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Bannière promo ────────────────────────────────────────────────────────
  Widget _buildPromoBanner() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const PromotionsActivesPage(),
      )),
      child: Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.green, _C.navyDk],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -25,
            child: Container(width: 110, height: 110,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _C.gold.withOpacity(0.15))),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(text: TextSpan(children: [
                      const TextSpan(text: 'Jusqu’à\n', style: TextStyle()),
                      TextSpan(text: '-30%',
                          style: GoogleFonts.plusJakartaSans(fontSize: 30, fontWeight: FontWeight.w800, color: _C.gold, height: 1.1)),
                    ], style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: _C.white, height: 1.3))),
                    const SizedBox(height: 4),
                    Text('sur une sélection\nde produits',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _C.white.withOpacity(0.85), height: 1.35)),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(color: _C.gold, borderRadius: BorderRadius.circular(12)),
                      child: Text('Voir les promos',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _C.navyDk)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.local_offer_rounded, color: Colors.white24, size: 72),
            ],
          ),
        ],
      ),
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
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: _C.black)),
          Text(label,  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _C.label, fontWeight: FontWeight.w500)),
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
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: _C.black)),
          Text('Voir tout', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: _C.green)),
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
            Text('Erreur: $_boutiquesError', style: GoogleFonts.plusJakartaSans(color: _C.orange), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _fetchBoutiques,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: _C.black, borderRadius: BorderRadius.circular(12)),
                child: Text('Réessayer', style: GoogleFonts.plusJakartaSans(color: _C.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }
    if (_boutiques.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text('Aucune boutique disponible', style: GoogleFonts.plusJakartaSans(color: _C.label))),
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
                    ? DecorationImage(image: CachedNetworkImageProvider(imageOptimisee(boutique.logo!)), fit: BoxFit.cover)
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _C.black)),
                  Text(sousTitre,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _C.label),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (horaires.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 10, color: _C.green),
                      const SizedBox(width: 3),
                      Text(horaires, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _C.green)),
                    ]),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(10)),
              child: Text(boutique.vendeurNomComplet,
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: _C.sub),
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
                  child: Text('Aucun produit disponible', style: GoogleFonts.plusJakartaSans(color: _C.label))));
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
                  Text('Erreur: ${state.message}', style: GoogleFonts.plusJakartaSans(color: _C.orange), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _produitBloc?.add(LoadProduits()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: _C.black, borderRadius: BorderRadius.circular(12)),
                      child: Text('Réessayer', style: GoogleFonts.plusJakartaSans(color: _C.white, fontWeight: FontWeight.w600)),
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
                    ? DecorationImage(image: CachedNetworkImageProvider(imageOptimisee(produit.image)), fit: BoxFit.cover)
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
                Text(produit.nom, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _C.black),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(produit.ville, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _C.label)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(text: TextSpan(children: [
                      TextSpan(text: produit.prix, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: _C.black)),
                      TextSpan(text: ' F',         style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _C.label)),
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
                style: GoogleFonts.plusJakartaSans(color: _C.white),
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
              style: GoogleFonts.plusJakartaSans(color: _C.white),
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
                          ? DecorationImage(image: CachedNetworkImageProvider(imageOptimisee(widget.boutique.logo!)), fit: BoxFit.cover)
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
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: _C.black)),
                        if (widget.boutique.localisation.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: _C.green),
                            const SizedBox(width: 3),
                            Text(widget.boutique.localisation,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _C.label)),
                          ]),
                        if (widget.boutique.horaires.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: _C.green),
                            const SizedBox(width: 3),
                            Text(widget.boutique.horaires,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _C.green)),
                          ]),
                        const SizedBox(height: 4),
                        if (widget.boutique.vendeurNomComplet.isNotEmpty || widget.boutique.vendeurNumero.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.person_outline, size: 12, color: _C.green),
                            const SizedBox(width: 3),
                            Text('${widget.boutique.vendeurNomComplet} (${widget.boutique.vendeurNumero})',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _C.label)),
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _C.black)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(8)),
                    child: Text('En stock', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: _C.green)),
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
            child: Text(_error!, style: GoogleFonts.plusJakartaSans(color: _C.orange), textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () { setState(() { _loading = true; _error = null; }); _loadProduits(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: _C.black, borderRadius: BorderRadius.circular(12)),
            child: Text('Réessayer', style: GoogleFonts.plusJakartaSans(color: _C.white, fontWeight: FontWeight.w600)),
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
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _C.label)),
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
                    ? DecorationImage(image: CachedNetworkImageProvider(imageOptimisee(produit.image)), fit: BoxFit.cover)
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
                Text(produit.nom, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _C.black),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(produit.ville, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _C.label)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(text: TextSpan(children: [
                      TextSpan(text: produit.prix, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: _C.black)),
                      TextSpan(text: ' F',         style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _C.label)),
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