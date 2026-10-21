import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/utils/image_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/services/localisation_service.dart';
import '../../../../../core/theme/app_color.dart';
import '../../../../../core/widgets/barre_navigation_verre.dart' show kEspaceBarreBas;
import '../../../../../core/widgets/ui_kit.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/domain/entities/user.dart';
import '../../../../auth/presentation/signup/interets_page.dart';
import '../../../../catalogue/data/produit_catalogue.dart';
import '../../../../catalogue/presentation/pages/boutique_publique_page.dart';
import '../../../../catalogue/presentation/pages/produits_page.dart';
import '../../../../catalogue/presentation/widgets/bouton_panier.dart';
import '../../../../catalogue/presentation/widgets/compte_a_rebours.dart';
import '../../../../catalogue/presentation/widgets/produit_card.dart';
import '../../../../notifications/data/datasources/notifications_remote_datasource.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../../core/routes/app_router.dart';
import '../../../../categories/data/categorie.dart';
import '../../../../categories/presentation/icones_categories.dart';
import '../../../data/datasources/accueil_remote_datasource.dart';
import '../../../../../core/widgets/app_app_bar.dart';
import '../../../../../core/widgets/empty_state.dart';

/// Accueil du client (connecté ou invité).
///
/// En tête : recherche, catégories. Ensuite les sections servies par le
/// backend, dans son ordre : promotions (avec compte à rebours), nouveautés,
/// boutiques suivies, boutiques recommandées… Un invité voit exactement la
/// même chose qu'un client : seul ce qui demande un compte (suivre, commander)
/// lui propose de se connecter.
class AccueilBoutiquesPage extends StatefulWidget {
  final User? user;
  final bool isGuest;

  const AccueilBoutiquesPage({super.key, this.user, this.isGuest = false});

  @override
  State<AccueilBoutiquesPage> createState() => _AccueilBoutiquesPageState();
}

