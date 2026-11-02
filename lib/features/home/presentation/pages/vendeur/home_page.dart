import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../../../../core/widgets/logo_boutique.dart';
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
import '../../../../abonnes/abonnes_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:saambiz/core/utils/image_url.dart';
import '../../../../../core/theme/app_color.dart';
import '../../../../../core/widgets/ui_kit.dart';
import '../../../../vendeur/presentation/pages/produit_form_page.dart';
import '../../../../vitrine/presentation/pages/ma_vitrine_page.dart';

class _C {
  static const green = Color(0xFF01154B); // navy (héritage de nom)
  static const navyDk = Color(0xFF060F26);
  static const gold = Color(0xFFFBB900);
  static const greenLight = Color(0xFFE8EEF7);
  static const black = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const success = Color(0xFF1E9E62);
  static const bg = Color(0xFFF4F5F8);
  static const surface = Color(0xFFF7F9FC);
  static const border = Color(0xFFE8EDF7);
  static const label = Color(0xFF93A1B8);
  static const sub = Color(0xFF5B6C8A);
  static const orange = Color(0xFFFF5722);
  static const amber = Color(0xFFFF9800);
  static const whatsapp = Color(0xFF25D366);
}

class HomePage extends StatefulWidget {
  final User? user;

  /// Bascule vers un autre onglet de l'espace vendeur (1 commandes,
  /// 3 promotions).
  final ValueChanged<int>? ouvrirOnglet;
  const HomePage({super.key, this.user, this.ouvrirOnglet});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _loading = false;
  int _nbCommandes = 0;
  int _nbFavoris = 0;

  // Tableau de bord (données réelles via /vendeur/dashboard)
  String _ventes = '0';
  String _visites = '0';
  String _clients = '0';
  int _commandesCount = 0;
  int _notifNonLues = 0; // 🔔 notifications non lues (via dashboard)
  List<CommandeModel> _recentOrders = [];

  List<BoutiqueModel> _boutiques = [];
  bool _boutiquesLoad = false;
  String? _boutiquesError;

  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  late AnimationController _contentCtrl;
  late Animation<double> _contentFade;

