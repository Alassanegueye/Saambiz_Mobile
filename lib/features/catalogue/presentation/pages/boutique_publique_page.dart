import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/features/messagerie/presentation/pages/chat_page.dart';
import 'package:dio/dio.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saambiz/core/widgets/logo_boutique.dart';
import 'package:saambiz/core/theme/police.dart';

import '../../../../core/services/token_service.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/url_externe.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../favoris/data/datasources/favoris_remote_datasource.dart';
import '../../../vitrine/presentation/widgets/etapes_contenus_vitrine.dart'
    show iconesAvantages;
import '../../data/catalogue_remote_datasource.dart';
import '../../data/produit_catalogue.dart';
import '../widgets/bouton_panier.dart';
import '../widgets/produit_card.dart';
import '../../../avis/presentation/feuille_avis_boutique.dart';
import '../../../signalements/presentation/ouvrir_signalement.dart';

const _bleuVerifie = Color(0xFF1D9BF0);
const _encre = Color(0xFF1B1F27);
const _fondDoux = Color(0xFFF4F5F8);

/// Une section de la boutique (« Nos promos du moment »…) et ses produits.
class _Section {
  final String titre;
  final List<ProduitCatalogue> produits;
  const _Section(this.titre, this.produits);
}

/// Page d'une boutique dans l'application, la même que son site web :
/// identité (logo, nom, note, ancienneté, adresse), « Suivre », appeler /
/// WhatsApp, réseaux, puis les sections choisies par le vendeur, chacune sur
/// une ligne qui défile avec « Voir tout », ses avantages et sa présentation.
/// Une boutique qui n'a pas encore composé de section montre tous ses
/// produits. Ouverte aux invités ; seul « Suivre » demande un compte.
class BoutiquePubliquePage extends StatefulWidget {
  final String boutiqueId;

  /// Ce qu'on sait déjà de la boutique (carte touchée), affiché tout de suite.
  final BoutiqueResume? apercu;

  const BoutiquePubliquePage({
    super.key,
    required this.boutiqueId,
    this.apercu,
  });

  @override
  State<BoutiquePubliquePage> createState() => _BoutiquePubliquePageState();
}

class _BoutiquePubliquePageState extends State<BoutiquePubliquePage> {
  final _ds = CatalogueRemoteDataSource(sl<Dio>());
  final _scroll = ScrollController();

  Map<String, dynamic>? _boutique;
  bool _boutiqueChargee = false;
  final List<ProduitCatalogue> _produits = [];
  int _page = 1;
  int _pages = 1;
  bool _chargement = true;
  bool _suite = false;
  String? _erreur;
  bool _suivi = false;
  bool _cloche = false;

