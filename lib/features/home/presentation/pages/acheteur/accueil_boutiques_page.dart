import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saambiz/core/widgets/logo_boutique.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/utils/image_url.dart';

import '../../../../../core/services/localisation_service.dart';
import '../../../../../core/theme/app_color.dart';
import '../../../../../core/widgets/barre_navigation_verre.dart'
    show kEspaceBarreBas;
import '../../../../../core/widgets/ui_kit.dart';
import '../../../../../core/widgets/animations.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/domain/entities/user.dart';
import '../../../../auth/presentation/signup/interets_page.dart';
import '../../../../catalogue/data/produit_catalogue.dart';
import '../../../../categories/data/categorie.dart';
import '../../../../categories/presentation/icones_categories.dart';
import '../../../../catalogue/presentation/pages/boutique_publique_page.dart';
import '../../../../catalogue/presentation/pages/produits_page.dart';
import '../../../../catalogue/presentation/widgets/bouton_panier.dart';
import '../../../../catalogue/presentation/widgets/produit_card.dart';
import '../../../../notifications/data/datasources/notifications_remote_datasource.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../../core/routes/app_router.dart';
import '../../../../../core/routes/observateur_routes.dart';
import '../../../data/datasources/accueil_remote_datasource.dart';
import '../../../../../core/widgets/app_app_bar.dart';
import '../../../../../core/widgets/empty_state.dart';

/// Accueil du client (connecté ou invité).
///
/// En tête : logo, notifications, panier et recherche. Ensuite les sections
/// servies par le backend : promotions en bandeau, produits en grille,
/// boutiques réunies dans un bloc à onglets. Un invité voit exactement la
/// même chose qu'un client : seul ce qui demande un compte (suivre, commander)
/// lui propose de se connecter.
class AccueilBoutiquesPage extends StatefulWidget {
  final User? user;
  final bool isGuest;

  const AccueilBoutiquesPage({super.key, this.user, this.isGuest = false});

  @override
  State<AccueilBoutiquesPage> createState() => _AccueilBoutiquesPageState();
}

