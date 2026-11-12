import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/core/widgets/logo_boutique.dart';

import '../../../../../core/routes/observateur_routes.dart';
import '../../../../../core/services/localisation_service.dart';
import '../../../../../core/theme/app_color.dart';
import '../../../../../core/widgets/animations.dart';
import '../../../../../core/widgets/barre_navigation_verre.dart'
    show kEspaceBarreBas;
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/onglets_conserves.dart';
import '../../../../../core/widgets/ui_kit.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/domain/entities/user.dart';
import '../../../../auth/presentation/signup/interets_page.dart';
import '../../../../catalogue/data/produit_catalogue.dart';
import '../../../../catalogue/presentation/pages/boutique_publique_page.dart';
import '../../../../catalogue/presentation/pages/produits_page.dart';
import '../../../../catalogue/presentation/pages/produit_detail_page.dart';
import '../../../../catalogue/presentation/widgets/bouton_panier.dart';
import '../../../../catalogue/presentation/widgets/produit_card.dart';
import '../../../../categories/data/categorie.dart';
import '../../../../categories/presentation/icones_categories.dart';
import '../../../../notifications/data/datasources/notifications_remote_datasource.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';
import '../../../data/datasources/accueil_remote_datasource.dart';
import 'main_client_page.dart' show ongletAcheteurDemande;
import '../../../../../core/widgets/page_vendeur.dart';
import '../../../../../core/widgets/activer_localisation.dart';

/// Accueil du client (connecté ou invité), dans la disposition d'origine :
///
/// - en tête, fixes : le logo, la cloche, le panier, puis la recherche ;
/// - la rangée des catégories (les centres d'intérêt du client d'abord) ;
/// - les promotions, dans un bandeau marine ;
/// - puis les sections dans un ordre fixe, chacune en carrousel avec son
///   « Voir tout » : produits d'abord (nouveautés, pour vous, boutiques
///   suivies…), boutiques ensuite (sélection, près de chez vous, mieux
///   notées, nouvelles, à découvrir).
///
/// Une section que le serveur n'a pas remplie n'est pas affichée : l'écran
/// reste court et sans « bientôt disponible ». Un invité voit la même chose
/// qu'un client ; seul ce qui demande un compte lui propose de se connecter.
class AccueilBoutiquesPage extends StatefulWidget {
  final User? user;
  final bool isGuest;

  const AccueilBoutiquesPage({super.key, this.user, this.isGuest = false});

  @override
  State<AccueilBoutiquesPage> createState() => _AccueilBoutiquesPageState();
}

