import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saambiz/core/utils/image_url.dart';

import '../../../../core/services/localisation_service.dart';
import '../../../../injection_container.dart';
import '../../../catalogue/data/produit_catalogue.dart' show BoutiqueResume;
import '../../../catalogue/presentation/pages/boutique_publique_page.dart';
import '../../data/categorie.dart';
import '../icones_categories.dart';

class _C {
  static const navy = Color(0xFF0D1B3D);
  static const gold = Color(0xFFF2B705);
  static const bg = Color(0xFFF7F9FC);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E7F0);
  static const textMid = Color(0xFF48597A);
  static const textLight = Color(0xFF8794AC);
  static const green = Color(0xFF22C55E);
  static const navySoft = Color(0xFFE8EDF7);
}

/// Boutiques d'une catégorie — ouverte depuis la rangée de catégories de
/// l'accueil. Les plus proches d'abord quand la position est connue.
class CategorieBoutiquesPage extends StatefulWidget {
  final Categorie categorie;
  const CategorieBoutiquesPage({super.key, required this.categorie});

  @override
  State<CategorieBoutiquesPage> createState() => _CategorieBoutiquesPageState();
}

class _CategorieBoutiquesPageState extends State<CategorieBoutiquesPage> {
  final List<Map<String, dynamic>> _boutiques = [];
  final ScrollController _scroll = ScrollController();
  int _page = 1;
  int _total = 0;
  bool _chargement = true;
  bool _chargementSuite = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_surDefilement);
    _charger();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _surDefilement() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
      _chargerSuite();
    }
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
      _page = 1;
    });
    try {
      final position = const LocalisationService().positionMemorisee();
      final res = await CategoriesRemoteDataSource(sl<Dio>()).boutiques(
        widget.categorie.slug,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      if (!mounted) return;
      setState(() {
        _boutiques
          ..clear()
          ..addAll(res.boutiques);
        _total = res.total;
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

  Future<void> _chargerSuite() async {
    if (_chargementSuite || _chargement || _boutiques.length >= _total) return;
    setState(() => _chargementSuite = true);
    try {
      final position = const LocalisationService().positionMemorisee();
      final res = await CategoriesRemoteDataSource(sl<Dio>()).boutiques(
        widget.categorie.slug,
        page: _page + 1,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      if (!mounted) return;
      setState(() {
        _page += 1;
        _boutiques.addAll(res.boutiques);
        _total = res.total;
      });
    } catch (_) {
      // La suite se rechargera au prochain défilement.
    } finally {
      if (mounted) setState(() => _chargementSuite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.categorie;
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        surfaceTintColor: _C.bg,
        elevation: 0,
        foregroundColor: _C.navy,
        titleSpacing: 0,
        title: Text(
          c.nom,
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: _C.navy),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        color: _C.navy,
        child: _corps(),
      ),
    );
  }

  Widget _corps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: _C.navy));
    }
    if (_erreur != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.wifi_off_rounded, size: 44, color: _C.textLight),
          const SizedBox(height: 16),
          Text(_erreur!, textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _C.textMid)),
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

    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      itemCount: _boutiques.length + 2,
      separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 16 : 10),
      itemBuilder: (_, i) {
        if (i == 0) return _entete();
        if (i == _boutiques.length + 1) {
          if (_boutiques.isEmpty) return _vide();
          return _chargementSuite
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: _C.navy, strokeWidth: 2)),
                )
              : const SizedBox.shrink();
        }
        return _LigneBoutique(donnees: _boutiques[i - 1]);
      },
    );
  }

  Widget _entete() {
    final c = widget.categorie;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: _C.navySoft, borderRadius: BorderRadius.circular(14)),
          child: Icon(iconeCategorie(c.icone), color: _C.navy, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _total > 1 ? '$_total boutiques' : (_total == 1 ? '1 boutique' : 'Aucune boutique'),
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: _C.navy),
              ),
              if ((c.description ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(c.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: _C.textMid)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vide() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(Icons.storefront_outlined, size: 44, color: _C.textLight),
          const SizedBox(height: 14),
          Text(
            'Pas encore de boutique dans cette catégorie.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _C.textMid),
          ),
          const SizedBox(height: 4),
          Text(
            'Revenez bientôt : de nouvelles boutiques ouvrent chaque semaine.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: _C.textLight),
          ),
        ],
      ),
    );
  }
}

/// Une boutique de la liste : logo, nom, ville, badge de confiance, distance.
class _LigneBoutique extends StatelessWidget {
  final Map<String, dynamic> donnees;
  const _LigneBoutique({required this.donnees});

  @override
  Widget build(BuildContext context) {
    final logo = donnees['logo']?.toString();
    final verifiee = donnees['verifiee'] == true;
    final distance = donnees['distanceKm'];
    final slogan = donnees['slogan']?.toString();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (donnees['id'] == null) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BoutiquePubliquePage(
            boutiqueId: donnees['id'].toString(),
            apercu: BoutiqueResume.fromJson(donnees),
          ),
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 60,
                height: 60,
                child: logo != null && logo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageOptimisee(logo),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const _LogoParDefaut(),
                      )
                    : const _LogoParDefaut(),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: _C.navy),
                        ),
                      ),
                      if (verifiee) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.verified_rounded, size: 15, color: _C.green),
                      ],
                    ],
                  ),
                  if (slogan != null && slogan.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(slogan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _C.textMid)),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 13, color: _C.textLight),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          [
                            donnees['localisation']?.toString(),
                            if (distance != null) '$distance km',
                          ].where((e) => e != null && e.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: _C.textLight),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.gold),
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
