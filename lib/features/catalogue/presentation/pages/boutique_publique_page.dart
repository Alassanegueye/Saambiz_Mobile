import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/utils/image_url.dart';

import '../../../../core/services/token_service.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/url_externe.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../favoris/data/datasources/favoris_remote_datasource.dart';
import '../../../vitrine/presentation/widgets/etapes_contenus_vitrine.dart' show iconesAvantages;
import '../../data/catalogue_remote_datasource.dart';
import '../../data/produit_catalogue.dart';
import '../widgets/bouton_panier.dart';
import '../widgets/produit_card.dart';

const _bleuVerifie = Color(0xFF1D9BF0);
const _encre = Color(0xFF1B1F27);
const _fondDoux = Color(0xFFF5F7FB);

/// Une section de la boutique (« Nos promos du moment »…) et ses produits.
class _Section {
  final String titre;
  final List<ProduitCatalogue> produits;
  const _Section(this.titre, this.produits);
}

/// Page d'une boutique dans l'application — la même que son site web :
/// identité (logo, nom, note, ancienneté, adresse), « Suivre », appeler /
/// WhatsApp, réseaux, puis les sections choisies par le vendeur, chacune sur
/// une ligne qui défile avec « Voir tout », ses avantages et sa présentation.
/// Une boutique qui n'a pas encore composé de section montre tous ses
/// produits. Ouverte aux invités ; seul « Suivre » demande un compte.
class BoutiquePubliquePage extends StatefulWidget {
  final String boutiqueId;

  /// Ce qu'on sait déjà de la boutique (carte touchée), affiché tout de suite.
  final BoutiqueResume? apercu;

  const BoutiquePubliquePage({super.key, required this.boutiqueId, this.apercu});

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

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_sections.isEmpty && _scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _chargerSuite();
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

  // ── Données ──────────────────────────────────────────────────────────

  Future<void> _chargerBoutique() async {
    try {
      final b = await _ds.boutique(widget.boutiqueId);
      if (mounted) setState(() => _boutique = b);
    } catch (_) {/* l'aperçu reste affiché */} finally {
      if (mounted) setState(() => _boutiqueChargee = true);
    }
  }

  List<_Section> get _sections => (_boutique?['sections'] as List? ?? const [])
      .whereType<Map>()
      .map((s) => _Section(
            (s['titre'] ?? '').toString(),
            (s['produits'] as List? ?? const [])
                .whereType<Map>()
                .map((p) => ProduitCatalogue.fromJson(Map<String, dynamic>.from(p)))
                .toList(),
          ))
      .where((s) => s.produits.isNotEmpty)
      .toList();

