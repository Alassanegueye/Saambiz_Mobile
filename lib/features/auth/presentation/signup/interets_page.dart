import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/services/localisation_service.dart';
import '../../../../injection_container.dart';
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

const List<({String label, IconData icon})> _categories = [
  (label: 'Mode', icon: Icons.checkroom_outlined),
  (label: 'Chaussures', icon: Icons.ice_skating_outlined),
  (label: 'Électronique', icon: Icons.smartphone_outlined),
  (label: 'Beauté', icon: Icons.spa_outlined),
  (label: 'Maison', icon: Icons.chair_outlined),
  (label: 'Alimentation', icon: Icons.shopping_basket_outlined),
  (label: 'Sport', icon: Icons.sports_soccer_outlined),
  (label: 'Autres', icon: Icons.more_horiz_rounded),
];

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
  final Set<String> _selection = {};
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
        _selection.addAll(
          sl<SharedPreferences>().getStringList(kInteretsKey) ?? const [],
        );
      } catch (_) {/* grille vide */}
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
    return SbScaffold(
      children: [
        const SizedBox(height: 14),
        Text(
          prenom == null || prenom.isEmpty
              ? 'Bienvenue sur SaamBiz 🎉'
              : 'Bienvenue $prenom 🎉',
          style: Sb.title(23),
        ),
        const SizedBox(height: 10),
        Text(
          "Qu'est-ce qui vous intéresse ?\nChoisissez au moins 2 catégories.",
          style: Sb.body(14),
        ),
        const SizedBox(height: 24),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (_, i) {
            final cat = _categories[i];
            final on = _selection.contains(cat.label);
            return _CategoryTile(
              label: cat.label,
              icon: cat.icon,
              selected: on,
              onTap: () => setState(() {
                on ? _selection.remove(cat.label) : _selection.add(cat.label);
              }),
            );
          },
        ),

        const SizedBox(height: 26),
        SbPrimaryButton(
          label: widget.modeEdition ? 'Enregistrer' : 'Découvrir SaamBiz',
          icon: Icons.arrow_forward_rounded,
          loading: _saving,
          onPressed: _valide ? _continuer : null,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _valide
                ? '${_selection.length} catégories sélectionnées'
                : 'Sélectionnez au moins 2 catégories',
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
            color: selected ? Sb.goldSoft : Sb.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Sb.gold : Sb.border,
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
                        style: GoogleFonts.dmSans(
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
                    backgroundColor: Sb.gold,
                    child: Icon(Icons.check_rounded, size: 12, color: Sb.navy),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
