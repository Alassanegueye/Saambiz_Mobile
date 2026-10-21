import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/services/localisation_service.dart';
import '../../../../injection_container.dart';
import '../../../categories/data/categorie.dart';
import '../../../categories/presentation/icones_categories.dart';
import '../../../home/data/datasources/accueil_remote_datasource.dart';
import '../../domain/entities/user.dart';
import 'signup_kit.dart';

/// Centres d'intérêt conservés sur l'appareil.
///
/// Indispensable pour les invités : sans compte, il n'y a rien à enregistrer
/// côté serveur, et c'est pourtant ce qui personnalise leur accueil. Pour un
/// client connecté, la sélection part aussi vers le backend (elle le suit
/// alors d'un appareil à l'autre) et cette copie locale sert de secours.
const String kInteretsKey = 'client_interets';

/// Centres d'intérêt du client.
///
/// Trois entrées : après la vérification email (nouveau compte), juste après
/// « continuer sans compte » (invité), ou depuis l'accueil pour ajuster sa
/// sélection (`modeEdition`).
class InteretsPage extends StatefulWidget {
  final User? user;
  final bool isGuest;

  /// Ouvert depuis l'accueil : on enregistre et on revient en arrière au lieu
  /// d'enchaîner sur la suite du parcours d'inscription.
  final bool modeEdition;

  const InteretsPage({
    super.key,
    this.user,
    this.isGuest = false,
    this.modeEdition = false,
  });

  @override
  State<InteretsPage> createState() => _InteretsPageState();
}

class _InteretsPageState extends State<InteretsPage> {
  // Slugs des catégories choisies. La liste elle-même vient du serveur
  // (gérée dans le dashboard admin) ; la liste de secours s'affiche tant
  // que le réseau n'a pas répondu.
  final Set<String> _selection = {};
  List<Categorie> _categories = kCategoriesSecours;
  List<String> _enregistrees = const [];
  bool _saving = false;

  // Deux catégories minimum : en dessous, le fil personnalisé n'a pas
  // assez de matière pour être différent de l'accueil générique.
  bool get _valide => _selection.length >= 2;

  @override
  void initState() {
    super.initState();
    // En édition, on repart de la sélection existante plutôt que d'une
    // grille vide : le client ajuste, il ne recommence pas.
    if (widget.modeEdition) {
      try {
        _enregistrees =
            sl<SharedPreferences>().getStringList(kInteretsKey) ?? const [];
      } catch (_) {/* grille vide */}
      _reprendreSelection();
    }
    _chargerCategories();
  }

  Future<void> _chargerCategories() async {
    final liste = await CategoriesRemoteDataSource(sl<Dio>()).lister();
    if (!mounted) return;
    setState(() {
      _categories = liste;
      _reprendreSelection();
    });
  }

  /// La sélection enregistrée peut contenir des slugs ou, pour une ancienne
  /// version de l'application, des noms : on la ramène aux slugs affichés.
  void _reprendreSelection() {
    final slugs = _categories.map((c) => c.slug).toSet();
    _selection.removeWhere((s) => !slugs.contains(s));
    for (final v in _enregistrees) {
      for (final c in _categories) {
        if (c.correspond(v)) _selection.add(c.slug);
      }
    }
  }

  Future<void> _continuer() async {
    if (!_valide || _saving) return;
    setState(() => _saving = true);

    final choix = _selection.toList();

    try {
      await sl<SharedPreferences>().setStringList(kInteretsKey, choix);
    } catch (_) {
      // Confort d'affichage : on n'empêche pas d'entrer dans l'application
      // si l'écriture locale échoue.
    }

    // Client connecté : la sélection part aussi côté serveur, c'est elle qui
    // amorce les affinités de son accueil.
    if (!widget.isGuest) {
      await AccueilRemoteDataSource(sl<Dio>()).majPreferences(interets: choix);
    }

    if (!mounted) return;

    if (widget.modeEdition) {
      Navigator.of(context).pop(true);
      return;
    }

    // La géolocalisation n'est proposée qu'une fois : si le client a déjà
    // tranché, on entre directement dans l'application.
    if (const LocalisationService().dejaDemandee()) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.acheteurRoute,
        (_) => false,
        arguments: widget.isGuest
            ? const {'isGuest': true}
            : (widget.user ?? const {'isGuest': false}),
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.localisationRoute,
        (_) => false,
        arguments: {'user': widget.user, 'isGuest': widget.isGuest},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prenom = widget.user?.prenom;
    return SbPageAuth(
      // Dernière étape de l'inscription d'un client (pas en modification).
      etape: widget.modeEdition ? null : 5,
      icone: Icons.favorite_border_rounded,
      titre: widget.modeEdition
          ? 'Vos goûts'
          : prenom == null || prenom.isEmpty
              ? 'Bienvenue !'
              : 'Bienvenue $prenom',
      sousTitre: 'Choisissez au moins 2 catégories.',
      carte: [
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (_, i) {
            final cat = _categories[i];
            final on = _selection.contains(cat.slug);
            return _CategoryTile(
              label: cat.nom,
              icon: iconeCategorie(cat.icone),
              selected: on,
              onTap: () => setState(() {
                on ? _selection.remove(cat.slug) : _selection.add(cat.slug);
              }),
            );
          },
        ),
        const SizedBox(height: 22),
        SbPrimaryButton(
          label: widget.modeEdition ? 'Enregistrer' : 'Découvrir SaamBiz',
          icon: Icons.arrow_forward_rounded,
          loading: _saving,
          onPressed: _valide ? _continuer : null,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '${_selection.length} sélectionnée${_selection.length > 1 ? 's' : ''}',
            style: Sb.body(12.5),
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected ? Sb.navyTint : Sb.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Sb.navy : Sb.border,
              width: selected ? 1.8 : 1.3,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 26, color: Sb.navy),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Sb.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Sb.navy,
                    child: Icon(Icons.check_rounded, size: 12, color: Sb.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
