import 'package:saambiz/core/widgets/messages.dart';
import 'package:flutter/cupertino.dart';
import 'package:saambiz/core/widgets/onglets_conserves.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../../../../core/widgets/logo_boutique.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:saambiz/features/auth/domain/entities/user.dart';
import '../../bloc/produit_bloc.dart';
import '../../bloc/produit_event.dart';
import '../../../data/datasources/produit_remote_datasource.dart';
import '../../../data/models/produit_model.dart';
import '../../../data/models/boutique_model.dart';
import '../../../../../injection_container.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../vendeur/domain/usecases/get_vendeur_dashboard.dart';
import 'package:saambiz/features/compte/domain/usecases/get_me.dart';
import '../../../../commande/data/datasources/commande_remote_datasource.dart';
import '../../../../commande/data/models/commande_model.dart';
import '../../../../commande/presentation/pages/commande_detail_page.dart'
    show CommandeDetailArgs;
import '../../../../../core/routes/app_router.dart';
import '../../../../commande/presentation/widgets/commande_card.dart'
    show couleurStatutCommande;
import '../../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../abonnes/abonnes_page.dart';
import '../../../../../core/theme/app_color.dart';
import '../../../../../core/utils/texte.dart';
import '../../../../../core/widgets/avatar_utilisateur.dart';
import '../../../../../core/widgets/ui_kit.dart';
import '../../../../vendeur/presentation/pages/produit_form_page.dart';
import 'profil_page.dart';
import 'package:saambiz/features/certification/certification_service.dart';
import '../../../../../core/widgets/page_vendeur.dart';