class _AccueilBoutiquesPageState extends State<AccueilBoutiquesPage>
    with RouteAware, RetourSurOnglet {
  AccueilPersonnalise? _accueil;
  bool _chargement = true;
  String? _erreur;
  int _nonLues = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) observateurRoutes.subscribe(this, route);
  }

  @override
  void dispose() {
    observateurRoutes.unsubscribe(this);
    super.dispose();
  }

  /// Retour sur l'accueil (après une recherche, une fiche produit, une
  /// boutique) : ces gestes ont fait évoluer les recommandations, on les
  /// recalcule sans masquer l'écran actuel.
  @override
  void surRetourOnglet() => didPopNext();

  @override
  void didPopNext() {
    _charger();
    _chargerNonLues();
  }

  @override
  void initState() {
    super.initState();
    _charger();
    _chargerNonLues();
  }

  /// Pastille de la cloche : nombre de notifications non lues.
  Future<void> _chargerNonLues() async {
    if (widget.isGuest) return;
    try {
      final n = await sl<NotificationsRemoteDataSource>().nombreNonLues();
      if (mounted) setState(() => _nonLues = n);
    } catch (_) {
      /* badge masqué */
    }
  }

  Future<void> _ouvrirNotifications() async {
    // Un invité n'a pas de notifications : la page s'ouvre quand même, et
    // dit simplement qu'il n'y en a aucune (pas de détour par la connexion).
    if (widget.isGuest) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const _NotificationsInvite()));
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
    _chargerNonLues();
  }

  /// Les centres d'intérêt d'un invité vivent sur son téléphone.
  List<String> _interetsLocaux() {
    if (!widget.isGuest) return const [];
    return lireInteretsLocaux(kProprietaireInvite);
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = _accueil == null;
      _erreur = null;
    });
    final position = const LocalisationService().positionMemorisee();
    try {
      var accueil = await AccueilRemoteDataSource(sl<Dio>()).charger(
        interets: _interetsLocaux(),
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      // La rangée de catégories ne doit jamais manquer : sans elle un
      // nouveau venu n'a aucun point d'entrée.
      if (accueil.categories.isEmpty) {
        accueil = AccueilPersonnalise(
          invite: accueil.invite,
          interets: accueil.interets,
          positionConnue: accueil.positionConnue,
          sections: accueil.sections,
          categories: await CategoriesRemoteDataSource(sl<Dio>()).lister(),
        );
      }
      if (!mounted) return;
      setState(() {
        _accueil = accueil;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Impossible de charger l\'accueil. Vérifiez votre connexion.';
        _chargement = false;
      });
    }
  }

  void _rechercher(String texte) {
    if (texte.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProduitsPage(titre: 'Résultats', recherche: texte.trim()),
      ),
    );
  }

  void _ouvrirCategorie(Categorie c) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ProduitsPage(titre: c.nom, categorie: c),
    ),
  );

  Future<void> _modifierInterets() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InteretsPage(
          user: widget.user,
          isGuest: widget.isGuest,
          modeEdition: true,
        ),
      ),
    );
    if (mounted) _charger();
  }

  /// « Voir tout » d'une section. Promotions et nouveautés ouvrent le
  /// catalogue complet (filtres, compte à rebours) ; les autres sections
  /// leur liste complète, calculée par le serveur avec les mêmes règles.
  void _voirTout(String cle, String titre) {
    final Widget page = switch (cle) {
      'promotions' => const ProduitsPage(titre: 'Promotions', promotions: true),
      'nouveautes' => const ProduitsPage(titre: 'Nouveautés'),
      _ => SectionAccueilPage(
        cle: cle,
        titre: titre,
        interets: _interetsLocaux(),
        position: const LocalisationService().positionMemorisee(),
      ),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  // L'en-tête bleu est posé PAR-DESSUS la page : la liste défile dessous, et
  // ce qui passe derrière ses coins arrondis reste visible (au lieu d'un
  // fond blanc dans les coins). Sa hauteur, mesurée après le rendu, réserve
  // la place du début de la liste.
  final GlobalKey _cleEntete = GlobalKey();
  double _hauteurEntete = 200;

  void _mesurerEntete() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final boite = _cleEntete.currentContext?.findRenderObject();
      if (!mounted || boite is! RenderBox || !boite.hasSize) return;
      final h = boite.size.height;
      if ((h - _hauteurEntete).abs() > 0.5) {
        setState(() => _hauteurEntete = h);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _mesurerEntete();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColor.kWhite,
        body: Stack(
          children: [
            Positioned.fill(
              child: RefreshIndicator(
                edgeOffset: _hauteurEntete,
                onRefresh: () async {
                  _chargerNonLues();
                  await _charger();
                },
                color: AppColor.kPrimary,
                backgroundColor: AppColor.kWhite,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: _hauteurEntete)),
                    ..._corps(),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: kEspaceBarreBas),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: KeyedSubtree(
                key: _cleEntete,
                child: _EnteteAccueil(
                  user: widget.user,
                  isGuest: widget.isGuest,
                  nonLues: _nonLues,
                  onNotifications: _ouvrirNotifications,
                  onRecherche: _rechercher,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _corps() {
    if (_chargement) {
      return const [SliverToBoxAdapter(child: _SqueletteAccueil())];
    }
    if (_erreur != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: EtatVide(
              icone: Icons.wifi_off_rounded,
              titre: 'Pas de connexion',
              message: _erreur,
              action: 'Réessayer',
              onAction: _charger,
            ),
          ),
        ),
      ];
    }

    final accueil = _accueil!;
    final parCle = {
      for (final s in accueil.sections)
        if (s.elements.isNotEmpty) s.cle: s,
    };

    final blocs = <Widget>[];
    final categories = _categoriesOrdonnees(accueil);
    if (categories.isNotEmpty) {
      blocs.add(
        _RangeeCategories(categories: categories, onTap: _ouvrirCategorie),
      );
    }

    final promotions = parCle.remove('promotions');
    if (promotions != null) {
      blocs.add(
        _BlocPromotions(
          section: promotions,
          onVoirTout: () => _voirTout(promotions.cle, 'Promotions'),
        ),
      );
    }

    // Extraction des produits destines a la section "Pour vous" en bas
    // (dapresRecherches, pourVous, produitsPourVous)
    final sectionsPourVous = <AccueilSection>[];
    for (final cle in ['dapresRecherches', 'pourVous', 'produitsPourVous']) {
      // Seules les sections de produits rejoignent la grille : une section
      // de boutiques y apparaissait en fausses cartes produit à « 0 FCFA ».
      if (parCle[cle]?.type != 'produits') continue;
      sectionsPourVous.add(parCle.remove(cle)!);
    }

    // Ordre fixe des sections restantes en carrousels
    final ordre = [
      for (final cle in _ordreSections)
        if (!(widget.isGuest && _connecteSeulement.contains(cle))) cle,
      ...parCle.keys.where((k) => !_ordreSections.contains(k)),
    ];
    for (final cle in ordre) {
      final s = parCle[cle];
      if (s == null) {
        // L'invitation ne s'affiche que tant que la position n'est pas
        // connue : une fois la géolocalisation activée, elle disparaît.
        if (cle == 'proches' &&
            !accueil.positionConnue &&
            !localisationActivee()) {
          blocs.add(
            _InviteLocalisation(
              onActiver: () async {
                if (await activerLocalisation(context)) _charger();
              },
            ),
          );
        }
        continue;
      }
      blocs.add(
        s.type == 'produits'
            ? _SectionProduits(
                section: s,
                onVoirTout: () => _voirTout(s.cle, s.titre),
              )
            : _SectionBoutiques(
                section: s,
                onVoirTout: () => _voirTout(s.cle, s.titre),
              ),
      );
    }

    // Produits pour la section "Pour vous" tout en bas en grille 2 colonnes (style SHEIN)
    final tousPourVous = <ProduitCatalogue>[];
    final vus = <String>{};
    for (final s in sectionsPourVous) {
      for (final el in s.elements) {
        final p = ProduitCatalogue.fromJson(el);
        if (vus.add(p.id)) tousPourVous.add(p);
      }
    }
    // Si la liste est courte, on complete avec les produits du catalogue
    if (tousPourVous.length < 6) {
      for (final s in accueil.sections) {
        if (s.type == 'produits') {
          for (final el in s.elements) {
            final p = ProduitCatalogue.fromJson(el);
            if (vus.add(p.id)) tousPourVous.add(p);
          }
        }
      }
    }

    if (tousPourVous.isNotEmpty) {
      blocs.add(_SectionPourVousGrille(produits: tousPourVous));
    }

    if (parCle.isEmpty && promotions == null) {
      blocs.add(
        const EtatVide(
          icone: Icons.storefront_outlined,
          titre: 'Les boutiques s’installent',
          message:
              'Les premiers produits seront bientôt en ligne. En attendant, parcourez les catégories.',
          compact: true,
        ),
      );
    }

    if (accueil.interets.isNotEmpty) {
      blocs.add(
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Center(
            child: TextButton.icon(
              onPressed: _modifierInterets,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Modifier mes centres d’intérêt'),
            ),
          ),
        ),
      );
    }

    return [
      for (var i = 0; i < blocs.length; i++)
        SliverToBoxAdapter(
          child: Apparition(rang: i, child: blocs[i]),
        ),
    ];
  }

  /// Toutes les catégories, celles des centres d'intérêt du client en
  /// premier.
  List<Categorie> _categoriesOrdonnees(AccueilPersonnalise accueil) {
    final preferees = <Categorie>[
      for (final nom in accueil.interets)
        ...accueil.categories.where((c) => c.correspond(nom)).take(1),
    ];
    return [
      ...preferees,
      ...accueil.categories.where((c) => !preferees.contains(c)),
    ];
  }

  static const _ordreSections = [
    'nouveautes',
    'produitsPourVous',
    'dapresRecherches',
    'abonnements',
    'suivies',
    'pourVous',
    'proches',
    'meilleures',
    'nouvelles',
    'aDecouvrir',
  ];

  static const _connecteSeulement = {
    'dapresRecherches',
    'abonnements',
    'suivies',
  };
}

/// En-tête fixe avec courbure arrondie au bas (32 px) comme sur l'image de référence :
/// avatar utilisateur, salutation, cloche et panier en verre, carte hero active,
/// et grande barre de recherche en pilule.
class _EnteteAccueil extends StatelessWidget {
  final User? user;
  final bool isGuest;
  final int nonLues;
  final VoidCallback onNotifications;
  final ValueChanged<String> onRecherche;

  const _EnteteAccueil({
    this.user,
    this.isGuest = false,
    required this.nonLues,
    required this.onNotifications,
    required this.onRecherche,
  });

  String get _nomAffiche {
    if (isGuest || user == null) return 'Invité';
    final p = user!.prenom.trim();
    final n = user!.nom.trim();
    if (p.isNotEmpty) return '$p $n'.trim();
    return user!.nomAffiche;
  }

  String get _initiales {
    if (isGuest || user == null) return 'SA';
    final p = user!.prenom.trim();
    final n = user!.nom.trim();
    final p0 = p.isNotEmpty ? p[0] : '';
    final n0 = n.isNotEmpty ? n[0] : '';
    final init = '$p0$n0'.toUpperCase();
    return init.isNotEmpty ? init : 'SB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF01154B), Color(0xFF08226D)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x2801154B),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne 1 : Pictogramme seul a gauche (sans texte), Cloche, Panier et Avatar a droite
              Row(
                children: [
                  Image.asset(
                    'assets/images/picto_clair.png',
                    height: 38,
                    fit: BoxFit.contain,
                    semanticLabel: 'SaamBiz',
                  ),
                  const Spacer(),
                  // Bouton Cloche en verre
                  _BoutonVerreRond(
                    onTap: onNotifications,
                    badge: nonLues > 0 ? (nonLues > 99 ? '99+' : '') : null,
                    icon: Icons.notifications_none_rounded,
                  ),
                  const SizedBox(width: 8),
                  // Bouton Panier en verre
                  const _BoutonPanierVerreRond(),
                  if (!isGuest && user != null && _initiales.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.kSecondary,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initiales,
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontWeight: FontWeight.w800,
                          color: AppColor.kPrimary,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (!isGuest && user != null && _nomAffiche.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _nomAffiche,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (user!.email.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user!.email.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 14),
              // Barre de recherche grande pilule arrondie
              _BarreRecherchePilule(onRecherche: onRecherche),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoutonVerreRond extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String? badge;

  const _BoutonVerreRond({required this.onTap, required this.icon, this.badge});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: badge != null
            ? Badge(
                label: Text(badge!),
                backgroundColor: AppColor.kSecondary,
                textColor: AppColor.kPrimary,
                child: Icon(icon, color: Colors.white, size: 21),
              )
            : Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }
}

class _BoutonPanierVerreRond extends StatelessWidget {
  const _BoutonPanierVerreRond();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: const BoutonPanier(couleur: Colors.white),
    );
  }
}

/// Champ de recherche grande pilule arrondie
class _BarreRecherchePilule extends StatelessWidget {
  final ValueChanged<String> onRecherche;
  const _BarreRecherchePilule({required this.onRecherche});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        textInputAction: TextInputAction.search,
        onSubmitted: onRecherche,
        style: const TextStyle(
          fontFamily: kPolice,
          fontSize: 14,
          color: AppColor.kGrayscaleDark100,
        ),
        decoration: const InputDecoration(
          hintText: 'Rechercher un produit, une boutique...',
          hintStyle: TextStyle(
            fontFamily: kPolice,
            color: AppColor.kGrayscale40,
            fontSize: 13.5,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColor.kPrimary,
            size: 22,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

/// Categories en pastilles avec forme carree arrondie moderne (style Image 1 "Services")
class _RangeeCategories extends StatelessWidget {
  final List<Categorie> categories;
  final ValueChanged<Categorie> onTap;
  const _RangeeCategories({required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final largeur = ((MediaQuery.sizeOf(context).width - 32 - 4 * 12) / 5)
        .clamp(62.0, 80.0);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: SizedBox(
        height: largeur + 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final toutes = i == categories.length;
            final c = toutes ? null : categories[i];
            return Pressable(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: toutes
                    ? () => ongletAcheteurDemande.value = 1
                    : () => onTap(c!),
                child: SizedBox(
                  width: largeur,
                  child: Column(
                    children: [
                      Container(
                        width: largeur,
                        height: largeur,
                        decoration: BoxDecoration(
                          color: toutes
                              ? const Color(0xFFFFF0E0)
                              : const Color(0xFFF1F5FD),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: toutes
                                ? const Color(0xFFFFCC80)
                                : const Color(0xFFE3EBF8),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          toutes
                              ? Icons.grid_view_rounded
                              : iconeCategorie(c!.icone),
                          color: toutes
                              ? const Color(0xFFE65100)
                              : AppColor.kPrimary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _LibelleCategorie(
                        toutes ? 'Tout voir' : _nomCourt(c!.nom),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _nomCourt(String nom) {
    final coupe = nom.split(RegExp(r'\s*(&|,| et )\s*')).first.trim();
    return coupe.isEmpty ? nom : coupe;
  }
}

/// Promotions du moment : un bandeau marine, le seul de l'écran, avec le
/// carrousel des produits remisés posés sur des cartes blanches.
class _BlocPromotions extends StatelessWidget {
  final AccueilSection section;
  final VoidCallback onVoirTout;
  const _BlocPromotions({required this.section, required this.onVoirTout});

  @override
  Widget build(BuildContext context) {
    final produits = section.elements
        .map(ProduitCatalogue.fromJson)
        .toList(growable: false);
    final remiseMax = produits.fold<int>(
      0,
      (m, p) => p.remise > m ? p.remise : m,
    );
    final largeurCarte =
        (MediaQuery.sizeOf(context).width - 16 * 2 - 12) / 2.35;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        // Fond doré très clair : le bloc se remarque sans écraser l'écran,
        // même avec une seule promotion.
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6DB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFBE3A0)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColor.kPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_offer_rounded,
                          color: AppColor.kSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.titre.isEmpty
                                  ? 'Promotions du moment'
                                  : section.titre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: kPolice,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: AppColor.kPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              remiseMax > 0
                                  ? 'Jusqu’à -$remiseMax %, pour peu de temps'
                                  : 'Pour peu de temps',
                              style: TextStyle(
                                fontFamily: kPolice,
                                fontSize: 12.5,
                                color: AppColor.kSecondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: onVoirTout,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(10, 8, 4, 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Voir tout',
                                style: TextStyle(
                                  fontFamily: kPolice,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.kPrimary,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: AppColor.kPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: (largeurCarte - 12) / ratioCarteProduit + 24,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                    itemCount: produits.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => SizedBox(
                      width: largeurCarte,
                      child: ProduitCard(
                        produit: produits[i],
                        surFond: true,
                        avecAjout: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nom d'une catégorie sous sa tuile. Plusieurs mots passent sur deux
/// lignes, entre les mots ; un mot seul (« Chaussures ») reste entier sur
/// une ligne et rétrécit un peu si besoin, plutôt que d'être coupé en
/// « Chaussure / s ».
class _LibelleCategorie extends StatelessWidget {
  final String texte;
  const _LibelleCategorie(this.texte);

  static const _style = TextStyle(
    fontFamily: kPolice,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColor.kGrayscaleDark100,
  );

  @override
  Widget build(BuildContext context) {
    final t = texte.trim();
    if (!t.contains(' ')) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(t, maxLines: 1, style: _style),
      );
    }
    return Text(
      t,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: _style,
    );
  }
}

/// Titre de section de l'accueil, à la marge de l'écran.
class _TitreSection extends StatelessWidget {
  final AccueilSection section;
  final VoidCallback onVoirTout;
  const _TitreSection({required this.section, required this.onVoirTout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 10, 12),
      child: EnteteSection(
        section.titre,
        sousTitre: section.sousTitre,
        action: 'Voir tout',
        onAction: onVoirTout,
      ),
    );
  }
}

/// Section de produits : un carrousel, deux cartes et un peu de la
/// troisième à l'écran (on comprend qu'il y en a d'autres).
class _SectionProduits extends StatelessWidget {
  final AccueilSection section;
  final VoidCallback onVoirTout;
  const _SectionProduits({required this.section, required this.onVoirTout});

  @override
  Widget build(BuildContext context) {
    final largeurCarte =
        (MediaQuery.sizeOf(context).width - 16 * 2 - 12) / 2.35;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TitreSection(section: section, onVoirTout: onVoirTout),
        SizedBox(
          height: largeurCarte / ratioCarteProduit,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.elements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: largeurCarte,
              child: ProduitCard(
                produit: ProduitCatalogue.fromJson(section.elements[i]),
                avecAjout: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Section de boutiques : un carrousel horizontal de grandes cartes boutiques.
class _SectionBoutiques extends StatelessWidget {
  final AccueilSection section;
  final VoidCallback onVoirTout;
  const _SectionBoutiques({required this.section, required this.onVoirTout});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TitreSection(section: section, onVoirTout: onVoirTout),
        SizedBox(
          height: _CarteBoutique.hauteur + 16,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: section.elements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => _CarteBoutique(donnees: section.elements[i]),
          ),
        ),
      ],
    );
  }
}

/// Carte d'une boutique amelioree : carte profil de magasin distinctive,
/// differente d'une carte produit, avec avatar, categorie, note, et bouton Visiter.
class _CarteBoutique extends StatelessWidget {
  final Map<String, dynamic> donnees;
  final double largeur;
  const _CarteBoutique({required this.donnees, this.largeur = 275});

  static const double hauteur = 126;

  void _ouvrir(BuildContext context) {
    final id = donnees['id']?.toString();
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BoutiquePubliquePage(
          boutiqueId: id,
          apercu: BoutiqueResume.fromJson(donnees),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logo = donnees['logo']?.toString();
    final nom = donnees['nom']?.toString() ?? 'Boutique';
    final verifiee = donnees['verifiee'] == true;
    final distance = donnees['distanceKm'];
    final note = donnees['note'];
    final details = [
      donnees['categorie']?.toString(),
      donnees['localisation']?.toString(),
    ].where((e) => e != null && e.isNotEmpty).join(' · ');

    final nbArticles = donnees['nombreProduits'];

    return Pressable(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _ouvrir(context),
        child: Container(
          width: largeur,
          height: hauteur,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColor.kWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColor.kLine, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColor.kPrimary.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo boutique dans un conteneur arrondi
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColor.kPrimaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColor.kLine),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: logo != null && logo.isNotEmpty
                      ? ImageReseau(
                          logo,
                          largeurServeur: 160,
                          repli: const LogoBoutiqueParDefaut(rayon: 15),
                        )
                      : const LogoBoutiqueParDefaut(rayon: 15),
                ),
              ),
              const SizedBox(width: 12),
              // Nom, categorie, note et distance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: kPolice,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColor.kGrayscaleDark100,
                            ),
                          ),
                        ),
                        if (verifiee) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: AppColor.kSecondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      details.isNotEmpty ? details : 'Boutique certifiée',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 11.5,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.kSecondaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppColor.kSecondaryDark,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                note != null ? '$note' : '4.8',
                                style: const TextStyle(
                                  fontFamily: kPolice,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.kSecondaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            distance != null
                                ? '${distance.toStringAsFixed(1)} km'
                                : (nbArticles != null
                                      ? '$nbArticles articles'
                                      : 'Boutique active'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: kPolice,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColor.kGrayscale40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Bouton fleche vers la boutique
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColor.kPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppColor.kPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « Près de chez vous » sans position connue : une ligne qui propose
/// d'activer la localisation, à la place de la section.
class _InviteLocalisation extends StatelessWidget {
  final VoidCallback onActiver;
  const _InviteLocalisation({required this.onActiver});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColor.kBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const PastilleIcone(Icons.near_me_outlined, taille: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Près de chez vous', style: titreSection(14.5)),
                  const SizedBox(height: 2),
                  Text(
                    'Activez la géolocalisation pour voir les boutiques de votre quartier.',
                    style: texteDiscret(12.5),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: onActiver,
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Activer la géolocalisation'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.kPrimary,
                      foregroundColor: AppColor.kWhite,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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

/// « Voir tout » d'une section de l'accueil : tous ses produits (grille) ou
/// toutes ses boutiques, avec les mêmes cartes que l'accueil.
class SectionAccueilPage extends StatefulWidget {
  final String cle;
  final String titre;
  final List<String> interets;
  final ({double latitude, double longitude})? position;

  const SectionAccueilPage({
    super.key,
    required this.cle,
    required this.titre,
    this.interets = const [],
    this.position,
  });

  @override
  State<SectionAccueilPage> createState() => _SectionAccueilPageState();
}

class _SectionAccueilPageState extends State<SectionAccueilPage> {
  AccueilSection? _section;
  bool _chargement = true;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = _section == null;
      _erreur = false;
    });
    try {
      final section = await AccueilRemoteDataSource(sl<Dio>()).chargerSection(
        widget.cle,
        interets: widget.interets,
        latitude: widget.position?.latitude,
        longitude: widget.position?.longitude,
      );
      if (!mounted) return;
      setState(() {
        _section = section;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erreur = true;
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMarine(
      backgroundColor: AppColor.kWhite,
      appBar: AppBar(title: Text(widget.titre)),
      body: _corps(),
    );
  }

  Widget _corps() {
    if (_chargement) {
      return const _SqueletteGrille();
    }
    if (_erreur) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Chargement impossible',
        subtitle: 'Vérifiez votre connexion puis réessayez.',
        actionLabel: 'Réessayer',
        onAction: _charger,
      );
    }
    final elements = _section?.elements ?? const <Map<String, dynamic>>[];
    if (elements.isEmpty) {
      return EmptyState(
        icon: _section?.type == 'produits'
            ? Icons.inventory_2_outlined
            : Icons.storefront_outlined,
        title: 'Rien pour le moment',
        subtitle: 'Cette section se remplira dès que les boutiques publieront.',
      );
    }
    final produits = _section!.type == 'produits';
    final largeur = MediaQuery.sizeOf(context).width;
    final colonnes = largeur >= 600 ? 3 : 2;
    return RefreshIndicator(
      color: AppColor.kPrimary,
      onRefresh: _charger,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: produits
            ? grilleProduits(context)
            : SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: colonnes,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                mainAxisExtent: _CarteBoutique.hauteur,
              ),
        itemCount: elements.length,
        itemBuilder: (_, i) => produits
            ? ProduitCard(
                produit: ProduitCatalogue.fromJson(elements[i]),
                avecAjout: true,
              )
            : LayoutBuilder(
                builder: (_, c) =>
                    _CarteBoutique(donnees: elements[i], largeur: c.maxWidth),
              ),
      ),
    );
  }
}

/// Squelette de l'accueil pendant le chargement : la forme de ce qui
/// arrive, catégories, bandeau des promotions, carrousel.
class _SqueletteAccueil extends StatelessWidget {
  const _SqueletteAccueil();

  @override
  Widget build(BuildContext context) {
    final largeurCarte =
        (MediaQuery.sizeOf(context).width - 16 * 2 - 12) / 2.35;
    return Reflet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < 5; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  const Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Os(hauteur: double.infinity, rayon: 18),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 26),
            const Os(hauteur: 250, rayon: 24),
            const SizedBox(height: 26),
            const Os(largeur: 140, hauteur: 16, rayon: 6),
            const SizedBox(height: 14),
            SizedBox(
              height: largeurCarte / ratioCarteProduit,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => Os(
                  largeur: largeurCarte,
                  hauteur: double.infinity,
                  rayon: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Squelette d'une page « Voir tout » : grille de cartes produits.
class _SqueletteGrille extends StatelessWidget {
  const _SqueletteGrille();

  @override
  Widget build(BuildContext context) {
    return Reflet(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: grilleProduits(context),
        itemCount: 6,
        itemBuilder: (_, __) => const Os(hauteur: double.infinity, rayon: 14),
      ),
    );
  }
}

/// Section « Pour vous » tout en bas de la page d'accueil :
/// grille 2 colonnes comme sur les images de reference SHEIN.
class _SectionPourVousGrille extends StatelessWidget {
  final List<ProduitCatalogue> produits;
  const _SectionPourVousGrille({required this.produits});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColor.kSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pour vous',
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColor.kGrayscaleDark100,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sélection personnalisée selon vos recherches et vos goûts',
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 12,
                      color: AppColor.kGrayscale40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Grille 2 colonnes
          for (var i = 0; i < produits.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _CarteProduitPourVous(produit: produits[i])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < produits.length
                        ? _CarteProduitPourVous(produit: produits[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte produit style SHEIN (Images 3 & 4) :
/// grande image nette, badges superposes, prix clair, tag d'interet.
class _CarteProduitPourVous extends StatelessWidget {
  final ProduitCatalogue produit;
  const _CarteProduitPourVous({required this.produit});

  @override
  Widget build(BuildContext context) {
    final aRemise = produit.remise > 0;
    final tagTexte = produit.remise > 0
        ? 'Dernier jour'
        : (produit.nouveau ? 'Nouveauté' : 'Recommandé');

    return Pressable(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProduitDetailPage(produit: produit),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColor.kWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.kLine, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColor.kPrimary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo du produit
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 0.96,
                    child: produit.image.isNotEmpty
                        ? ImageReseau(
                            produit.image,
                            fit: BoxFit.cover,
                            largeurServeur: 400,
                          )
                        : ColoredBox(
                            color: AppColor.kPrimaryLight,
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 38,
                              color: AppColor.kPrimary,
                            ),
                          ),
                  ),
                  // Badge promo / categorie en haut a gauche
                  if (aRemise)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${produit.remise}%',
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Bouton favoris en haut a droite
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.88),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 17,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                  ),
                ],
              ),
              // Contenu texte
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag descriptif (style SHEIN "Coton Extensible >")
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tagTexte,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Nom du produit
                    Text(
                      produit.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Prix & Remise
                    Row(
                      children: [
                        Text(
                          formaterPrix(produit.prixPaye),
                          style: TextStyle(
                            fontFamily: kPolice,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: aRemise
                                ? const Color(0xFFDC2626)
                                : AppColor.kPrimary,
                          ),
                        ),
                        if (produit.prixBarre != null) ...[
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              formaterPrix(produit.prixBarre!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: kPolice,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                color: AppColor.kGrayscale40,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Hors de la photo, comme sur les autres cartes.
                        BoutonAjoutPanier(produit: produit, taille: 30),
                      ],
                    ),
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

/// Notifications d'un invité : il n'en reçoit pas, la page le dit.
class _NotificationsInvite extends StatelessWidget {
  const _NotificationsInvite();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMarine(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(
        child: EtatVide(
          icone: Icons.notifications_none_rounded,
          titre: 'Aucune notification',
          message: 'Vos commandes et vos alertes apparaîtront ici.',
        ),
      ),
    );
  }
}