  /// La couverture a défilé : le nom de la boutique passe dans la barre.
  bool _replie = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final replie = _scroll.offset > _hauteurCouverture - 40;
      if (replie != _replie) setState(() => _replie = replie);
      if (_sections.isEmpty &&
          _scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
        _chargerSuite();
      }
    });
    _chargerBoutique();
    _charger();
    _chargerSuivi();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // Données
  Future<void> _chargerBoutique() async {
    try {
      final b = await _ds.boutique(widget.boutiqueId);
      if (mounted) setState(() => _boutique = b);
    } catch (_) {
      /* l'aperçu reste affiché */
    } finally {
      if (mounted) setState(() => _boutiqueChargee = true);
    }
  }

  List<_Section> get _sections => (_boutique?['sections'] as List? ?? const [])
      .whereType<Map>()
      .map(
        (s) => _Section(
          (s['titre'] ?? '').toString(),
          (s['produits'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (p) => ProduitCatalogue.fromJson(Map<String, dynamic>.from(p)),
              )
              .toList(),
        ),
      )
      .where((s) => s.produits.isNotEmpty)
      .toList();

  Future<void> _chargerSuivi() async {
    if (!await sl<TokenService>().isAuthenticated) return;
    try {
      final s = await sl<FavorisRemoteDataSource>().statutSuivi(
        widget.boutiqueId,
      );
      if (mounted) {
        setState(() {
          _suivi = s['suivi'] == true;
          _cloche = s['clocheActive'] == true;
        });
      }
    } catch (_) {}
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final res = await _ds.produits(
        boutique: widget.boutiqueId,
        tri: 'recents',
      );
      if (!mounted) return;
      setState(() {
        _produits
          ..clear()
          ..addAll(res.produits);
        _page = 1;
        _pages = res.pages;
        _chargement = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _erreur =
              'Impossible de charger les produits. Vérifiez votre connexion.';
          _chargement = false;
        });
      }
    }
  }

  Future<void> _chargerSuite() async {
    if (_suite || _chargement || _page >= _pages) return;
    setState(() => _suite = true);
    try {
      final res = await _ds.produits(
        boutique: widget.boutiqueId,
        tri: 'recents',
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _produits.addAll(res.produits);
        _page += 1;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _suite = false);
    }
  }

  // Actions
  Future<void> _basculerSuivi() async {
    if (!await sl<TokenService>().isAuthenticated) {
      if (!mounted) return;
      afficherInfo(
        context,
        'Créez un compte ou connectez-vous pour suivre cette boutique.',
        titre: 'Connexion requise',
      );
      return;
    }
    final avant = _suivi;
    setState(() {
      _suivi = !avant;
      if (avant) _cloche = false;
    });
    try {
      final ds = sl<FavorisRemoteDataSource>();
      avant
          ? await ds.supprimer(widget.boutiqueId)
          : await ds.ajouter(widget.boutiqueId);
      if (!mounted) return;
      afficherSucces(
        context,
        avant
            ? 'Vous ne suivez plus cette boutique.'
            : 'Vous suivez cette boutique. Activez la cloche pour recevoir ses promotions et nouveautés.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _suivi = avant);
      afficherErreur(context, 'Action impossible pour le moment. Réessayez.');
    }
  }

  /// Cloche : seuls les abonnés qui l'activent reçoivent les notifications
  /// de la boutique (promotions, nouveautés, messages).
  Future<void> _basculerCloche() async {
    final avant = _cloche;
    setState(() => _cloche = !avant);
    try {
      final actif = await sl<FavorisRemoteDataSource>().toggleCloche(
        widget.boutiqueId,
        !avant,
      );
      if (!mounted) return;
      setState(() => _cloche = actif);
      afficherSucces(
        context,
        actif
            ? 'Notifications activées : vous serez prévenu des promotions et nouveautés.'
            : 'Notifications désactivées pour cette boutique.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _cloche = avant);
      afficherErreur(context, 'Action impossible pour le moment. Réessayez.');
    }
  }

  String _numero(String telephone) {
    final tel = telephone.replaceAll(RegExp(r'\D'), '');
    return tel.length == 9 ? '221$tel' : tel;
  }

  Future<void> _whatsapp(String telephone) async {
    final numero = _numero(telephone);
    if (numero.isEmpty) {
      afficherInfo(
        context,
        'Cette boutique n\'a pas indiqué de numéro WhatsApp.',
      );
      return;
    }
    if (!await UrlExterne.lancer('https://wa.me/$numero') && mounted) {
      afficherErreur(
        context,
        'WhatsApp n\'est pas disponible sur cet appareil.',
      );
    }
  }

  /// Compte du vendeur, destinataire des messages.
  String get _vendeurId {
    final b = _boutique;
    final vendeur = b?['vendeur'];
    return (b?['vendeurId'] ?? (vendeur is Map ? vendeur['id'] : null) ?? '')
        .toString();
  }

  Future<void> _ecrire(String nomBoutique) async {
    if (!await sl<TokenService>().isAuthenticated) {
      if (!mounted) return;
      afficherInfo(
        context,
        'Créez un compte ou connectez-vous pour écrire à cette boutique.',
        titre: 'Connexion requise',
      );
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          interlocuteurId: _vendeurId,
          interlocuteurNom: nomBoutique,
        ),
      ),
    );
  }

  Future<void> _appeler(String telephone) async {
    final numero = telephone.replaceAll(RegExp(r'[^\d+]'), '');
    if ((numero.isEmpty || !await UrlExterne.lancer('tel:$numero')) &&
        mounted) {
      afficherErreur(context, 'Appel impossible depuis cet appareil.');
    }
  }

  Future<void> _carte(String adresse) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(adresse)}';
    if (!await UrlExterne.lancer(url) && mounted) {
      afficherErreur(context, 'Impossible d\'ouvrir la carte.');
    }
  }

  static const double _hauteurCouverture = 168;

  String get _nom =>
      (_boutique?['nom'] ?? widget.apercu?.nom ?? 'Boutique').toString();

  Color get _accent {
    final hex = (_boutique?['accent'] ?? '').toString().replaceAll('#', '');
    final v = int.tryParse(hex, radix: 16);
    return (hex.length == 6 && v != null)
        ? Color(0xFF000000 | v)
        : AppColor.kPrimary;
  }

  // Écran
  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    final haut = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColor.kWhite,
        body: Stack(
          children: [
            RefreshIndicator(
              color: AppColor.kPrimary,
              edgeOffset: haut + 60,
              onRefresh: () async =>
                  Future.wait([_chargerBoutique(), _charger()]),
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Couverture (bannière ou dégradé à la couleur de la boutique) :
                  // elle fait partie de la page, pour que le logo puisse déborder
                  // dessus. La barre flotte par-dessus (voir plus bas).
                  SliverToBoxAdapter(child: _haut(haut)),
                  SliverToBoxAdapter(child: _entete()),
                  if (sections.isNotEmpty)
                    ...sections.map(
                      (s) => SliverToBoxAdapter(child: _ligneSection(s)),
                    )
                  else if (_boutiqueChargee) ...[
                    SliverToBoxAdapter(child: _titreSection('Nos produits')),
                    ..._grille(),
                  ],
                  SliverToBoxAdapter(child: _avantages()),
                  SliverToBoxAdapter(child: _apropos()),
                  SliverToBoxAdapter(
                    child: _suite
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColor.kPrimary,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : const SizedBox(height: 32),
                  ),
                ],
              ),
            ),
            // Barre flottante : retour, panier, menu. Transparente sur la
            // couverture ; à la couleur de la boutique, avec son nom, une fois
            // la couverture passée.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                color: _replie ? _accent : Colors.transparent,
                padding: EdgeInsets.fromLTRB(12, haut + 8, 12, 8),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      _PastilleBarre(
                        child: IconButton(
                          tooltip: 'Retour',
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppColor.kPrimary,
                          ),
                        ),
                      ),
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: _replie ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: kPolice,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColor.kWhite,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const _PastilleBarre(child: BoutonPanier()),
                    const SizedBox(width: 8),
                    // Le signalement suit la barre, sinon le formulaire
                    // redevient inatteignable.
                    _PastilleBarre(
                      child: MenuSignaler(
                        type: 'boutique',
                        cibleId: widget.boutiqueId,
                      ),
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

  /// Couverture, puis le logo qui la chevauche, avec « Suivre » et la
  /// cloche à droite. Le tout dans un seul bloc : un débordement vers le bloc
  /// voisin serait rogné.
  Widget _haut(double haut) {
    final logo = (_boutique?['logo'] ?? widget.apercu?.logo ?? '').toString();
    const debord = 48.0;
    return SizedBox(
      height: _hauteurCouverture + haut + debord + 12,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _hauteurCouverture + haut,
            child: _couverture(),
          ),
          Positioned(
            left: 20,
            bottom: 0,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColor.kWhite,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColor.kWhite, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.kPrimary.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: logo.isNotEmpty
                    ? ImageReseau(
                        logo,
                        largeurServeur: 256,
                        fit: BoxFit.cover,
                        repli: const LogoBoutiqueParDefaut(),
                      )
                    : const LogoBoutiqueParDefaut(),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 6,
            child: Row(
              children: [
                _BoutonSuivre(
                  suivi: _suivi,
                  couleur: _accent,
                  onTap: _basculerSuivi,
                ),
                // La cloche n'apparaît qu'une fois la boutique suivie.
                if (_suivi) ...[
                  const SizedBox(width: 8),
                  _BoutonCloche(
                    active: _cloche,
                    couleur: _accent,
                    onTap: _basculerCloche,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bannière de la boutique, sinon un dégradé à sa couleur avec un motif
  /// discret de sacs, pour que la couverture ne soit jamais vide.
  Widget _couverture() {
    final banniere = (_boutique?['banniere'] ?? '').toString();
    final fond = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(_accent, Colors.black, 0.25)!,
            _accent,
            Color.lerp(_accent, Colors.white, 0.18)!,
          ],
        ),
      ),
      child: Align(
        alignment: const Alignment(0.95, 0.4),
        child: Icon(
          Icons.shopping_bag_rounded,
          size: 150,
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (banniere.isNotEmpty)
          ImageReseau(banniere, fit: BoxFit.cover, repli: fond)
        else
          fond,
        // Voile en haut : les pastilles restent lisibles sur une photo.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0x55000000), Color(0x00000000)],
            ),
          ),
        ),
      ],
    );
  }

  // Identité de la boutique.
  Widget _entete() {
    final a = widget.apercu;
    final b = _boutique;
    final nom = _nom;
    final adresse = (b?['localisation'] ?? a?.localisation ?? '').toString();
    final verifiee = b?['verifiee'] == true || (a?.verifiee ?? false);
    final sousTitre = (b?['slogan'] ?? b?['categorie'] ?? '').toString();
    final telephone = (b?['telephone'] ?? b?['whatsapp'] ?? a?.telephone ?? '')
        .toString();
    final whatsapp = (b?['whatsapp'] ?? b?['telephone'] ?? a?.telephone ?? '')
        .toString();
    final note = b?['note'];
    final nombreAvis = b?['nombreAvis'] is num
        ? (b!['nombreAvis'] as num).toInt()
        : 0;
    final depuis = b?['depuis'];
    final reseaux = b?['reseaux'] is Map
        ? Map<String, dynamic>.from(b!['reseaux'] as Map)
        : const <String, dynamic>{};

    final liens = <(IconData, String, String)>[
      if ((reseaux['instagram'] ?? '').toString().isNotEmpty)
        (
          Icons.camera_alt_outlined,
          'Instagram',
          reseaux['instagram'].toString(),
        ),
      if ((reseaux['snapchat'] ?? '').toString().isNotEmpty)
        (
          Icons.chat_bubble_outline_rounded,
          'Snapchat',
          reseaux['snapchat'].toString(),
        ),
      if ((reseaux['facebook'] ?? '').toString().isNotEmpty)
        (Icons.facebook_rounded, 'Facebook', reseaux['facebook'].toString()),
      if ((reseaux['tiktok'] ?? '').toString().isNotEmpty)
        (Icons.music_note_rounded, 'TikTok', reseaux['tiktok'].toString()),
    ];

    final contacts = <Widget>[
      if (telephone.isNotEmpty)
        _ActionContact(
          icone: Icons.phone_rounded,
          libelle: 'Appeler',
          couleur: _accent,
          onTap: () => _appeler(telephone),
        ),
      if (whatsapp.isNotEmpty)
        _ActionContact(
          icone: Icons.chat_rounded,
          libelle: 'WhatsApp',
          couleur: const Color(0xFF1FA855),
          onTap: () => _whatsapp(whatsapp),
        ),
      if (_vendeurId.isNotEmpty)
        _ActionContact(
          icone: Icons.mail_outline_rounded,
          libelle: 'Message',
          couleur: _accent,
          onTap: () => _ecrire(nom),
        ),
      if (adresse.isNotEmpty)
        _ActionContact(
          icone: Icons.map_outlined,
          libelle: 'Itinéraire',
          couleur: _accent,
          onTap: () => _carte(adresse),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _encre,
                    height: 1.15,
                  ),
                ),
              ),
              if (verifiee) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  size: 22,
                  color: _bleuVerifie,
                ),
              ],
            ],
          ),
          if (sousTitre.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sousTitre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 14.5,
                height: 1.35,
                color: AppColor.kGrayscale40,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Toujours affichée, même sans avis : c'est le seul chemin vers
              // la feuille des avis.
              _Info(
                icone: Icons.star_rounded,
                couleurIcone: const Color(0xFFF5B301),
                fond: const Color(0xFFFFF4D1),
                texte: note is num && nombreAvis > 0
                    ? '$note · $nombreAvis avis'
                    : 'Donner votre avis',
                fleche: true,
                onTap: () => ouvrirAvisBoutique(
                  context,
                  boutiqueId: widget.boutiqueId,
                  nomBoutique: nom,
                ),
              ),
              if (depuis != null)
                _Info(
                  icone: Icons.storefront_outlined,
                  texte: 'Depuis $depuis',
                ),
              if (adresse.isNotEmpty)
                _Info(
                  icone: Icons.location_on_outlined,
                  texte: adresse,
                  onTap: () => _carte(adresse),
                ),
            ],
          ),
          if (contacts.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                for (var i = 0; i < contacts.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: contacts[i]),
                ],
              ],
            ),
          ],
          if (liens.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Suivez-nous',
                  style: TextStyle(
                    fontFamily: kPolice,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kGrayscale40,
                  ),
                ),
                const SizedBox(width: 10),
                for (final l in liens)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: _accent.withValues(alpha: 0.08),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => UrlExterne.lancer(l.$3),
                        child: SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(
                            l.$1,
                            size: 18,
                            color: _accent,
                            semanticLabel: l.$2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 32, color: AppColor.kLine),
        ],
      ),
    );
  }

  // Titre de section : gros titre à gauche, « Voir tout → » à droite.
  Widget _titreSection(String titre, {VoidCallback? voirTout}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _encre,
              ),
            ),
          ),
          if (voirTout != null)
            TextButton(
              onPressed: voirTout,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Voir tout',
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: _accent),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Une section : ses produits sur une ligne qui défile.
  Widget _ligneSection(_Section s) {
    const largeur = 168.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titreSection(
          s.titre,
          voirTout: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  _SectionPage(titre: s.titre, produits: s.produits),
            ),
          ),
        ),
        SizedBox(
          height: largeur / ratioCarteProduit,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: s.produits.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: largeur,
              child: ProduitCard(produit: s.produits[i], avecAjout: true),
            ),
          ),
        ),
      ],
    );
  }

  // Boutique sans section : tous ses produits.
  List<Widget> _grille() {
    if (_chargement) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColor.kPrimary,
                strokeWidth: 2.5,
              ),
            ),
          ),
        ),
      ];
    }
    if (_erreur != null) {
      return [
        SliverToBoxAdapter(
          child: EtatVide(
            icone: Icons.wifi_off_rounded,
            titre: 'Oups',
            message: _erreur,
            action: 'Réessayer',
            onAction: _charger,
          ),
        ),
      ];
    }
    if (_produits.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: EtatVide(
            icone: Icons.inventory_2_outlined,
            titre: 'Aucun produit pour le moment',
            message: 'Cette boutique ajoute bientôt ses produits.',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          gridDelegate: grilleProduits(context),
          delegate: SliverChildBuilderDelegate(
            (_, i) => ProduitCard(produit: _produits[i], avecAjout: true),
            childCount: _produits.length,
          ),
        ),
      ),
    ];
  }

  // Les avantages de la boutique (« Livraison rapide »…).
  Widget _avantages() {
    final liste = (_boutique?['avantages'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    if (liste.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _fondDoux,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: 14,
        children: [
          for (final a in liste)
            SizedBox(
              width: 150,
              child: Column(
                children: [
                  Icon(
                    iconesAvantages[a['icone']]?.$1 ??
                        Icons.star_border_rounded,
                    size: 26,
                    color: _accent,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (a['titre'] ?? '').toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _encre,
                    ),
                  ),
                  if ((a['texte'] ?? '').toString().isNotEmpty)
                    Text(
                      a['texte'].toString(),
                      textAlign: TextAlign.center,
                      style: texteDiscret(12),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _apropos() {
    final texte = (_boutique?['apropos'] ?? '').toString().trim();
    if (texte.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À propos',
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _encre,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            texte,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 14,
              height: 1.55,
              color: AppColor.kGrayscale40,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille ronde gris clair autour d'un bouton de la barre de la boutique.
class _PastilleBarre extends StatelessWidget {
  final Widget child;
  const _PastilleBarre({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColor.kWhite.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// « Suivre » (plein) ou « Suivie » (contour, coche) : l'état se lit d'un coup
/// d'œil, sans dépendre d'un cœur rouge.
class _BoutonSuivre extends StatelessWidget {
  final bool suivi;
  final Color couleur;
  final VoidCallback onTap;
  const _BoutonSuivre({
    required this.suivi,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 42,
      decoration: BoxDecoration(
        color: suivi ? AppColor.kWhite : couleur,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: couleur, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  suivi ? Icons.check_rounded : Icons.add_rounded,
                  size: 19,
                  color: suivi ? couleur : AppColor.kWhite,
                ),
                const SizedBox(width: 6),
                Text(
                  suivi ? 'Suivie' : 'Suivre',
                  style: TextStyle(
                    fontFamily: kPolice,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: suivi ? couleur : AppColor.kWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoutonCloche extends StatelessWidget {
  final bool active;
  final Color couleur;
  final VoidCallback onTap;
  const _BoutonCloche({
    required this.active,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? couleur : AppColor.kWhite,
      shape: CircleBorder(side: BorderSide(color: couleur, width: 1.5)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            active
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            size: 20,
            color: active ? AppColor.kWhite : couleur,
            semanticLabel: active
                ? 'Désactiver les notifications'
                : 'Activer les notifications',
          ),
        ),
      ),
    );
  }
}

/// Une information courte en pastille (note, ancienneté, ville).
class _Info extends StatelessWidget {
  final IconData icone;
  final String texte;
  final Color couleurIcone;
  final Color fond;
  final bool fleche;
  final VoidCallback? onTap;
  const _Info({
    required this.icone,
    required this.texte,
    this.couleurIcone = _encre,
    this.fond = _fondDoux,
    this.fleche = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fond,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 16, color: couleurIcone),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  texte,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _encre,
                  ),
                ),
              ),
              if (fleche) ...[
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF8A93A6),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Une façon de joindre la boutique : icône dans un rond, libellé dessous.
class _ActionContact extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final Color couleur;
  final VoidCallback onTap;
  const _ActionContact({
    required this.icone,
    required this.libelle,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _fondDoux,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, size: 19, color: couleur),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  libelle,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _encre,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « Voir tout » d'une section : tous ses produits en grille.
class _SectionPage extends StatelessWidget {
  final String titre;
  final List<ProduitCatalogue> produits;
  const _SectionPage({required this.titre, required this.produits});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kWhite,
      appBar: AppBar(
        backgroundColor: AppColor.kWhite,
        scrolledUnderElevation: 0,
        title: Text(
          titre,
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [BoutonPanier(), SizedBox(width: 6)],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: grilleProduits(context),
        itemCount: produits.length,
        itemBuilder: (_, i) =>
            ProduitCard(produit: produits[i], avecAjout: true),
      ),
    );
  }
}