class _AccueilBoutiquesPageState extends State<AccueilBoutiquesPage>
    with RouteAware {
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
    // Un invité n'a pas de notifications : on lui propose de se connecter.
    if (widget.isGuest) {
      Navigator.of(context).pushNamed(AppRouter.loginRoute);
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
      final accueil = await AccueilRemoteDataSource(sl<Dio>()).charger(
        interets: _interetsLocaux(),
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
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

  @override
  Widget build(BuildContext context) {
    // En-tête compact (logo, cloche, panier, recherche), puis un fil
    // vertical : promotions en bandeau, produits en grille, boutiques en
    // liste. Les catégories ont leur propre onglet.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
        body: Column(
          children: [
            _entete(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _chargerNonLues();
                  await _charger();
                },
                color: AppColor.kPrimary,
                child: CustomScrollView(
                  slivers: [
                    ..._corps(),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: kEspaceBarreBas),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entete() {
    return Container(
      color: AppColor.kPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo_clair.png',
                    height: 26,
                    fit: BoxFit.contain,
                    semanticLabel: 'SaamBiz',
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: _ouvrirNotifications,
                    icon: Badge(
                      isLabelVisible: _nonLues > 0,
                      backgroundColor: AppColor.kSecondary,
                      textColor: AppColor.kPrimary,
                      label: Text(_nonLues > 99 ? '99+' : '$_nonLues'),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColor.kWhite,
                      ),
                    ),
                  ),
                  const BoutonPanier(couleur: AppColor.kWhite),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChampRecherche(onSubmitted: _rechercher),
              ),
            ],
          ),
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
        SliverToBoxAdapter(
          child: EtatVide(
            icone: Icons.wifi_off_rounded,
            titre: 'Pas de connexion',
            message: _erreur,
            action: 'Réessayer',
            onAction: _charger,
          ),
        ),
      ];
    }

    final sections = (_accueil?.sections ?? const <AccueilSection>[])
        .where((s) => s.elements.isNotEmpty)
        .toList();
    final parCle = {for (final s in sections) s.cle: s};
    final ordre = [
      for (final b in _blocsAccueil)
        if (!(b.connecteSeulement && widget.isGuest)) b.cle,
    ];
    // Section ajoutée côté serveur et inconnue de l'application : à la suite.
    ordre.addAll(parCle.keys.where((k) => !ordre.contains(k)));

    final produits = [
      for (final k in ordre)
        if (parCle[k]?.type == 'produits') parCle[k]!,
    ];
    final boutiques = [
      for (final k in ordre)
        if (parCle[k] != null && parCle[k]!.type != 'produits') parCle[k]!,
    ];

    if (produits.isEmpty && boutiques.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: EtatVide(
            icone: Icons.storefront_outlined,
            titre: 'Aucun produit pour le moment',
            message:
                'Les premiers produits seront bientôt en ligne. En attendant, parcourez les catégories.',
            compact: true,
          ),
        ),
      ];
    }

    final blocs = <Widget>[];
    final mesCategories = _mesCategories();
    if (mesCategories.isNotEmpty) blocs.add(_rangeeMesCategories(mesCategories));
    for (final s in produits) {
      blocs.add(
        s.cle == 'promotions' ? _bandeauProduits(s) : _grilleProduits(s),
      );
    }
    if (boutiques.isNotEmpty) {
      blocs.add(_BlocBoutiques(sections: boutiques, onVoirTout: _voirTout));
    }
    if (_accueil?.interets.isNotEmpty ?? false) {
      blocs.add(
        Center(
          child: TextButton.icon(
            onPressed: _modifierInterets,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Modifier mes centres d’intérêt'),
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

  /// Catégories du client, dans l'ordre de ses goûts : celles choisies à
  /// l'inscription au départ, puis celles que ses recherches, visites et
  /// abonnements font monter.
  List<Categorie> _mesCategories() {
    final accueil = _accueil;
    if (accueil == null) return const [];
    return [
      for (final nom in accueil.interets)
        ...accueil.categories.where((c) => c.correspond(nom)).take(1),
    ];
  }

  /// « Vos catégories » : raccourcis en tête d'accueil.
  Widget _rangeeMesCategories(List<Categorie> categories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: EnteteSection(
              'Vos catégories',
              action: 'Modifier',
              onAction: _modifierInterets,
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = categories[i];
                return PuceFiltre(
                  libelle: c.nom,
                  icone: iconeCategorie(c.icone),
                  active: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProduitsPage(titre: c.nom, categorie: c),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const List<_BlocAccueil> _blocsAccueil = [
    _BlocAccueil('promotions'),
    _BlocAccueil('produitsPourVous'),
    _BlocAccueil('dapresRecherches', connecteSeulement: true),
    _BlocAccueil('abonnements', connecteSeulement: true),
    _BlocAccueil('nouveautes'),
    _BlocAccueil('suivies', connecteSeulement: true),
    _BlocAccueil('pourVous'),
    _BlocAccueil('proches'),
    _BlocAccueil('meilleures'),
    _BlocAccueil('nouvelles'),
    _BlocAccueil('aDecouvrir'),
  ];

  /// Promotions : une seule rangée qui défile, sur fond or pâle (la
  /// couleur du logo), pour les distinguer du reste du fil.
  Widget _bandeauProduits(AccueilSection s) {
    final largeurCarte = (MediaQuery.sizeOf(context).width - 16 * 2 - 12) / 2.4;
    return Container(
      color: AppColor.kSecondaryLight,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 10),
            child: EnteteSection(
              s.titre,
              sousTitre: s.sousTitre,
              action: 'Voir tout',
              onAction: () => _voirTout(s.cle, s.titre),
            ),
          ),
          SizedBox(
            height: largeurCarte / ratioCarteProduit,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: s.elements.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: largeurCarte,
                child: ProduitCard(
                  produit: ProduitCatalogue.fromJson(s.elements[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Autres sections de produits : grille de deux colonnes, quatre
  /// produits au plus ; la suite est derrière « Voir tout ».
  Widget _grilleProduits(AccueilSection s) {
    final elements = s.elements.take(4).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EnteteSection(
              s.titre,
              sousTitre: s.sousTitre,
              action: s.elements.length > elements.length ? 'Voir tout' : null,
              onAction: () => _voirTout(s.cle, s.titre),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: grilleProduits(context),
            itemCount: elements.length,
            itemBuilder: (_, i) =>
                ProduitCard(produit: ProduitCatalogue.fromJson(elements[i])),
          ),
        ],
      ),
    );
  }
}

/// Bloc « Boutiques » : les sections de boutiques réunies sous des onglets
/// texte (Populaires, Nouvelles…), chacune en liste de quatre lignes.
class _BlocBoutiques extends StatefulWidget {
  final List<AccueilSection> sections;
  final void Function(String cle, String titre) onVoirTout;
  const _BlocBoutiques({required this.sections, required this.onVoirTout});

  @override
  State<_BlocBoutiques> createState() => _BlocBoutiquesState();
}

class _BlocBoutiquesState extends State<_BlocBoutiques> {
  int _choix = 0;

  /// Libellé court de chaque section pour l'onglet.
  static const _courts = {
    'suivies': 'Suivies',
    'pourVous': 'Pour vous',
    'proches': 'À proximité',
    'meilleures': 'Populaires',
    'nouvelles': 'Nouvelles',
    'aDecouvrir': 'À découvrir',
  };

  @override
  Widget build(BuildContext context) {
    final sections = widget.sections;
    final s = sections[_choix.clamp(0, sections.length - 1)];
    final lignes = s.elements.take(4).toList();
    return Container(
      color: AppColor.kWhite,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnteteSection(
            'Boutiques',
            action: 'Voir tout',
            onAction: () => widget.onVoirTout(s.cle, s.titre),
          ),
          if (sections.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sections.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => PuceFiltre(
                  libelle: _courts[sections[i].cle] ?? sections[i].titre,
                  active: i == _choix,
                  onTap: () => setState(() => _choix = i),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: Mouvement.normal,
            child: Column(
              key: ValueKey(s.cle),
              children: [
                for (var i = 0; i < lignes.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _LigneBoutique(donnees: lignes[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne d'une boutique : logo carré, nom, catégorie et ville, note.
class _LigneBoutique extends StatelessWidget {
  final Map<String, dynamic> donnees;
  const _LigneBoutique({required this.donnees});

  @override
  Widget build(BuildContext context) {
    final logo = donnees['logo']?.toString();
    final verifiee = donnees['verifiee'] == true;
    final distance = donnees['distanceKm'];
    final note = donnees['note'];
    final id = donnees['id']?.toString();
    final details = [
      donnees['categorie']?.toString(),
      donnees['localisation']?.toString(),
      if (distance != null) '$distance km',
    ].where((e) => e != null && e.isNotEmpty).join(', ');

    return InkWell(
      onTap: id == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BoutiquePubliquePage(
                  boutiqueId: id,
                  apercu: BoutiqueResume.fromJson(donnees),
                ),
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: logo != null && logo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageOptimisee(logo, largeur: 160),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const _VisuelParDefaut(),
                      )
                    : const _VisuelParDefaut(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          donnees['nom']?.toString() ?? 'Boutique',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColor.kGrayscaleDark100,
                          ),
                        ),
                      ),
                      if (verifiee) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: AppColor.kSucces,
                        ),
                      ],
                    ],
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: texteDiscret(12.5),
                    ),
                  ],
                ],
              ),
            ),
            if (note != null) ...[
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: AppColor.kSecondary,
              ),
              const SizedBox(width: 2),
              Text(
                '$note',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kGrayscaleDark100,
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColor.kGrayscale30,
            ),
          ],
        ),
      ),
    );
  }
}

class _VisuelParDefaut extends StatelessWidget {
  const _VisuelParDefaut();

  @override
  Widget build(BuildContext context) => const LogoBoutiqueParDefaut();
}

/// Bloc attendu sur l'accueil : clé de la section côté serveur, titre par
/// défaut, icône et message quand elle est vide.
class _BlocAccueil {
  final String cle;
  final bool connecteSeulement;
  const _BlocAccueil(this.cle, {this.connecteSeulement = false});
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
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppAppBar(title: widget.titre),
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
    return RefreshIndicator(
      color: AppColor.kPrimary,
      onRefresh: _charger,
      child: produits
          ? GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: grilleProduits(context),
              itemCount: elements.length,
              itemBuilder: (_, i) =>
                  ProduitCard(produit: ProduitCatalogue.fromJson(elements[i])),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: elements.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _LigneBoutique(donnees: elements[i]),
            ),
    );
  }
}

/// Squelette de l'accueil pendant le chargement : la forme de ce qui
/// arrive, un bandeau de produits puis une grille.
class _SqueletteAccueil extends StatelessWidget {
  const _SqueletteAccueil();

  @override
  Widget build(BuildContext context) {
    final largeurCarte = (MediaQuery.sizeOf(context).width - 16 * 2 - 12) / 2.4;
    return Reflet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Os(largeur: 150, hauteur: 16, rayon: 6),
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
                  rayon: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Os(largeur: 120, hauteur: 16, rayon: 6),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: grilleProduits(context),
              itemCount: 2,
              itemBuilder: (_, __) =>
                  const Os(hauteur: double.infinity, rayon: 12),
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
        itemBuilder: (_, __) => const Os(hauteur: double.infinity, rayon: 12),
      ),
    );
  }
}
