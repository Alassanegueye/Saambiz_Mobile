import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/features/messagerie/presentation/pages/chat_page.dart';
import 'package:dio/dio.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saambiz/core/widgets/logo_boutique.dart';
import 'package:saambiz/core/theme/police.dart';

import '../../../../core/services/identifiant_visiteur.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typo.dart';
import '../../../../core/utils/url_externe.dart';
import '../../../../core/widgets/page_vendeur.dart';
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

/// Une section de la boutique (« Nos promos du moment »…) et ses produits.
class _Section {
  final String titre;
  final List<ProduitCatalogue> produits;
  const _Section(this.titre, this.produits);
}

/// Page d'une boutique vue par un acheteur : couverture, logo centré, nom,
/// slogan, propriétaire, chiffres clés (note, produits, ancienneté),
/// « Suivre » et les façons de la joindre. Deux onglets ensuite :
/// « Produits » (les sections choisies par le vendeur, puis tous ses
/// produits en grille) et « À propos » (présentation, propriétaire,
/// informations pratiques, engagements, réseaux). Ouverte aux invités ;
/// seuls « Suivre » et « Message » demandent un compte.
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

  /// Onglet affiché : 0 = Produits, 1 = À propos.
  int _onglet = 0;

  /// La couverture a défilé : le nom de la boutique passe dans la barre.
  bool _replie = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final replie = _scroll.offset > _hauteurCouverture - 40;
      if (replie != _replie) setState(() => _replie = replie);
      if (_onglet == 0 &&
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
  /// Adresse publique du site de la boutique, vide s'il n'est pas en ligne.
  String get _siteUrl => (_boutique?['siteUrl'] ?? '').toString().trim();

  /// Ouvre le site dans le navigateur. En cas d'échec on le dit, plutôt que
  /// de laisser l'appui sans effet.
  Future<void> _ouvrirSite(String url) async {
    final uri = Uri.tryParse(url);
    final ouvert =
        uri != null &&
        uri.hasScheme &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ouvert && mounted) {
      afficherErreur(context, 'Le site n’a pas pu s’ouvrir.');
    }
  }

  Future<void> _chargerBoutique() async {
    try {
      // Ouvrir la boutique est une visite : le serveur la compte une fois
      // par jour, ni pour son vendeur ni pour un robot.
      final b = await _ds.boutique(
        widget.boutiqueId,
        visiteur: IdentifiantVisiteur.lire(sl<SharedPreferences>()),
      );
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

  static const double _hauteurCouverture = 190;

  String get _nom =>
      (_boutique?['nom'] ?? widget.apercu?.nom ?? 'Boutique').toString();

  Color get _accent {
    final hex = (_boutique?['accent'] ?? '').toString().replaceAll('#', '');
    final v = int.tryParse(hex, radix: 16);
    return (hex.length == 6 && v != null)
        ? Color(0xFF000000 | v)
        : AppColor.kPrimary;
  }

  /// Prénom et nom du vendeur, vide si le serveur ne les donne pas.
  String get _proprietaire {
    final v = _boutique?['vendeur'];
    if (v is! Map) return '';
    return [v['prenom'], v['nom']]
        .where((x) => x != null && x.toString().trim().isNotEmpty)
        .map((x) => x.toString().trim())
        .join(' ');
  }

  bool get _verifiee =>
      _boutique?['verifiee'] == true || (widget.apercu?.verifiee ?? false);

  String get _adresse =>
      (_boutique?['localisation'] ?? widget.apercu?.localisation ?? '')
          .toString();

  String get _telephone =>
      (_boutique?['telephone'] ??
              _boutique?['whatsapp'] ??
              widget.apercu?.telephone ??
              '')
          .toString();

  String get _whatsappNumero =>
      (_boutique?['whatsapp'] ??
              _boutique?['telephone'] ??
              widget.apercu?.telephone ??
              '')
          .toString();

  int get _nombreProduits {
    final n = _boutique?['nombreProduits'];
    return n is num ? n.toInt() : _produits.length;
  }

  // Écran
  @override
  Widget build(BuildContext context) {
    final haut = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColor.kBackground,
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
                  // Couverture, puis la carte blanche de l'identité dont le
                  // logo chevauche le bord. La barre flotte par-dessus.
                  SliverToBoxAdapter(child: _haut(haut)),
                  SliverToBoxAdapter(child: _entete()),
                  SliverToBoxAdapter(child: _onglets()),
                  if (_onglet == 0)
                    ..._contenuProduits()
                  else
                    SliverToBoxAdapter(child: _contenuApropos()),
                  SliverToBoxAdapter(
                    child: _suite && _onglet == 0
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColor.kPrimary,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 32 + MediaQuery.paddingOf(context).bottom,
                          ),
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

  /// Couverture, carte blanche aux coins arrondis qui la recouvre en bas, et
  /// le logo centré à cheval sur le bord de la carte.
  Widget _haut(double haut) {
    final logo = (_boutique?['logo'] ?? widget.apercu?.logo ?? '').toString();
    const tailleLogo = 104.0;
    const recouvrement = 26.0;
    final bordCarte = _hauteurCouverture + haut - recouvrement;
    return SizedBox(
      height: bordCarte + tailleLogo / 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _hauteurCouverture + haut,
            child: _couverture(),
          ),
          Positioned(
            top: bordCarte,
            left: 0,
            right: 0,
            bottom: 0,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColor.kWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
          ),
          Positioned(
            top: bordCarte - tailleLogo / 2,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: tailleLogo,
                height: tailleLogo,
                decoration: BoxDecoration(
                  color: AppColor.kWhite,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColor.kWhite, width: 4),
                  boxShadow: AppDim.ombreFlottante,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
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
          ),
        ],
      ),
    );
  }

  /// Bannière de la boutique, sinon sa couleur en aplat, pour que la
  /// couverture ne soit jamais vide. Volontairement sans ornement : les
  /// dégradés à plusieurs teintes et les filigranes se lisaient comme des
  /// taches.
  Widget _couverture() {
    final banniere = (_boutique?['banniere'] ?? '').toString();
    final fond = DecoratedBox(decoration: BoxDecoration(color: _accent));
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

  // Identité de la boutique : nom, slogan, propriétaire, chiffres clés,
  // « Suivre » et les façons de la joindre.
  Widget _entete() {
    final b = _boutique;
    final nom = _nom;
    final adresse = _adresse;
    final sousTitre = (b?['slogan'] ?? '').toString().trim();
    final categorie = (b?['categorie'] ?? '').toString().trim();
    final telephone = _telephone;
    final whatsapp = _whatsappNumero;
    final proprietaire = _proprietaire;

    final contacts = <Widget>[
      if (telephone.isNotEmpty)
        _ActionContact(
          icone: Icons.phone_rounded,
          libelle: 'Appeler',
          onTap: () => _appeler(telephone),
        ),
      if (whatsapp.isNotEmpty)
        _ActionContact(
          icone: Icons.chat_rounded,
          libelle: 'WhatsApp',
          couleur: AppColor.kWhatsapp,
          onTap: () => _whatsapp(whatsapp),
        ),
      if (_vendeurId.isNotEmpty)
        _ActionContact(
          icone: Icons.mail_outline_rounded,
          libelle: 'Message',
          onTap: () => _ecrire(nom),
        ),
      if (adresse.isNotEmpty)
        _ActionContact(
          icone: Icons.near_me_outlined,
          libelle: 'Itinéraire',
          onTap: () => _carte(adresse),
        ),
      // Le site de la boutique, quand il est EN LIGNE. Le serveur ne renvoie
      // `siteUrl` que dans ce cas : le `slug` existe dès la création de la
      // boutique, bien avant la mise en ligne, et le fabriquer ici enverrait
      // l'acheteur sur une adresse morte.
      //
      // L'adresse est celle qu'on partage : pas de marqueur `apercu`, un
      // acheteur qui ouvre le site doit compter comme une visite.
      if (_siteUrl.isNotEmpty)
        _ActionContact(
          icone: Icons.language_rounded,
          libelle: 'Son site',
          onTap: () => _ouvrirSite(_siteUrl),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: AppDim.ombreCarte,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Column(
        children: [
          // Nom et badge vérifié, centrés sous le logo.
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: nom),
                if (_verifiee)
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.verified_rounded,
                        size: 22,
                        color: _bleuVerifie,
                        semanticLabel: 'Boutique vérifiée',
                      ),
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypo.titreL.copyWith(color: _encre),
          ),
          if (sousTitre.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sousTitre,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypo.corps.copyWith(color: AppColor.kGrayscale40),
            ),
          ],
          if (proprietaire.isNotEmpty || categorie.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (proprietaire.isNotEmpty)
                  _Puce(
                    icone: Icons.person_outline_rounded,
                    texte: 'Par $proprietaire',
                  ),
                if (categorie.isNotEmpty)
                  _Puce(
                    icone: Icons.sell_outlined,
                    texte: categorie,
                    fond: AppColor.kSecondaryLight,
                    couleur: AppColor.kSecondaryDark,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          _chiffres(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BoutonSuivre(suivi: _suivi, onTap: _basculerSuivi),
              ),
              // La cloche n'apparaît qu'une fois la boutique suivie.
              if (_suivi) ...[
                const SizedBox(width: 10),
                _BoutonCloche(active: _cloche, onTap: _basculerCloche),
              ],
            ],
          ),
          if (contacts.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final c in contacts) Expanded(child: c)],
            ),
          ],
        ],
      ),
    );
  }

  /// Note, nombre de produits, ancienneté : trois chiffres côte à côte.
  Widget _chiffres() {
    final b = _boutique;
    final note = b?['note'];
    final nombreAvis = b?['nombreAvis'] is num
        ? (b!['nombreAvis'] as num).toInt()
        : 0;
    final depuis = b?['depuis'];
    final aDesAvis = note is num && nombreAvis > 0;
    final produits = _nombreProduits;

    Widget separateur() =>
        Container(width: 1, height: 34, color: AppColor.kGrayscale20);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.kSurface,
        borderRadius: AppDim.brGrand,
      ),
      child: Row(
        children: [
          // Toujours présent, même sans avis : c'est le chemin vers la
          // feuille des avis.
          Expanded(
            child: _Chiffre(
              valeur: aDesAvis
                  ? note.toStringAsFixed(1).replaceAll('.', ',')
                  : 'Noter',
              icone: Icons.star_rounded,
              libelle: aDesAvis ? '$nombreAvis avis' : 'Donner votre avis',
              onTap: () => ouvrirAvisBoutique(
                context,
                boutiqueId: widget.boutiqueId,
                nomBoutique: _nom,
              ),
            ),
          ),
          separateur(),
          Expanded(
            child: _Chiffre(
              valeur: '$produits',
              libelle: produits > 1 ? 'Produits' : 'Produit',
              onTap: () => setState(() => _onglet = 0),
            ),
          ),
          if (depuis != null) ...[
            separateur(),
            Expanded(
              child: _Chiffre(valeur: '$depuis', libelle: 'Sur SaamBiz'),
            ),
          ],
        ],
      ),
    );
  }

  /// Bascule « Produits » / « À propos ».
  Widget _onglets() {
    Widget onglet(int i, String libelle) {
      final actif = _onglet == i;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _onglet = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: actif ? AppColor.kPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDim.rayonPastille),
            ),
            child: Text(
              libelle,
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: actif ? AppColor.kWhite : AppColor.kGrayscale40,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColor.kWhite,
          borderRadius: BorderRadius.circular(AppDim.rayonPastille),
          boxShadow: AppDim.ombreCarte,
        ),
        child: Row(children: [onglet(0, 'Produits'), onglet(1, 'À propos')]),
      ),
    );
  }

  // Titre de section : gros titre à gauche, « Voir tout → » à droite.
  Widget _titreSection(String titre, {int? total, VoidCallback? voirTout}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColor.kSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              titre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypo.titreM.copyWith(color: _encre),
            ),
          ),
          if (total != null && total > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColor.kPrimaryLight,
                borderRadius: BorderRadius.circular(AppDim.rayonPastille),
              ),
              child: Text(
                '$total',
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kPrimary,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (voirTout != null)
            TextButton(
              onPressed: voirTout,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Voir tout',
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColor.kPrimaryMedium,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColor.kPrimaryMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Onglet Produits : les sections du vendeur, puis tous les produits.
  List<Widget> _contenuProduits() {
    final sections = _sections;
    return [
      for (final s in sections) SliverToBoxAdapter(child: _ligneSection(s)),
      SliverToBoxAdapter(
        child: _titreSection(
          sections.isEmpty ? 'Nos produits' : 'Tous les produits',
          total: _chargement ? null : _nombreProduits,
        ),
      ),
      ..._grille(),
    ];
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

  // Tous les produits de la boutique, en grille.
  List<Widget> _grille() {
    if (_chargement) {
      // Squelette : la grille garde sa forme pendant le chargement.
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: grilleProduits(context),
            delegate: SliverChildBuilderDelegate(
              (_, __) => const _CarteFantome(),
              childCount: 4,
            ),
          ),
        ),
      ];
    }
    if (_erreur != null) {
      return [
        SliverToBoxAdapter(
          child: _Carte(
            child: EtatVide(
              icone: Icons.wifi_off_rounded,
              titre: 'Oups',
              message: _erreur,
              action: 'Réessayer',
              onAction: _charger,
              compact: true,
            ),
          ),
        ),
      ];
    }
    if (_produits.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: _Carte(
            child: EtatVide(
              icone: Icons.inventory_2_outlined,
              titre: 'Aucun produit pour le moment',
              message:
                  'Cette boutique ajoute bientôt ses produits. '
                  'Suivez-la pour être prévenu de ses nouveautés.',
              compact: true,
            ),
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

  // Onglet À propos : présentation, propriétaire, informations pratiques,
  // avantages et réseaux.
  Widget _contenuApropos() {
    final b = _boutique;
    final texte = (b?['apropos'] ?? b?['description'] ?? '').toString().trim();
    final categorie = (b?['categorie'] ?? '').toString().trim();
    final horaires = (b?['horaires'] ?? '').toString().trim();
    final depuis = b?['depuis'];
    final adresse = _adresse;
    final telephone = _telephone;
    final whatsapp = (b?['whatsapp'] ?? '').toString().trim();

    final infos = <Widget>[
      if (categorie.isNotEmpty)
        _LigneInfo(
          icone: Icons.sell_outlined,
          titre: 'Catégorie',
          valeur: categorie,
        ),
      if (adresse.isNotEmpty)
        _LigneInfo(
          icone: Icons.location_on_outlined,
          titre: 'Adresse',
          valeur: adresse,
          onTap: () => _carte(adresse),
        ),
      if (horaires.isNotEmpty)
        _LigneInfo(
          icone: Icons.schedule_rounded,
          titre: 'Horaires',
          valeur: horaires,
        ),
      if (telephone.isNotEmpty)
        _LigneInfo(
          icone: Icons.phone_outlined,
          titre: 'Téléphone',
          valeur: telephone,
          onTap: () => _appeler(telephone),
        ),
      if (whatsapp.isNotEmpty && whatsapp != telephone)
        _LigneInfo(
          icone: Icons.chat_outlined,
          titre: 'WhatsApp',
          valeur: whatsapp,
          onTap: () => _whatsapp(whatsapp),
        ),
      if (depuis != null)
        _LigneInfo(
          icone: Icons.storefront_outlined,
          titre: 'Sur SaamBiz depuis',
          valeur: '$depuis',
        ),
    ];

    final avantages = (b?['avantages'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final reseaux = b?['reseaux'] is Map
        ? Map<String, dynamic>.from(b!['reseaux'] as Map)
        : const <String, dynamic>{};
    final liens = <(IconData, String, String)>[
      for (final r in const [
        (Icons.camera_alt_outlined, 'Instagram', 'instagram'),
        (Icons.facebook_rounded, 'Facebook', 'facebook'),
        (Icons.music_note_rounded, 'TikTok', 'tiktok'),
        (Icons.chat_bubble_outline_rounded, 'Snapchat', 'snapchat'),
        (Icons.language_rounded, 'Site web', 'site'),
      ])
        if ((reseaux[r.$3] ?? '').toString().trim().isNotEmpty)
          (r.$1, r.$2, reseaux[r.$3].toString().trim()),
    ];

    if (!_boutiqueChargee && b == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColor.kPrimary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (texte.isNotEmpty)
          _Carte(
            titre: 'Présentation',
            child: Text(
              texte,
              style: AppTypo.corps.copyWith(color: AppColor.kGrayscale60),
            ),
          ),
        _Carte(titre: 'Le propriétaire', child: _proprietaireCarte()),
        if (infos.isNotEmpty)
          _Carte(
            titre: 'Informations',
            child: Column(
              children: [
                for (var i = 0; i < infos.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColor.kLine),
                  infos[i],
                ],
              ],
            ),
          ),
        if (avantages.isNotEmpty)
          _Carte(
            titre: 'Nos engagements',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final a in avantages)
                  _Avantage(
                    icone:
                        iconesAvantages[a['icone']]?.$1 ??
                        Icons.star_border_rounded,
                    titre: (a['titre'] ?? '').toString(),
                    texte: (a['texte'] ?? '').toString(),
                  ),
              ],
            ),
          ),
        if (liens.isNotEmpty)
          _Carte(
            titre: 'Retrouvez-nous',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final l in liens)
                  _Puce(
                    icone: l.$1,
                    texte: l.$2,
                    onTap: () => UrlExterne.lancer(l.$3),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// Avatar aux initiales, nom, statut du vendeur et « Écrire ».
  Widget _proprietaireCarte() {
    final nom = _proprietaire;
    final affiche = nom.isNotEmpty ? nom : 'Vendeur $_nom';
    final initiales = (nom.isNotEmpty ? nom : _nom)
        .split(RegExp(r'\s+'))
        .where((m) => m.isNotEmpty)
        .take(2)
        .map((m) => m.characters.first.toUpperCase())
        .join();
    final depuis = _boutique?['depuis'];
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColor.kPrimary,
            shape: BoxShape.circle,
          ),
          child: Text(
            initiales,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColor.kSecondary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                affiche,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypo.titreS.copyWith(color: _encre),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    _verifiee
                        ? Icons.verified_rounded
                        : Icons.storefront_outlined,
                    size: 15,
                    color: _verifiee ? _bleuVerifie : AppColor.kGrayscale40,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      [
                        _verifiee ? 'Vendeur vérifié' : 'Vendeur',
                        if (depuis != null) 'depuis $depuis',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypo.petit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_vendeurId.isNotEmpty) ...[
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () => _ecrire(_nom),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.kPrimary,
              side: const BorderSide(color: AppColor.kPrimaryBorder),
              shape: RoundedRectangleBorder(borderRadius: AppDim.brMoyen),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 40),
            ),
            icon: const Icon(Icons.mail_outline_rounded, size: 17),
            label: const Text(
              'Écrire',
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Pastille ronde blanche autour d'un bouton de la barre de la boutique.
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

/// « Suivre la boutique » (plein, marine) ou « Boutique suivie » (clair,
/// coche) : l'état se lit d'un coup d'œil.
class _BoutonSuivre extends StatelessWidget {
  final bool suivi;
  final VoidCallback onTap;
  const _BoutonSuivre({required this.suivi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 50,
      decoration: BoxDecoration(
        color: suivi ? AppColor.kPrimaryLight : AppColor.kPrimary,
        borderRadius: AppDim.brGrand,
        border: Border.all(
          color: suivi ? AppColor.kPrimaryBorder : AppColor.kPrimary,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppDim.brGrand,
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                suivi ? Icons.check_rounded : Icons.add_rounded,
                size: 20,
                color: suivi ? AppColor.kPrimary : AppColor.kSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                suivi ? 'Boutique suivie' : 'Suivre la boutique',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: suivi ? AppColor.kPrimary : AppColor.kWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoutonCloche extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _BoutonCloche({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColor.kSecondary : AppColor.kWhite,
      shape: RoundedRectangleBorder(
        borderRadius: AppDim.brGrand,
        side: BorderSide(
          color: active ? AppColor.kSecondary : AppColor.kPrimaryBorder,
        ),
      ),
      child: InkWell(
        borderRadius: AppDim.brGrand,
        onTap: onTap,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            active
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            size: 22,
            color: AppColor.kPrimary,
            semanticLabel: active
                ? 'Désactiver les notifications'
                : 'Activer les notifications',
          ),
        ),
      ),
    );
  }
}

/// Un chiffre clé (note, produits, ancienneté) et son libellé.
class _Chiffre extends StatelessWidget {
  final String valeur;
  final String libelle;
  final IconData? icone;
  final VoidCallback? onTap;
  const _Chiffre({
    required this.valeur,
    required this.libelle,
    this.icone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppDim.brMoyen,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icone != null) ...[
                  Icon(icone, size: 18, color: AppColor.kSecondary),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    valeur,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColor.kPrimary,
                      fontFeatures: AppTypo.chiffres,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              libelle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypo.minuscule,
            ),
          ],
        ),
      ),
    );
  }
}

/// Une information courte en pastille (propriétaire, catégorie, réseau).
class _Puce extends StatelessWidget {
  final IconData icone;
  final String texte;
  final Color fond;
  final Color couleur;
  final VoidCallback? onTap;
  const _Puce({
    required this.icone,
    required this.texte,
    this.fond = AppColor.kPrimaryLight,
    this.couleur = AppColor.kPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fond,
      borderRadius: BorderRadius.circular(AppDim.rayonPastille),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDim.rayonPastille),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 15, color: couleur),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  texte,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kPolice,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: couleur,
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

/// Une façon de joindre la boutique : icône dans un rond, libellé dessous.
class _ActionContact extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final Color couleur;
  final VoidCallback onTap;
  const _ActionContact({
    required this.icone,
    required this.libelle,
    required this.onTap,
    this.couleur = AppColor.kPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppDim.brGrand,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 22, color: couleur),
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
                  fontWeight: FontWeight.w600,
                  color: AppColor.kGrayscale80,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte blanche de l'onglet À propos, avec un titre facultatif.
class _Carte extends StatelessWidget {
  final String? titre;
  final Widget child;
  const _Carte({this.titre, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: _decorationCarte,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titre != null) ...[
            Text(titre!, style: AppTypo.titreS.copyWith(color: _encre)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

final _decorationCarte = BoxDecoration(
  color: AppColor.kWhite,
  borderRadius: AppDim.brCarte,
  boxShadow: AppDim.ombreCarte,
);

/// Une ligne d'information : icône, intitulé, valeur ; touchable si `onTap`.
class _LigneInfo extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String valeur;
  final VoidCallback? onTap;
  const _LigneInfo({
    required this.icone,
    required this.titre,
    required this.valeur,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDim.brMoyen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColor.kPrimaryLight,
                borderRadius: AppDim.brMoyen,
              ),
              child: Icon(icone, size: 19, color: AppColor.kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: AppTypo.minuscule),
                  const SizedBox(height: 1),
                  Text(valeur, style: AppTypo.corpsFort.copyWith(fontSize: 14)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColor.kGrayscale30,
              ),
          ],
        ),
      ),
    );
  }
}

/// Un engagement de la boutique (« Livraison rapide »…).
class _Avantage extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String texte;
  const _Avantage({
    required this.icone,
    required this.titre,
    required this.texte,
  });

  @override
  Widget build(BuildContext context) {
    // Deux par ligne dans la carte (marges 2 × 20, rembourrage 2 × 18).
    final largeur = (MediaQuery.sizeOf(context).width - 40 - 36 - 10) / 2;
    return Container(
      width: largeur,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.kSurface,
        borderRadius: AppDim.brGrand,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColor.kSecondaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 19, color: AppColor.kSecondaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            titre,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _encre,
            ),
          ),
          if (texte.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(texte, style: texteDiscret(12)),
          ],
        ],
      ),
    );
  }
}

/// Carte produit vide le temps du chargement.
class _CarteFantome extends StatelessWidget {
  const _CarteFantome();

  @override
  Widget build(BuildContext context) {
    Widget barre(double largeur) => Container(
      height: 12,
      width: largeur,
      decoration: BoxDecoration(
        color: AppColor.kBackground2,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Container(
      decoration: _decorationCarte,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.kBackground2,
                borderRadius: AppDim.brGrand,
              ),
            ),
          ),
          const SizedBox(height: 12),
          barre(110),
          const SizedBox(height: 8),
          barre(70),
          const SizedBox(height: 6),
        ],
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
    return ScaffoldMarine(
      appBar: AppBar(
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
