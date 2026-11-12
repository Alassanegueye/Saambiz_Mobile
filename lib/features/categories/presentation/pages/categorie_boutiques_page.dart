import 'package:dio/dio.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:flutter/material.dart';
import 'package:saambiz/core/widgets/logo_boutique.dart';
import 'package:saambiz/core/theme/police.dart';

import '../../../../core/services/localisation_service.dart';
import '../../../../injection_container.dart';
import '../../../catalogue/data/produit_catalogue.dart' show BoutiqueResume;
import '../../../catalogue/presentation/pages/boutique_publique_page.dart';
import '../../data/categorie.dart';
import '../icones_categories.dart';

class _C {
  static const navy = Color(0xFF01154B);
  static const gold = Color(0xFFFBB900);
  static const bg = Color(0xFFF7F9FC);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E7F0);
  static const textMid = Color(0xFF48597A);
  static const textLight = Color(0xFF8794AC);
  static const green = Color(0xFF22C55E);
  static const navySoft = Color(0xFFE8EDF7);
}

/// Boutiques d'une catégorie, ouverte depuis la rangée de catégories de
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
        _erreur =
            'Impossible de charger les boutiques. Vérifiez votre connexion.';
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
        titleSpacing: 0,
        title: Text(
          c.nom,
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
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
          Text(
            _erreur!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 14,
              color: _C.textMid,
            ),
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
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _C.navy,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : const SizedBox.shrink();
        }
        return LigneBoutique(donnees: _boutiques[i - 1]);
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
          decoration: BoxDecoration(
            color: _C.navySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(iconeCategorie(c.icone), color: _C.navy, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _total > 1
                    ? '$_total boutiques'
                    : (_total == 1 ? '1 boutique' : 'Aucune boutique'),
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _C.navy,
                ),
              ),
              if ((c.description ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    c.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 12.5,
                      color: _C.textMid,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vide() {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.storefront_outlined, size: 44, color: _C.textLight),
          SizedBox(height: 14),
          Text(
            'Pas encore de boutique dans cette catégorie.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 14,
              color: _C.textMid,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Revenez bientôt : de nouvelles boutiques ouvrent chaque semaine.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 12.5,
              color: _C.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Une boutique de la liste : logo, nom, badge de confiance, catégorie,
/// ville, distance, note et nombre d'articles quand le serveur les donne.
class LigneBoutique extends StatelessWidget {
  final Map<String, dynamic> donnees;
  const LigneBoutique({super.key, required this.donnees});

  void _ouvrir(BuildContext context) {
    if (donnees['id'] == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BoutiquePubliquePage(
          boutiqueId: donnees['id'].toString(),
          apercu: BoutiqueResume.fromJson(donnees),
        ),
      ),
    );
  }

  static String? _texte(dynamic v) {
    final t = v?.toString().trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  static String? _distance(dynamic v) {
    final d = v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
    if (d == null) return null;
    if (d < 1) return '${(d * 1000).round()} m';
    return '${d < 10 ? d.toStringAsFixed(1) : d.round()} km';
  }

  @override
  Widget build(BuildContext context) {
    final logo = _texte(donnees['logo']);
    final nom = _texte(donnees['nom']) ?? 'Boutique';
    final verifiee = donnees['verifiee'] == true;
    final slogan = _texte(donnees['slogan']);
    final categorie = _texte(donnees['categorie']);
    final ville = _texte(donnees['localisation']);
    final distance = _distance(donnees['distanceKm']);
    final noteBrute = donnees['note'];
    final note = noteBrute is num
        ? noteBrute.toDouble()
        : double.tryParse('${noteBrute ?? ''}');
    final nbBrut = donnees['nombreProduits'];
    final nbArticles = nbBrut is num
        ? nbBrut.toInt()
        : int.tryParse('${nbBrut ?? ''}');

    return Material(
      color: _C.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _ouvrir(context),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
            boxShadow: [
              BoxShadow(
                color: _C.navy.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: logo != null
                      ? ImageReseau(
                          logo,
                          fit: BoxFit.cover,
                          repli: const _LogoParDefaut(),
                        )
                      : const _LogoParDefaut(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: _C.navy,
                            ),
                          ),
                        ),
                        if (verifiee) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: _C.green,
                          ),
                        ],
                      ],
                    ),
                    if (slogan != null || categorie != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        slogan ?? categorie!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 12.5,
                          color: _C.textMid,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (note != null && note > 0)
                          _Pastille(
                            icone: Icons.star_rounded,
                            texte: note.toStringAsFixed(1),
                            fond: const Color(0xFFFFF4D1),
                            couleur: const Color(0xFF9A6B00),
                            couleurIcone: _C.gold,
                          ),
                        if (ville != null || distance != null)
                          _Pastille(
                            icone: Icons.place_outlined,
                            texte: [
                              ville,
                              distance,
                            ].whereType<String>().join(' · '),
                          ),
                        if (nbArticles != null && nbArticles > 0)
                          _Pastille(
                            icone: Icons.inventory_2_outlined,
                            texte: nbArticles == 1
                                ? '1 article'
                                : '$nbArticles articles',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _C.navySoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: _C.navy,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  final IconData icone;
  final String texte;
  final Color fond;
  final Color couleur;
  final Color? couleurIcone;
  const _Pastille({
    required this.icone,
    required this.texte,
    this.fond = _C.navySoft,
    this.couleur = _C.textMid,
    this.couleurIcone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: couleurIcone ?? couleur),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              texte,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: couleur,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoParDefaut extends StatelessWidget {
  const _LogoParDefaut();

  @override
  Widget build(BuildContext context) => const LogoBoutiqueParDefaut();
}