  ProduitRemoteDataSource? _dataSource;
  ProduitBloc? _produitBloc;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _contentCtrl.forward();
    });
    _loadStats();
    _initBloc();
  }

  Future<void> _initBloc() async {
    try {
      // Récupérés via l'injection de dépendances (Dio partagé + API_BASE_URL du .env)
      final dataSource = sl<ProduitRemoteDataSource>();
      final bloc = sl<ProduitBloc>();
      bloc.add(LoadProduits());
      if (mounted) {
        setState(() {
          _dataSource = dataSource;
          _produitBloc = bloc;
        });
        _fetchBoutiques();
      }
    } catch (e) {
      debugPrint('Erreur init bloc: $e');
    }
  }

  Future<void> _fetchBoutiques() async {
    if (_dataSource == null) return;
    setState(() {
      _boutiquesLoad = true;
      _boutiquesError = null;
    });
    try {
      final list = await _dataSource!.getBoutiques();
      if (mounted)
        setState(() {
          _boutiques = list;
          _boutiquesLoad = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _boutiquesError = e.toString();
          _boutiquesLoad = false;
        });
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
          _ventes = _fmtNombre(stats['chiffreAffaires']);
          _commandesCount = _toInt(stats['nombreCommandes']);
          _nbCommandes = _commandesCount;
          _visites = _toInt(stats['totalVues']).toString();
          _clients = _toInt(stats['nombreAbonnes']).toString();
          _notifNonLues = _toInt(data['notificationsNonLues']);
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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
    _loadStats(); // rafraîchir le badge (notificationsNonLues) au retour
  }

  // Ouvrir la bottom sheet d'une boutique
  void _openBoutiqueSheet(BoutiqueModel boutique) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _BoutiqueSheet(boutique: boutique, dataSource: _dataSource),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tableau de bord : en-tête marine (boutique et chiffres clés), actions
    // rapides, puis les dernières commandes.
    // En-tête marine : icônes de la barre d'état en blanc.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
        body: Column(
          children: [
            _buildDashHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _produitBloc?.add(LoadProduits());
                  await Future.wait([_loadStats(), _fetchBoutiques()]);
                },
                color: AppColor.kPrimary,
                child: FadeTransition(
                  opacity: _contentFade,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildActions(),
                      const SizedBox(height: 24),
                      _buildRecentOrders(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// En-tête : logo et nom de la boutique, lien vers la boutique, cloche.
  Widget _buildDashHeader() {
    final boutique = _boutiques.isNotEmpty ? _boutiques.first : null;
    final logo = boutique?.logo;
    final hasLogo = logo != null && logo.isNotEmpty;

    return Container(
      color: AppColor.kPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 6, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: AppColor.kWhite,
                      child: hasLogo
                          ? CachedNetworkImage(
                              imageUrl: imageOptimisee(logo),
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  const LogoBoutiqueParDefaut(),
                            )
                          : const LogoBoutiqueParDefaut(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          boutique?.nom ?? 'Ma boutique',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColor.kWhite,
                          ),
                        ),
                        if (boutique != null)
                          GestureDetector(
                            onTap: () => _openBoutiqueSheet(boutique),
                            child: Text(
                              'Voir ma boutique',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColor.kSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: _openNotifications,
                    icon: Badge(
                      isLabelVisible: _notifNonLues > 0,
                      backgroundColor: AppColor.kSecondary,
                      textColor: AppColor.kPrimary,
                      label: Text(
                        _notifNonLues > 99 ? '99+' : '$_notifNonLues',
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColor.kWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildStatCards(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chiffres clés sur l'en-tête marine : le chiffre d'affaires en grand,
  /// puis commandes, visites et abonnés sur une ligne.
  Widget _buildStatCards() {
    final etiquette = GoogleFonts.inter(
      fontSize: 12.5,
      color: AppColor.kWhite.withValues(alpha: 0.7),
    );
    Widget petit(String label, String valeur, {VoidCallback? onTap}) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valeur,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kWhite,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(label, style: etiquette),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chiffre d’affaires', style: etiquette),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            text: _ventes,
            children: [
              TextSpan(
                text: ' FCFA',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kSecondary,
                ),
              ),
            ],
          ),
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColor.kWhite,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 14),
        Container(height: 1, color: AppColor.kWhite.withValues(alpha: 0.12)),
        const SizedBox(height: 12),
        Row(
          children: [
            petit(
              'Commandes',
              '$_commandesCount',
              onTap: () => widget.ouvrirOnglet?.call(1),
            ),
            petit('Visites', _visites),
            // Le nombre d'abonnés ouvre la liste des clients abonnés.
            petit(
              'Abonnés',
              _clients,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AbonnesPage())),
            ),
          ],
        ),
      ],
    );
  }

  /// Actions rapides : ce qu'un vendeur fait le plus souvent.
  Widget _buildActions() {
    Widget action(
      IconData icone,
      String libelle,
      VoidCallback onTap, {
      bool principale = false,
    }) {
      return Expanded(
        child: Material(
          color: principale ? AppColor.kSecondary : AppColor.kWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: principale ? AppColor.kSecondary : AppColor.kLine,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icone, color: AppColor.kPrimary, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    libelle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColor.kGrayscaleDark100,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    void ouvrir(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          action(
            Icons.add_box_outlined,
            'Ajouter un produit',
            () => ouvrir(const ProduitFormPage()),
            principale: true,
          ),
          const SizedBox(width: 10),
          action(
            Icons.local_offer_outlined,
            'Promotions',
            () => widget.ouvrirOnglet?.call(3),
          ),
          const SizedBox(width: 10),
          action(
            Icons.language_rounded,
            'Mon site web',
            () => ouvrir(const MaVitrinePage()),
          ),
        ],
      ),
    );
  }

  /// Dernières commandes, en liste ; « Voir tout » ouvre l'onglet Commandes.
  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EnteteSection(
          'Dernières commandes',
          action: 'Voir tout',
          onAction: () => widget.ouvrirOnglet?.call(1),
        ),
        const SizedBox(height: 8),
        if (_recentOrders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: decorationCarte(),
            child: Text(
              'Aucune commande pour le moment.',
              textAlign: TextAlign.center,
              style: texteDiscret(14),
            ),
          )
        else
          Container(
            decoration: decorationCarte(),
            child: Column(
              children: [
                for (var i = 0; i < _recentOrders.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 16),
                  _ligneCommande(_recentOrders[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _ligneCommande(CommandeModel o) {
    final st = _statutInfo(o.statut);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.acheteurNom ?? 'Client',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'N° ${o.referenceCommande}, ${_timeAgo(o.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: texteDiscret(12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmtNombre(o.montantTotal)} FCFA',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kGrayscaleDark100,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                st.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: st.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Header
  Widget _buildHeader(String prenom, String initiales) {
    return Container(
      color: _C.black,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.green.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.green.withOpacity(0.05),
              ),
            ),
          ),
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _C.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: _C.green.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child:
                              (widget.user?.photoProfil != null &&
                                  widget.user!.photoProfil!.isNotEmpty)
                              ? Image.network(
                                  widget.user!.photoProfil!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  (loadingProgress
                                                          .expectedTotalBytes ??
                                                      1)
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    // Si l'image ne charge pas, afficher les initiales
                                    return Center(
                                      child: Text(
                                        initiales,
                                        style: GoogleFonts.inter(
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
                                    style: GoogleFonts.inter(
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
                              '$prenom ${widget.user?.nom ?? ''}',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _C.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 12,
                                  color: _C.green.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.user?.email ?? 'email@exemple.com',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _C.white.withOpacity(0.6),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
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

  // Bannière promo
  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _C.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.green.withOpacity(0.12),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _C.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'OFFRE SPÉCIALE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _C.green,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Livraison ',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _C.white,
                            ),
                          ),
                          TextSpan(
                            text: 'offerte\n',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _C.green,
                            ),
                          ),
                          TextSpan(
                            text: 'ce week-end !',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _C.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sur toutes vos commandes',
                      style: GoogleFonts.inter(fontSize: 11, color: _C.label),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _C.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'En profiter',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _C.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Statistiques
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatChip(
              icon: Icons.receipt_long_rounded,
              label: 'Commandes',
              value: _nbCommandes.toString(),
              color: _C.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatChip(
              icon: Icons.favorite_border_rounded,
              label: 'Favoris',
              value: _nbFavoris.toString(),
              color: const Color(0xFFE53935),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatChip(
              icon: Icons.local_shipping_outlined,
              label: 'En transit',
              value: '0',
              color: _C.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _C.black,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: _C.label,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // En-tête section
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _C.black,
            ),
          ),
          Text(
            'Voir tout',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _C.green,
            ),
          ),
        ],
      ),
    );
  }

  // Liste boutiques dynamique
  Widget _buildShopList() {
    if (_dataSource == null || _boutiquesLoad) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5),
        ),
      );
    }
    if (_boutiquesError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: _C.orange, size: 40),
            const SizedBox(height: 8),
            Text(
              'Erreur: $_boutiquesError',
              style: GoogleFonts.inter(color: _C.orange),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _fetchBoutiques,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _C.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Réessayer',
                  style: GoogleFonts.inter(
                    color: _C.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_boutiques.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Aucune boutique disponible',
            style: GoogleFonts.inter(color: _C.label),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(children: _boutiques.map(_buildShopItem).toList()),
    );
  }

  Widget _buildShopItem(BoutiqueModel boutique) {
    final hasLogo = boutique.logo != null && boutique.logo!.isNotEmpty;
    final horaires = boutique.horaires;
    final sousTitre = boutique.localisation.isNotEmpty
        ? boutique.localisation
        : boutique.description;

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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _C.greenLight,
                borderRadius: BorderRadius.circular(12),
                image: hasLogo
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          imageOptimisee(boutique.logo!),
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: hasLogo ? null : const LogoBoutiqueParDefaut(rayon: 12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boutique.nom,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.black,
                    ),
                  ),
                  Text(
                    sousTitre,
                    style: GoogleFonts.inter(fontSize: 11, color: _C.label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (horaires.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 10,
                          color: _C.green,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          horaires,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: _C.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _C.greenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                boutique.vendeurNomComplet,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _C.sub,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Icône ouvrir boutique
            GestureDetector(
              onTap: () => _openBoutiqueSheet(boutique),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _C.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: _C.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Grille produits dynamique via Bloc
  Widget _buildProductGrid() {
    if (_produitBloc == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: BlocBuilder<ProduitBloc, ProduitState>(
        bloc: _produitBloc,
        builder: (context, state) {
          if (state is ProduitLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: _C.green,
                  strokeWidth: 2.5,
                ),
              ),
            );
          } else if (state is ProduitLoaded) {
            final produits = state.produits;
            if (produits.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Aucun produit disponible',
                    style: GoogleFonts.inter(color: _C.label),
                  ),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.80,
              ),
              itemCount: produits.length,
              itemBuilder: (_, i) => _buildProductCard(produits[i]),
            );
          } else if (state is ProduitError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: _C.orange,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erreur: ${state.message}',
                      style: GoogleFonts.inter(color: _C.orange),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _produitBloc?.add(LoadProduits()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _C.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Réessayer',
                          style: GoogleFonts.inter(
                            color: _C.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProductCard(ProduitModel produit) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(17),
                ),
                image: produit.image.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          imageOptimisee(produit.image),
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 14,
                        color: _C.label,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.nom,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _C.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  produit.ville,
                  style: GoogleFonts.inter(fontSize: 10, color: _C.label),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: produit.prix,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _C.black,
                            ),
                          ),
                          TextSpan(
                            text: ' F',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: _C.label,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _C.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: _C.white,
                        size: 16,
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

  // Helpers
  String _getInitiales(User? user) {
    if (user == null) return '?';
    final p = user.prenom?.isNotEmpty == true ? user.prenom![0] : '';
    final n = user.nom?.isNotEmpty == true ? user.nom![0] : '';
    return '$p$n'.toUpperCase();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Bottom Sheet, Produits d'une boutique
// ════════════════════════════════════════════════════════════════════════════
class _BoutiqueSheet extends StatefulWidget {
  final BoutiqueModel boutique;
  final ProduitRemoteDataSource? dataSource;

  const _BoutiqueSheet({required this.boutique, required this.dataSource});

  @override
  State<_BoutiqueSheet> createState() => _BoutiqueSheetState();
}

class _BoutiqueSheetState extends State<_BoutiqueSheet> {
  List<ProduitModel> _produits = [];
  bool _loading = true;
  String? _error;
  int? _nbAbonnes;

  @override
  void initState() {
    super.initState();
    _loadProduits();
    AbonnesService.charger()
        .then((l) {
          if (mounted) setState(() => _nbAbonnes = l.length);
        })
        .catchError((_) {});
  }

  Future<void> _loadProduits() async {
    if (widget.dataSource == null) {
      setState(() {
        _loading = false;
        _error = 'Source de données indisponible';
      });
      return;
    }
    try {
      final list = await widget.dataSource!.getProduitsByBoutique(
        widget.boutique.id,
      );
      if (mounted)
        setState(() {
          _produits = list;
          _loading = false;
        });
    } on DioException catch (e) {
      // 404 = boutique sans produit : on affiche la boutique avec une liste vide.
      if (e.response?.statusCode == 404) {
        if (mounted)
          setState(() {
            _produits = [];
            _loading = false;
          });
        return;
      }
      final pasDeReseau =
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;
      if (mounted) {
        setState(() {
          _error = pasDeReseau
              ? 'Connexion impossible. Vérifiez votre connexion internet.'
              : 'Impossible de charger les produits de la boutique.';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = 'Impossible de charger les produits de la boutique.';
          _loading = false;
        });
    }
  }

  // Appel WhatsApp
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
                style: GoogleFonts.inter(color: _C.white),
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
              style: GoogleFonts.inter(color: _C.white),
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
    final hasLogo =
        widget.boutique.logo != null && widget.boutique.logo!.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // En-tête boutique
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _C.greenLight,
                      borderRadius: BorderRadius.circular(14),
                      image: hasLogo
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                imageOptimisee(widget.boutique.logo!),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasLogo
                        ? null
                        : const LogoBoutiqueParDefaut(rayon: 14),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.boutique.nom,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _C.black,
                          ),
                        ),
                        if (widget.boutique.localisation.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: _C.green,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                widget.boutique.localisation,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: _C.label,
                                ),
                              ),
                            ],
                          ),
                        if (widget.boutique.horaires.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: _C.green,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                widget.boutique.horaires,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: _C.green,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        if (widget.boutique.vendeurNomComplet.isNotEmpty ||
                            widget.boutique.vendeurNumero.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 12,
                                color: _C.green,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${widget.boutique.vendeurNomComplet} (${widget.boutique.vendeurNumero})',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: _C.label,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Fermer
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _C.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: _C.sub,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Divider(color: _C.border, thickness: 1, height: 1),
            const SizedBox(height: 4),

            // Compteur produits
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Text(
                      '${_produits.length} produit${_produits.length > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Nombre d'abonnés : ouvre la liste des clients abonnés.
                    if (_nbAbonnes != null)
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AbonnesPage(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _C.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _C.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.people_alt_outlined,
                                size: 14,
                                color: _C.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_nbAbonnes abonné${_nbAbonnes! > 1 ? 's' : ''}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _C.green,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: _C.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _C.greenLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'En stock',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _C.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Corps : grille ou états
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _C.green,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _error != null
                  ? _buildError()
                  : _produits.isEmpty
                  ? _buildEmpty()
                  : GridView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: _C.orange, size: 40),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              style: GoogleFonts.inter(color: _C.orange),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _loadProduits();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _C.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Réessayer',
                style: GoogleFonts.inter(
                  color: _C.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
          const Icon(Icons.inventory_2_outlined, color: _C.label, size: 48),
          const SizedBox(height: 12),
          Text(
            'Aucun produit dans cette boutique',
            style: GoogleFonts.inter(fontSize: 14, color: _C.label),
          ),
        ],
      ),
    );
  }

  // Carte produit avec bouton WhatsApp
  Widget _buildProductCard(ProduitModel produit) {
    return Container(
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(17),
                ),
                image: produit.image.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          imageOptimisee(produit.image),
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 14,
                        color: _C.label,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Infos + boutons
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.nom,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _C.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  produit.ville,
                  style: GoogleFonts.inter(fontSize: 10, color: _C.label),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: produit.prix,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _C.black,
                            ),
                          ),
                          TextSpan(
                            text: ' F',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: _C.label,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bouton WhatsApp
                    GestureDetector(
                      onTap: () => _contactWhatsapp(produit.id),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _C.whatsapp,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.chat_rounded,
                          color: _C.white,
                          size: 15,
                        ),
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
