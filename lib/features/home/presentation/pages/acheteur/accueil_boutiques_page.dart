import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/services/localisation_service.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/domain/entities/user.dart';
import '../../../../auth/presentation/signup/interets_page.dart';
import '../../../data/datasources/accueil_remote_datasource.dart';
import '../../../data/models/boutique_model.dart';
import 'boutique_detail_page.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
class _C {
  static const navy = Color(0xFF0D1B3D);
  static const gold = Color(0xFFF2B705);
  static const bg = Color(0xFFF7F9FC);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E7F0);
  static const textMid = Color(0xFF48597A);
  static const textLight = Color(0xFF8794AC);
  static const green = Color(0xFF22C55E);
}

/// Accueil du client — une marketplace de BOUTIQUES, pas de produits.
///
/// Les sections, leur ordre et leurs libellés viennent du backend : c'est lui
/// qui connaît les affinités, les abonnements et la position. L'écran ne
/// décide de rien, il affiche ce qui lui est servi — ce qui permet de faire
/// évoluer la personnalisation sans publier une nouvelle version de l'app.
class AccueilBoutiquesPage extends StatefulWidget {
  final User? user;
  final bool isGuest;

  const AccueilBoutiquesPage({super.key, this.user, this.isGuest = false});

  @override
  State<AccueilBoutiquesPage> createState() => _AccueilBoutiquesPageState();
}

class _AccueilBoutiquesPageState extends State<AccueilBoutiquesPage> {
  AccueilPersonnalise? _accueil;
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  /// Les centres d'intérêt d'un invité vivent sur son téléphone ; ceux d'un
  /// client connecté sont côté serveur et n'ont pas à être renvoyés.
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
      _chargement = true;
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
        _erreur = 'Impossible de charger les boutiques. Vérifiez votre connexion.';
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _charger,
          color: _C.navy,
          child: _construireCorps(),
        ),
      ),
    );
  }

  Widget _construireCorps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: _C.navy));
    }

    if (_erreur != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.wifi_off_rounded, size: 44, color: _C.textLight),
          const SizedBox(height: 16),
          Text(
            _erreur!,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 14, color: _C.textMid),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton(
              onPressed: _charger,
              style: FilledButton.styleFrom(backgroundColor: _C.navy),
              child: const Text('Réessayer'),
            ),
          ),
        ],
      );
    }

    final accueil = _accueil;
    if (accueil == null || accueil.estVide) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.storefront_outlined, size: 44, color: _C.textLight),
          const SizedBox(height: 16),
          Text(
            'Aucune boutique à afficher pour le moment.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 14, color: _C.textMid),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        _entete(accueil),
        for (final section in accueil.sections) _construireSection(section),
      ],
    );
  }

  Widget _entete(AccueilPersonnalise accueil) {
    final prenom = widget.user?.prenom;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prenom != null && prenom.isNotEmpty
                ? 'Bonjour $prenom 👋'
                : 'Bonjour 👋',
            style: GoogleFonts.sora(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: _C.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            accueil.positionConnue
                ? 'Les boutiques qui vous ressemblent, près de chez vous'
                : 'Les boutiques qui vous ressemblent',
            style: GoogleFonts.dmSans(fontSize: 13.5, color: _C.textMid),
          ),

          // Les centres d'intérêt sont rappelés et modifiables : c'est le
          // seul endroit où le client reprend la main sur ce qu'on lui montre.
          if (accueil.interets.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final interet in accueil.interets)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                      decoration: BoxDecoration(
                        color: _C.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _C.border),
                      ),
                      child: Text(
                        interet,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.navy,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: _modifierInterets,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                      decoration: BoxDecoration(
                        color: _C.navy,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune_rounded, size: 13, color: _C.gold),
                          const SizedBox(width: 5),
                          Text(
                            'Modifier',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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

  Widget _construireSection(AccueilSection section) {
    if (section.elements.isEmpty) return const SizedBox.shrink();
    final estProduits = section.type == 'produits';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.titre,
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.navy,
                ),
              ),
              if (section.sousTitre != null && section.sousTitre!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    section.sousTitre!,
                    style: GoogleFonts.dmSans(fontSize: 12, color: _C.textLight),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: estProduits ? 208 : 176,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.elements.length,
            itemBuilder: (_, i) => estProduits
                ? _CarteProduit(donnees: section.elements[i])
                : _CarteBoutique(donnees: section.elements[i]),
          ),
        ),
      ],
    );
  }
}

/// Carte d'une boutique : logo, nom, catégorie, badge de confiance et
/// distance quand la position est connue.
class _CarteBoutique extends StatelessWidget {
  final Map<String, dynamic> donnees;
  const _CarteBoutique({required this.donnees});

  @override
  Widget build(BuildContext context) {
    final logo = donnees['logo']?.toString();
    final verifiee = donnees['verifiee'] == true;
    final distance = donnees['distanceKm'];
    final note = donnees['note'];

    return GestureDetector(
      onTap: () {
        if (donnees['id'] == null) return;
        // La fiche boutique attend le modèle complet : la charge utile de
        // l'accueil en contient assez pour l'ouvrir sans aller-retour.
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BoutiqueDetailPage(
            boutique: BoutiqueModel.fromJson(donnees),
          ),
        ));
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: SizedBox(
                    height: 88,
                    width: double.infinity,
                    child: logo != null && logo.isNotEmpty
                        ? Image.network(
                            logo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _LogoParDefaut(),
                          )
                        : const _LogoParDefaut(),
                  ),
                ),
                if (verifiee)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: _C.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded,
                          size: 14, color: _C.green),
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
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _C.navy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      donnees['categorie']?.toString(),
                      donnees['localisation']?.toString(),
                    ].where((e) => e != null && e.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(fontSize: 11, color: _C.textLight),
                  ),
                  if (distance != null || note != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (note != null) ...[
                          const Icon(Icons.star_rounded, size: 13, color: _C.gold),
                          const SizedBox(width: 3),
                          Text(
                            '$note',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _C.navy,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (distance != null) ...[
                          const Icon(Icons.place_outlined, size: 12, color: _C.textLight),
                          const SizedBox(width: 2),
                          Text(
                            '$distance km',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: _C.textLight),
                          ),
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

/// Carte d'un produit — n'apparaît que dans la section des boutiques suivies.
class _CarteProduit extends StatelessWidget {
  final Map<String, dynamic> donnees;
  const _CarteProduit({required this.donnees});

  @override
  Widget build(BuildContext context) {
    final image = donnees['image']?.toString();
    final boutique = donnees['boutique'] as Map?;

    return GestureDetector(
      onTap: () {
        final boutique = donnees['boutique'] as Map?;
        if (boutique == null || boutique['id'] == null) return;
        // Pas d'écran de détail produit autonome côté acheteur : on ouvre la
        // boutique, où le produit est présenté avec le reste du catalogue.
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BoutiqueDetailPage(
            boutique: BoutiqueModel.fromJson(Map<String, dynamic>.from(boutique)),
          ),
        ));
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: SizedBox(
                height: 112,
                width: double.infinity,
                child: image != null && image.isNotEmpty
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _LogoParDefaut(),
                      )
                    : const _LogoParDefaut(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donnees['nom']?.toString() ?? 'Produit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _C.navy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${donnees['prix'] ?? '—'} FCFA',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _C.navy,
                    ),
                  ),
                  if (boutique != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      boutique['nom']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(fontSize: 10.5, color: _C.textLight),
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

class _LogoParDefaut extends StatelessWidget {
  const _LogoParDefaut();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFEDF1F9),
        child: const Icon(Icons.storefront_outlined, color: _C.textLight),
      );
}