class _AccueilBoutiquesPageState extends State<AccueilBoutiquesPage> {
  AccueilPersonnalise? _accueil;
  List<Categorie> _categories = const [];
  bool _chargement = true;
  String? _erreur;
  int _nonLues = 0;

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
    } catch (_) {/* badge masqué */}
  }

  Future<void> _ouvrirNotifications() async {
    // Un invité n'a pas de notifications : on lui propose de se connecter.
    if (widget.isGuest) {
      Navigator.of(context).pushNamed(AppRouter.loginRoute);
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
    _chargerNonLues();
  }

  /// Les centres d'intérêt d'un invité vivent sur son téléphone.
  List<String> _interetsLocaux() {
    if (!widget.isGuest) return const [];
    try {
      return sl<SharedPreferences>().getStringList(kInteretsKey) ?? const [];
    } catch (_) {
      return const [];
    }
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
      // La rangée de catégories ne doit jamais manquer : sans elle un
      // nouveau venu n'a aucun point d'entrée.
      final categories = accueil.categories.isNotEmpty
          ? accueil.categories
          : await CategoriesRemoteDataSource(sl<Dio>()).lister();
      if (!mounted) return;
      setState(() {
        _accueil = accueil;
        _categories = categories;
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
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProduitsPage(titre: 'Résultats', recherche: texte.trim()),
    ));
  }

  void _ouvrirCategorie(Categorie c) => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProduitsPage(titre: c.nom, categorie: c),
      ));

  Future<void> _modifierInterets() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => InteretsPage(user: widget.user, isGuest: widget.isGuest, modeEdition: true),
    ));
    if (mounted) _charger();
  }

  @override
  Widget build(BuildContext context) {
    // Accueil dans le style de Yobante Boutique : fond blanc, en-tête fixe
    // (pictogramme, cloche, panier, recherche), contenu qui défile dessous.
    return Scaffold(
      backgroundColor: AppColor.kWhite,
      body: Column(
        children: [
          Container(
            color: AppColor.kWhite,
            child: SafeArea(bottom: false, child: _entete()),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _chargerNonLues();
                await _charger();
              },
              color: AppColor.kPrimary,
              backgroundColor: AppColor.kWhite,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  ..._corps(),
                  const SliverToBoxAdapter(child: SizedBox(height: kEspaceBarreBas + 8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _entete() {
    final interets = _accueil?.interets ?? const <String>[];
    return Container(
      color: AppColor.kWhite,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/picto_navy.png', height: 36, fit: BoxFit.contain, semanticLabel: 'SaamBiz'),
              const Spacer(),
              // Cloche puis panier, tout à droite (mêmes tailles que Yobante
              // Boutique : cloche 40 × 40, icône 22 ; panier icône 24).
              Semantics(
                button: true,
                label: 'Notifications',
                child: GestureDetector(
                  onTap: _ouvrirNotifications,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Center(
                          child: Icon(Icons.notifications_none_rounded, color: AppColor.kPrimary, size: 22),
                        ),
                        if (_nonLues > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              constraints: const BoxConstraints(minWidth: 18),
                              decoration: BoxDecoration(
                                color: AppColor.kErreur,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Text(
                                _nonLues > 99 ? '99+' : '$_nonLues',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, height: 1.2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const BoutonPanier(),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChampRecherche(onSubmitted: _rechercher),
          ),
          if (interets.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  PuceFiltre(
                    libelle: 'Mes intérêts',
                    icone: Icons.tune_rounded,
                    active: true,
                    onTap: _modifierInterets,
                  ),
                  for (final i in interets)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: PuceFiltre(libelle: i, active: false, onTap: _modifierInterets),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _corps() {
    if (_chargement) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 120),
            child: Center(child: CircularProgressIndicator(color: AppColor.kPrimary, strokeWidth: 2.5)),
          ),
        ),
      ];
    }
    if (_erreur != null) {
      return [
        SliverToBoxAdapter(
          child: EtatVide(icone: Icons.wifi_off_rounded, titre: 'Pas de connexion', message: _erreur, action: 'Réessayer', onAction: _charger),
        ),
      ];
    }

    final recues = _accueil?.sections ?? const <AccueilSection>[];
    final sections = recues.where((s) => s.elements.isNotEmpty).toList();
    final parCle = {for (final s in sections) s.cle: s};

    // Les blocs de l'accueil sont toujours présents, dans un ordre fixe
    // (comme sur Yobante Boutique) : un bloc sans contenu affiche un état
    // vide explicite au lieu de disparaître.
    final blocs = <Widget>[];
    for (final b in _blocsAccueil) {
      if (b.connecteSeulement && widget.isGuest) continue;
      final s = parCle.remove(b.cle);
      blocs.add(s != null ? _section(s) : _blocVide(b));
    }
    // Section ajoutée côté serveur et inconnue de l'application : affichée à la suite.
    for (final s in parCle.values) {
      blocs.add(_section(s));
    }

    return [
      if (_categories.isNotEmpty) SliverToBoxAdapter(child: _rangeeCategories()),
      SliverToBoxAdapter(child: _bandeauPromotions(sections)),
      for (final b in blocs) SliverToBoxAdapter(child: b),
    ];
  }

  /// Page « Voir tout » d'une section. Promotions et nouveautés ouvrent le
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

  /// Bloc vide : titre de la section puis carte d'état vide.
  Widget _blocVide(_BlocAccueil b) {
    final proches = b.cle == 'proches' && !(_accueil?.positionConnue ?? false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: EnteteSection(b.titre, action: 'Voir tout →', onAction: () => _voirTout(b.cle, b.titre)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            decoration: BoxDecoration(color: AppColor.kBackground, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: AppColor.kPrimaryLight, shape: BoxShape.circle),
                  child: Icon(b.icone, color: AppColor.kPrimary, size: 26),
                ),
                const SizedBox(height: 14),
                Text(
                  'Bientôt disponible',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100),
                ),
                const SizedBox(height: 6),
                Text(
                  proches
                      ? 'Activez la localisation depuis votre profil pour voir les boutiques de votre quartier.'
                      : b.vide,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kGrayscale40, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const List<_BlocAccueil> _blocsAccueil = [
    _BlocAccueil('promotions', 'Promotions du moment', Icons.local_offer_outlined,
        'Les bonnes affaires des boutiques apparaîtront ici.'),
    _BlocAccueil('nouveautes', 'Nouveautés', Icons.new_releases_outlined,
        'Les derniers produits publiés apparaîtront ici.'),
    _BlocAccueil('abonnements', 'Chez les boutiques que vous suivez', Icons.favorite_border_rounded,
        'Suivez des boutiques pour retrouver ici leurs nouveautés.',
        connecteSeulement: true),
    _BlocAccueil('pourVous', 'Sélectionné pour vous', Icons.auto_awesome_outlined,
        'Des boutiques choisies selon vos centres d’intérêt.'),
    _BlocAccueil('proches', 'Près de chez vous', Icons.place_outlined,
        'Aucune boutique encore dans votre secteur.'),
    _BlocAccueil('meilleures', 'Boutiques populaires', Icons.star_border_rounded,
        'Les boutiques les mieux notées apparaîtront ici.'),
    _BlocAccueil('nouvelles', 'Nouvelles boutiques', Icons.storefront_outlined,
        'Les vendeurs installent leurs vitrines.'),
    _BlocAccueil('aDecouvrir', 'À découvrir', Icons.explore_outlined,
        'De nouvelles boutiques à découvrir très bientôt.'),
  ];

  /// Catégories en pastilles (comme les rayons de Yobante Boutique) : carré
  /// bleu clair, icône, libellé dessous. Cinq remplissent la largeur de
  /// l'écran, les suivantes défilent.
  Widget _rangeeCategories() {
    final largeur = ((MediaQuery.sizeOf(context).width - 32 - 4 * 10) / 5).clamp(58.0, 84.0);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: largeur + 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final c = _categories[i];
            return GestureDetector(
              onTap: () => _ouvrirCategorie(c),
              child: SizedBox(
                width: largeur,
                child: Column(
                  children: [
                    Container(
                      width: largeur - 8,
                      height: largeur - 8,
                      decoration: BoxDecoration(
                        color: AppColor.kPrimaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(iconeCategorie(c.icone), color: AppColor.kPrimary, size: 26),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColor.kGrayscaleDark100),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Bandeau d'appel vers les promotions, seulement s'il y en a.
  Widget _bandeauPromotions(List<AccueilSection> sections) {
    final promos = sections.where((s) => s.cle == 'promotions').expand((s) => s.elements).length;
    if (promos == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ProduitsPage(titre: 'Promotions', promotions: true),
        )),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(color: AppColor.kPrimary, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Offres limitées',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColor.kSecondary, letterSpacing: .4)),
                    const SizedBox(height: 3),
                    Text('$promos produit${promos > 1 ? 's' : ''} en promotion',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Profitez-en avant la fin du compte à rebours',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColor.kSecondary, borderRadius: BorderRadius.circular(999)),
                child: Text('Voir',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColor.kPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(AccueilSection s) {
    final produits = s.type == 'produits';
    // « Voir tout » sur chaque section, comme sur Yobante Boutique.
    final VoidCallback voirTout = () => _voirTout(s.cle, s.titre);

    final largeurCarte = (MediaQuery.sizeOf(context).width - 16 * 2 - 12) / 2.3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              if (s.cle == 'promotions') ...[
                const Icon(Icons.local_fire_department_rounded, color: kPromoEncre, size: 20),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: EnteteSection(s.titre,
                    sousTitre: s.sousTitre, action: 'Voir tout →', onAction: voirTout),
              ),
            ],
          ),
        ),
        if (produits)
          SizedBox(
            height: largeurCarte / ratioCarteProduit,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: s.elements.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: largeurCarte,
                child: ProduitCard(produit: ProduitCatalogue.fromJson(s.elements[i])),
              ),
            ),
          )
        else
          SizedBox(
            height: 186,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: s.elements.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _CarteBoutique(donnees: s.elements[i]),
            ),
          ),
      ],
    );
  }
}

/// Carte d'une boutique : visuel, nom, catégorie · ville, note et distance.
class _CarteBoutique extends StatelessWidget {
  final Map<String, dynamic> donnees;
  const _CarteBoutique({required this.donnees});

  @override
  Widget build(BuildContext context) {
    final logo = donnees['logo']?.toString();
    final verifiee = donnees['verifiee'] == true;
    final distance = donnees['distanceKm'];
    final note = donnees['note'];
    final id = donnees['id']?.toString();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: id == null
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BoutiquePubliquePage(boutiqueId: id, apercu: BoutiqueResume.fromJson(donnees)),
              )),
      child: Container(
        width: 156,
        clipBehavior: Clip.antiAlias,
        decoration: decorationCarte(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: logo != null && logo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageOptimisee(logo, largeur: 320),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const _VisuelParDefaut(),
                        )
                      : const _VisuelParDefaut(),
                ),
                if (verifiee)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.verified_rounded, size: 14, color: AppColor.kSucces),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donnees['nom']?.toString() ?? 'Boutique',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [donnees['categorie']?.toString(), donnees['localisation']?.toString()]
                        .where((e) => e != null && e.isNotEmpty)
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: texteDiscret(11),
                  ),
                  if (distance != null || note != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (note != null) ...[
                          const Icon(Icons.star_rounded, size: 14, color: AppColor.kSecondary),
                          const SizedBox(width: 3),
                          Text('$note',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100)),
                          const SizedBox(width: 8),
                        ],
                        if (distance != null) ...[
                          const Icon(Icons.place_outlined, size: 13, color: AppColor.kGrayscale40),
                          const SizedBox(width: 2),
                          Text('$distance km', style: texteDiscret(11)),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
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
  Widget build(BuildContext context) => Container(
        color: AppColor.kSurface,
        child: const Icon(Icons.storefront_outlined, color: AppColor.kGrayscale40),
      );
}

/// Bloc attendu sur l'accueil : clé de la section côté serveur, titre par
/// défaut, icône et message quand elle est vide.
class _BlocAccueil {
  final String cle;
  final String titre;
  final IconData icone;
  final String vide;
  final bool connecteSeulement;
  const _BlocAccueil(this.cle, this.titre, this.icone, this.vide, {this.connecteSeulement = false});
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
      return const Center(child: CircularProgressIndicator(color: AppColor.kPrimary, strokeWidth: 2.5));
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
        icon: _section?.type == 'produits' ? Icons.inventory_2_outlined : Icons.storefront_outlined,
        title: 'Rien pour le moment',
        subtitle: 'Cette section se remplira dès que les boutiques publieront.',
      );
    }
    final produits = _section!.type == 'produits';
    final largeur = MediaQuery.sizeOf(context).width;
    return RefreshIndicator(
      color: AppColor.kPrimary,
      onRefresh: _charger,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: produits
            ? grilleProduits(context)
            : SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: largeur >= 600 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 190,
              ),
        itemCount: elements.length,
        itemBuilder: (_, i) => produits
            ? ProduitCard(produit: ProduitCatalogue.fromJson(elements[i]))
            : _CarteBoutique(donnees: elements[i]),
      ),
    );
  }
}