  Future<void> _chargerSuivi() async {
    if (!await sl<TokenService>().isAuthenticated) return;
    try {
      final s = await sl<FavorisRemoteDataSource>().statutSuivi(widget.boutiqueId);
      if (mounted) setState(() => _suivi = s['suivi'] == true);
    } catch (_) {}
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final res = await _ds.produits(boutique: widget.boutiqueId, tri: 'recents');
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
          _erreur = 'Impossible de charger les produits. Vérifiez votre connexion.';
          _chargement = false;
        });
      }
    }
  }

  Future<void> _chargerSuite() async {
    if (_suite || _chargement || _page >= _pages) return;
    setState(() => _suite = true);
    try {
      final res = await _ds.produits(boutique: widget.boutiqueId, tri: 'recents', page: _page + 1);
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

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> _basculerSuivi() async {
    if (!await sl<TokenService>().isAuthenticated) {
      _message('Créez un compte ou connectez-vous pour suivre cette boutique.');
      return;
    }
    final avant = _suivi;
    setState(() => _suivi = !avant);
    try {
      final ds = sl<FavorisRemoteDataSource>();
      avant ? await ds.supprimer(widget.boutiqueId) : await ds.ajouter(widget.boutiqueId);
      _message(avant ? 'Vous ne suivez plus cette boutique.' : 'Vous suivez cette boutique : ses nouveautés arriveront sur votre accueil.');
    } catch (_) {
      if (mounted) setState(() => _suivi = avant);
      _message('Action impossible pour le moment.');
    }
  }

  String _numero(String telephone) {
    final tel = telephone.replaceAll(RegExp(r'\D'), '');
    return tel.length == 9 ? '221$tel' : tel;
  }

  Future<void> _whatsapp(String telephone) async {
    final numero = _numero(telephone);
    if (numero.isEmpty) {
      _message('Cette boutique n\'a pas indiqué de numéro WhatsApp.');
      return;
    }
    if (!await UrlExterne.lancer('https://wa.me/$numero')) {
      _message('WhatsApp n\'est pas disponible sur cet appareil.');
    }
  }

  Future<void> _appeler(String telephone) async {
    final numero = telephone.replaceAll(RegExp(r'[^\d+]'), '');
    if (numero.isEmpty || !await UrlExterne.lancer('tel:$numero')) {
      _message('Appel impossible depuis cet appareil.');
    }
  }

  Future<void> _carte(String adresse) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(adresse)}';
    if (!await UrlExterne.lancer(url)) _message('Impossible d\'ouvrir la carte.');
  }

  void _message(String texte) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(texte), behavior: SnackBarBehavior.floating));
  }

  Color get _accent {
    final hex = (_boutique?['accent'] ?? '').toString().replaceAll('#', '');
    final v = int.tryParse(hex, radix: 16);
    return (hex.length == 6 && v != null) ? Color(0xFF000000 | v) : AppColor.kPrimary;
  }

  // ── Écran ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    return Scaffold(
      backgroundColor: AppColor.kWhite,
      appBar: AppBar(
        backgroundColor: AppColor.kWhite,
        surfaceTintColor: AppColor.kWhite,
        elevation: 0,
        foregroundColor: AppColor.kGrayscaleDark100,
        actions: const [BoutonPanier(), SizedBox(width: 6)],
      ),
      body: RefreshIndicator(
        color: AppColor.kPrimary,
        onRefresh: () async => Future.wait([_chargerBoutique(), _charger()]),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _entete()),
            if (sections.isNotEmpty)
              ...sections.map((s) => SliverToBoxAdapter(child: _ligneSection(s)))
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
                      child: Center(child: CircularProgressIndicator(color: AppColor.kPrimary, strokeWidth: 2)),
                    )
                  : const SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  // Identité de la boutique.
  Widget _entete() {
    final a = widget.apercu;
    final b = _boutique;
    final nom = (b?['nom'] ?? a?.nom ?? 'Boutique').toString();
    final logo = (b?['logo'] ?? a?.logo ?? '').toString();
    final adresse = (b?['localisation'] ?? a?.localisation ?? '').toString();
    final verifiee = b?['verifiee'] == true || (a?.verifiee ?? false);
    final sousTitre = (b?['slogan'] ?? b?['categorie'] ?? '').toString();
    final telephone = (b?['telephone'] ?? b?['whatsapp'] ?? a?.telephone ?? '').toString();
    final whatsapp = (b?['whatsapp'] ?? b?['telephone'] ?? a?.telephone ?? '').toString();
    final note = b?['note'];
    final nombreAvis = b?['nombreAvis'] is num ? (b!['nombreAvis'] as num).toInt() : 0;
    final depuis = b?['depuis'];
    final reseaux = b?['reseaux'] is Map ? Map<String, dynamic>.from(b!['reseaux'] as Map) : const <String, dynamic>{};

    final meta = <Widget>[
      if (note is num && nombreAvis > 0)
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF5B301)),
          const SizedBox(width: 3),
          Text('$note', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: _encre)),
          Text(' ($nombreAvis avis)', style: texteDiscret(13)),
        ]),
      if (depuis != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.storefront_outlined, size: 16, color: _encre),
          const SizedBox(width: 5),
          Text('Vente en ligne depuis $depuis', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _encre)),
        ]),
      if (adresse.isNotEmpty)
        InkWell(
          onTap: () => _carte(adresse),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_on_outlined, size: 17, color: _accent),
            const SizedBox(width: 4),
            Flexible(
              child: Text(adresse,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _encre)),
            ),
          ]),
        ),
    ];

    final liens = <(IconData, String, String)>[
      if ((reseaux['instagram'] ?? '').toString().isNotEmpty) (Icons.camera_alt_outlined, 'Instagram', reseaux['instagram'].toString()),
      if ((reseaux['snapchat'] ?? '').toString().isNotEmpty) (Icons.chat_bubble_outline_rounded, 'Snapchat', reseaux['snapchat'].toString()),
      if ((reseaux['facebook'] ?? '').toString().isNotEmpty) (Icons.facebook_rounded, 'Facebook', reseaux['facebook'].toString()),
      if ((reseaux['tiktok'] ?? '').toString().isNotEmpty) (Icons.music_note_rounded, 'TikTok', reseaux['tiktok'].toString()),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(color: _accent.withValues(alpha: 0.08), shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: logo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageOptimisee(logo, largeur: 256),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(Icons.storefront_outlined, size: 34, color: _accent),
                      )
                    : Icon(Icons.storefront_outlined, size: 34, color: _accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(nom,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: _encre, height: 1.15)),
                      ),
                      if (verifiee) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 22, color: _bleuVerifie),
                      ],
                    ]),
                    if (sousTitre.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(sousTitre, maxLines: 1, overflow: TextOverflow.ellipsis, style: texteDiscret(14)),
                    ],
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 14, runSpacing: 6, children: meta),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _basculerSuivi,
              icon: Icon(_suivi ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 20, color: _suivi ? const Color(0xFFE53935) : _accent),
              label: Text(_suivi ? 'Suivie' : 'Suivre',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: _accent)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _accent, width: 1.5),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          if (telephone.isNotEmpty || whatsapp.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              if (telephone.isNotEmpty)
                Expanded(child: _tuile(Icons.phone_outlined, 'Appeler', telephone, () => _appeler(telephone))),
              if (telephone.isNotEmpty && whatsapp.isNotEmpty) const SizedBox(width: 10),
              if (whatsapp.isNotEmpty)
                Expanded(child: _tuile(Icons.chat_outlined, 'WhatsApp', 'Écrire', () => _whatsapp(whatsapp))),
            ]),
          ],
          if (liens.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Suivez-nous', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColor.kGrayscale40)),
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
                        child: SizedBox(width: 38, height: 38, child: Icon(l.$1, size: 18, color: _accent, semanticLabel: l.$2)),
                      ),
                    ),
                  ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tuile(IconData icone, String titre, String sousTitre, VoidCallback onTap) {
    return Material(
      color: _fondDoux,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColor.kLine),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: _accent.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(icone, size: 17, color: _accent),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titre, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: _encre)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(sousTitre, maxLines: 1, style: texteDiscret(12)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // Titre de section : gros titre à gauche, « Voir tout → » à droite.
  Widget _titreSection(String titre, {VoidCallback? voirTout}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 12, 12),
      child: Row(children: [
        Expanded(
          child: Text(titre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: _encre)),
        ),
        if (voirTout != null)
          TextButton(
            onPressed: voirTout,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Voir tout', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: _accent)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 18, color: _accent),
            ]),
          ),
      ]),
    );
  }

  // Une section : ses produits sur une ligne qui défile.
  Widget _ligneSection(_Section s) {
    const largeur = 168.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titreSection(s.titre, voirTout: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => _SectionPage(titre: s.titre, produits: s.produits),
            ))),
        SizedBox(
          height: largeur / ratioCarteProduit,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: s.produits.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(width: largeur, child: ProduitCard(produit: s.produits[i])),
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
            child: Center(child: CircularProgressIndicator(color: AppColor.kPrimary, strokeWidth: 2.5)),
          ),
        ),
      ];
    }
    if (_erreur != null) {
      return [
        SliverToBoxAdapter(
          child: EtatVide(icone: Icons.wifi_off_rounded, titre: 'Oups', message: _erreur, action: 'Réessayer', onAction: _charger),
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
            (_, i) => ProduitCard(produit: _produits[i]),
            childCount: _produits.length,
          ),
        ),
      ),
    ];
  }

  // Les avantages de la boutique (« Livraison rapide »…).
  Widget _avantages() {
    final liste = (_boutique?['avantages'] as List? ?? const []).whereType<Map>().toList();
    if (liste.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: _fondDoux, borderRadius: BorderRadius.circular(20)),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: 14,
        children: [
          for (final a in liste)
            SizedBox(
              width: 150,
              child: Column(children: [
                Icon(iconesAvantages[a['icone']]?.$1 ?? Icons.star_border_rounded, size: 26, color: _accent),
                const SizedBox(height: 6),
                Text((a['titre'] ?? '').toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: _encre)),
                if ((a['texte'] ?? '').toString().isNotEmpty)
                  Text(a['texte'].toString(), textAlign: TextAlign.center, style: texteDiscret(12)),
              ]),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('À propos', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: _encre)),
        const SizedBox(height: 8),
        Text(texte, style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.55, color: AppColor.kGrayscale40)),
      ]),
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
        surfaceTintColor: AppColor.kWhite,
        elevation: 0,
        foregroundColor: AppColor.kGrayscaleDark100,
        title: Text(titre, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: const [BoutonPanier(), SizedBox(width: 6)],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: grilleProduits(context),
        itemCount: produits.length,
        itemBuilder: (_, i) => ProduitCard(produit: produits[i]),
      ),
    );
  }
}