class _C {
  static const green = Color(0xFF01154B); // navy (héritage de nom)
  static const greenLight = Color(0xFFE8EEF7);
  static const black = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F8);
  static const surface = Color(0xFFF7F9FC);
  static const border = Color(0xFFE8EDF7);
  static const label = Color(0xFF93A1B8);
  static const sub = Color(0xFF5B6C8A);
  static const orange = Color(0xFFFF5722);
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

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, RetourSurOnglet {
  @override
  void surRetourOnglet() {
    _loadStats();
    _fetchBoutiques();
    _loadUtilisateur();
  }

  bool _loading = false;
  int _nbCommandes = 0;
  final int _nbFavoris = 0;

  // Tableau de bord (données réelles via /vendeur/dashboard)
  String _ventes = '0';
  String _visites = '0';
  String _clients = '0';
  int _commandesCount = 0;
  int _notifNonLues = 0; //  notifications non lues (via dashboard)
  List<CommandeModel> _recentOrders = [];
  int _aTraiter = 0; // commandes en attente d'une décision du vendeur

  // Profil relu sur le serveur : à la réouverture de l'application, la session
  // est restaurée sans transmettre d'utilisateur à cette page.
  User? _utilisateur;

  // Le vendeur doit encore faire certifier sa boutique : point rouge sur
  // l'avatar, jusqu'à l'envoi de sa pièce d'identité.
  bool _certificationAFaire = false;

  List<BoutiqueModel> _boutiques = [];
  bool _boutiquesLoad = false;
  String? _boutiquesError;

  // Pas d'animation d'en-tête : celle qui existait pilotait deux
  // `Animation` que plus rien n'écoutait depuis la refonte de l'écran. Le
  // contrôleur était pourtant lancé, et un contrôleur lancé réclame une
  // frame à chaque battement pendant toute sa durée — 800 ms de travail de
  // rendu à chaque ouverture du tableau de bord, pour rien à l'écran.

  late AnimationController _contentCtrl;
  late Animation<double> _contentFade;

  ProduitRemoteDataSource? _dataSource;
  ProduitBloc? _produitBloc;

  @override
  void initState() {
    super.initState();
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _contentCtrl.forward();
    });
    _utilisateur = widget.user;
    _loadStats();
    _loadUtilisateur();
    _loadCertification();
    _initBloc();
  }

  /// Silencieux en cas d'échec : sans réponse, pas de point rouge.
  Future<void> _loadCertification() async {
    try {
      final s = await CertificationService(sl<Dio>()).statut();
      if (mounted) setState(() => _certificationAFaire = s.actionRequise);
    } catch (_) {}
  }

  /// En cas d'échec, l'en-tête garde simplement ce qu'il connaît déjà.
  Future<void> _loadUtilisateur() async {
    final resultat = await sl<GetMe>()();
    if (!mounted) return;
    resultat.fold(
      (echec) => logDebug('Profil non chargé : ${echec.errorMessage}'),
      (user) => setState(() => _utilisateur = user),
    );
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
      // Surtout pas la liste publique : elle contient les boutiques de tous les
      // vendeurs, la plus récente en premier.
      final maBoutique = await _dataSource!.getMaBoutique();
      if (mounted) {
        setState(() {
          _boutiques = maBoutique == null ? [] : [maBoutique];
          _boutiquesLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _boutiquesError = e.toString();
          _boutiquesLoad = false;
        });
      }
    }
  }

  @override
  void dispose() {
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
      if (mounted) {
        setState(() {
          _recentOrders = orders.take(3).toList();
          _aTraiter = orders.where((o) => o.statut == 'en_attente').length;
        });
      }
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

  /// Mêmes libellés et couleurs que la liste des commandes : une table à part
  /// ici affichait « En attente » pour tout statut qu'elle ne connaissait pas.
  ({String label, Color color}) _statutInfo(String statut) => (
    label: kStatutCommandeLabels[statut] ?? statut,
    color: couleurStatutCommande(statut),
  );

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
            _buildBarreHaut(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _produitBloc?.add(LoadProduits());
                  await Future.wait([
                    _loadStats(),
                    _fetchBoutiques(),
                    _loadUtilisateur(),
                  ]);
                },
                color: AppColor.kPrimary,
                child: FadeTransition(
                  opacity: _contentFade,
                  // Sans rebond : il ferait apparaître un trou clair entre la
                  // barre du haut et le bloc bleu.
                  child: ListView(
                    physics: const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.only(bottom: espaceBasVendeur(context)),
                    children: [
                      _buildBlocChiffres(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_aTraiter > 0) ...[
                              _buildATraiter(),
                              const SizedBox(height: 16),
                            ],
                            _buildActions(),
                            const SizedBox(height: 24),
                            _buildRecentOrders(),
                          ],
                        ),
                      ),
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

  /// Barre du haut, toujours visible : boutique, salutation, cloche.
  Widget _buildBarreHaut() {
    final boutique = _boutiques.isNotEmpty ? _boutiques.first : null;

    return ColoredBox(
      color: AppColor.kPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 18, 10),
          child: Row(
            children: [
              _logoBoutique(boutique),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: boutique == null
                      ? null
                      : () => _openBoutiqueSheet(boutique),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (boutique != null)
                        Text(
                          'Ma boutique',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kPolice,
                            fontSize: 12.5,
                            color: AppColor.kWhite.withValues(alpha: 0.7),
                          ),
                        ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              boutique?.nom ?? 'Ma boutique',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: kPolice,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColor.kWhite,
                              ),
                            ),
                          ),
                          if (boutique != null)
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColor.kSecondary,
                              size: 20,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.12),
                    child: InkWell(
                      onTap: _openNotifications,
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        child: Badge(
                          isLabelVisible: _notifNonLues > 0,
                          backgroundColor: AppColor.kSecondary,
                          textColor: AppColor.kPrimary,
                          label: Text(
                            _notifNonLues > 99 ? '99+' : '$_notifNonLues',
                            style: const TextStyle(
                              fontFamily: kPolice,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: AppColor.kWhite,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AvatarUtilisateur(
                utilisateur: _utilisateur,
                pastille: _certificationAFaire,
                // Le compte n'est plus un onglet : il s'ouvre ici, en haut,
                // et se referme sur l'écran d'où il a été appelé.
                onTap: () async {
                  await Navigator.of(context).push(
                    // Route iOS : le compte se ferme aussi d'un glissé
                    // du bord gauche vers la droite.
                    CupertinoPageRoute(
                      builder: (_) => ProfilPage(user: _utilisateur),
                    ),
                  );
                  // Au retour, la demande a peut-être été envoyée.
                  _loadCertification();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Le logo de la boutique, ou ses initiales tant qu'elle n'en a pas.
  Widget _logoBoutique(BoutiqueModel? boutique) {
    final logo = boutique?.logo;
    final Widget initiales = boutique == null
        ? const LogoBoutiqueParDefaut()
        : Center(
            child: Text(
              initialesDe(boutique.nom),
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColor.kPrimary,
              ),
            ),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        color: AppColor.kWhite,
        child: logo != null && logo.isNotEmpty
            ? ImageReseau(logo, fit: BoxFit.cover, repli: initiales)
            : initiales,
      ),
    );
  }

  /// Le chiffre d'affaires sur le bleu, et la carte des chiffres clés posée à
  /// cheval sur le bas du bloc.
  Widget _buildBlocChiffres() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 44,
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.kPrimary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColor.kPrimary.withValues(alpha: 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chiffre d’affaires',
                      style: TextStyle(
                        fontFamily: kPolice,
                        fontSize: 13,
                        color: AppColor.kWhite.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          text: _ventes,
                          children: const [
                            TextSpan(
                              text: ' FCFA',
                              style: TextStyle(
                                fontFamily: kPolice,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColor.kSecondary,
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColor.kWhite,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildCarteChiffres(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarteChiffres() {
    Widget chiffre(
      IconData icone,
      String label,
      String valeur, {
      VoidCallback? onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icone, size: 20, color: AppColor.kPrimaryMedium),
                const SizedBox(height: 6),
                Text(
                  valeur,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kGrayscaleDark100,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 1),
                Text(label, style: texteDiscret(12)),
              ],
            ),
          ),
        ),
      );
    }

    Widget separateur() =>
        Container(width: 1, height: 44, color: AppColor.kLine);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            chiffre(
              Icons.receipt_long_outlined,
              'Commandes',
              '$_commandesCount',
              onTap: () => widget.ouvrirOnglet?.call(1),
            ),
            separateur(),
            chiffre(Icons.visibility_outlined, 'Visites', _visites),
            separateur(),
            // Le nombre d'abonnés ouvre la liste des clients abonnés.
            chiffre(
              Icons.people_outline_rounded,
              'Abonnés',
              _clients,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AbonnesPage())),
            ),
          ],
        ),
      ),
    );
  }

  /// Ce qui attend une décision passe avant le reste de la page.
  Widget _buildATraiter() {
    final pluriel = _aTraiter > 1;
    return Material(
      color: AppColor.kSecondaryLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => widget.ouvrirOnglet?.call(1),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: AppColor.kSecondaryDark,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_aTraiter commande${pluriel ? 's' : ''} à traiter',
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    Text(
                      pluriel
                          ? 'Acceptez-les ou rejetez-les'
                          : 'Acceptez-la ou rejetez-la',
                      style: texteDiscret(12.5),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColor.kSecondaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Actions rapides : une action principale, deux raccourcis plus discrets.
  Widget _buildActions() {
    void ouvrir(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    Widget raccourci(IconData icone, String libelle, VoidCallback onTap) {
      return Expanded(
        child: Material(
          color: AppColor.kWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColor.kLine),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icone, color: AppColor.kPrimary, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      libelle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => ouvrir(const ProduitFormPage()),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text('Ajouter un produit'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColor.kSecondary,
            foregroundColor: AppColor.kPrimary,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(
              fontFamily: kPolice,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            raccourci(
              Icons.local_offer_outlined,
              'Promotions',
              () => widget.ouvrirOnglet?.call(4),
            ),
            const SizedBox(width: 10),
            raccourci(
              Icons.storefront_outlined,
              'Ma boutique',
              () => widget.ouvrirOnglet?.call(2),
            ),
          ],
        ),
      ],
    );
  }

  /// Dernières commandes ; une ligne ouvre la commande, « Voir tout » l'onglet.
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
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: decorationCarte(),
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 32,
                  color: AppColor.kGrayscale30,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucune commande pour le moment.',
                  textAlign: TextAlign.center,
                  style: texteDiscret(14),
                ),
              ],
            ),
          )
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: decorationCarte(),
            child: Column(
              children: [
                for (var i = 0; i < _recentOrders.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 68),
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
    final nom = (o.acheteurNom ?? '').trim();
    final initiales = initialesDe(nom);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          AppRouter.commandeDetailRoute,
          arguments: CommandeDetailArgs(o, isVendeur: true),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColor.kPrimaryLight,
                child: Text(
                  initiales.isEmpty ? '?' : initiales,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom.isEmpty ? 'Client' : nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(o.createdAt),
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
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColor.kGrayscaleDark100,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: st.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      st.label,
                      style: TextStyle(
                        fontFamily: kPolice,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: st.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      if (mounted) {
        setState(() {
          _produits = list;
          _loading = false;
        });
      }
    } on DioException catch (e) {
      // 404 = boutique sans produit : on affiche la boutique avec une liste vide.
      if (e.response?.statusCode == 404) {
        if (mounted) {
          setState(() {
            _produits = [];
            _loading = false;
          });
        }
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
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les produits de la boutique.';
          _loading = false;
        });
      }
    }
  }

  // Appel WhatsApp
  Future<void> _contactWhatsapp(String produitId) async {
    if (widget.dataSource == null) return;

    try {
      // 1. Récupère l'URL depuis le backend
      final url = await widget.dataSource!.getWhatsappUrl(produitId);
      logDebug('URL WhatsApp finale: $url');

      // 2. Parse l'URL
      final uri = Uri.parse(url);

      // 3. Vérifie si l'appareil peut ouvrir le lien
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // 4. Affiche un message si WhatsApp n'est pas installé
        if (mounted) {
          afficherErreur(
            context,
            'Impossible d\'ouvrir WhatsApp. Veuillez vérifier que l\'application est installée.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        afficherErreur(
          context,
          'WhatsApp n\'a pas pu s\'ouvrir. Réessayez.',
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
      builder: (_, controller) => DecoratedBox(
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
                              image: fournisseurImageReseau(
                                widget.boutique.logo!,
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
                          style: const TextStyle(
                            fontFamily: kPolice,
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
                                style: const TextStyle(
                                  fontFamily: kPolice,
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
                                style: const TextStyle(
                                  fontFamily: kPolice,
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
                                style: const TextStyle(
                                  fontFamily: kPolice,
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
            const Divider(color: _C.border, thickness: 1, height: 1),
            const SizedBox(height: 4),

            // Compteur produits
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Text(
                      '${_produits.length} produit${_produits.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontFamily: kPolice,
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
                                style: const TextStyle(
                                  fontFamily: kPolice,
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
                      child: const Text(
                        'En stock',
                        style: TextStyle(
                          fontFamily: kPolice,
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
              style: const TextStyle(fontFamily: kPolice, color: _C.orange),
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
              child: const Text(
                'Réessayer',
                style: TextStyle(
                  fontFamily: kPolice,
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, color: _C.label, size: 48),
          SizedBox(height: 12),
          Text(
            'Aucun produit dans cette boutique',
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 14,
              color: _C.label,
            ),
          ),
        ],
      ),
    );
  }

  // Carte produit avec bouton WhatsApp
  Widget _buildProductCard(ProduitModel produit) {
    return DecoratedBox(
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(17),
                ),
                image: produit.image.isNotEmpty
                    ? DecorationImage(
                        image: fournisseurImageReseau(produit.image),
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
                        color: Colors.white.withValues(alpha: 0.9),
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
                  style: const TextStyle(
                    fontFamily: kPolice,
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
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 10,
                    color: _C.label,
                  ),
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
                            style: const TextStyle(
                              fontFamily: kPolice,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _C.black,
                            ),
                          ),
                          const TextSpan(
                            text: ' F',
                            style: TextStyle(
                              fontFamily: kPolice,
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
