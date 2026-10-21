import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../injection_container.dart';
import '../../../boutique/domain/usecases/creer_boutique.dart';
import '../../domain/entities/user.dart';
import '../../../categories/presentation/widgets/selecteur_categories.dart';
import '../widgets/mise_en_page_auth.dart';
import 'signup_kit.dart';

const List<String> kVilles = [
  'Dakar',
  'Thiès',
  'Saint-Louis',
  'Touba',
  'Mbour',
  'Ziguinchor',
  'Kaolack',
  'Rufisque',
  'Diourbel',
  'Autre',
];

/// Écran 4B : création de la boutique, juste après la vérification email.
/// L'utilisateur est déjà connecté à ce stade (connexion automatique après
/// validation du code), l'appel part donc avec son jeton.
///
/// Trois pages, une question par écran : le nom, les catégories, puis la
/// ville et le WhatsApp.
class CreerBoutiquePage extends StatefulWidget {
  final User? user;
  const CreerBoutiquePage({super.key, this.user});

  @override
  State<CreerBoutiquePage> createState() => _CreerBoutiquePageState();
}

class _CreerBoutiquePageState extends State<CreerBoutiquePage> {
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  // Slugs choisis (1 à 3) ; la liste vient du serveur, gérée dans le dashboard.
  List<String> _categories = const [];
  String? _categoriesError;
  String _ville = kVilles.first;

  bool _loading = false;
  String? _error;
  String? _nomError;

  /// 0 : nom · 1 : catégories · 2 : ville et WhatsApp.
  int _page = 0;

  String? _erreurNom(String nom) => nom.length < 2
      ? 'Donnez un nom à votre boutique.'
      : !RegExp(r'^\p{L}', unicode: true).hasMatch(nom)
          ? 'Le nom de la boutique doit commencer par une lettre.'
          : null;

  void _continuer() {
    FocusScope.of(context).unfocus();
    if (_page == 0) {
      setState(() => _nomError = _erreurNom(_nomCtrl.text.trim()));
      if (_nomError != null) return;
    }
    if (_page == 1) {
      setState(() => _categoriesError =
          _categories.isEmpty ? 'Choisissez au moins une catégorie.' : null);
      if (_categoriesError != null) return;
    }
    if (_page < 2) {
      setState(() {
        _page++;
        _error = null;
      });
    } else {
      _creer();
    }
  }

  void _retour() {
    if (_loading) return;
    if (_page > 0) {
      setState(() => _page--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _creer() async {
    FocusScope.of(context).unfocus();
    final nom = _nomCtrl.text.trim();
    setState(() {
      _nomError = _erreurNom(nom);
      _categoriesError =
          _categories.isEmpty ? 'Choisissez au moins une catégorie.' : null;
    });
    if (_nomError != null || _categoriesError != null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await sl<CreerBoutique>()(
      nom: nom,
      // La description reste modifiable ensuite depuis « Ma boutique » : on ne
      // la demande pas ici pour garder la création en trois champs.
      description: 'Boutique à $_ville',
      localisation: _ville,
      telephone: _telCtrl.text.trim(),
      categories: _categories,
    );

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _error = failure.errorMessage;
        _loading = false;
      }),
      (boutique) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.boutiquePreteRoute,
          (_) => false,
          arguments: {'user': widget.user, 'nomBoutique': boutique.nom},
        );
      },
    );
  }

  static const _titres = [
    ('Votre boutique', 'Le nom que verront vos clients.'),
    ('Ce que vous vendez', 'Choisissez de 1 à 3 catégories.'),
    ('Où vous trouver', 'Tout reste modifiable ensuite.'),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _page == 0 && !_loading,
      onPopInvokedWithResult: (aQuitte, _) {
        if (!aQuitte) _retour();
      },
      child: SbPageAuth(
        etape: 5,
        vendeur: true,
        icone: const [Icons.storefront_outlined, Icons.category_outlined, Icons.location_on_outlined][_page],
        titre: _titres[_page].$1,
        sousTitre: _titres[_page].$2,
        onRetour: _retour,
        carte: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'Page ${_page + 1} sur 3',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: Sb.textMid),
            ),
          ),
          SbErrorBanner(_error),
          if (_page == 0)
            SbField(
              label: 'Nom de la boutique',
              hint: 'Ex. Boutique Awa',
              icon: Icons.storefront_outlined,
              controller: _nomCtrl,
              errorText: _nomError,
              textInputAction: TextInputAction.done,
            ),
          // Gardé monté (caché) : le sélecteur charge la liste une seule fois
          // et retrouve le choix quand on revient sur cette page.
          Offstage(
            offstage: _page != 1,
            child: SelecteurCategories(
              erreur: _categoriesError,
              onChanged: (choix) => setState(() {
                _categories = choix;
                if (choix.isNotEmpty) _categoriesError = null;
              }),
            ),
          ),
          if (_page == 2) ...[
            _Dropdown(
              label: 'Ville',
              value: _ville,
              items: kVilles,
              icon: Icons.location_on_outlined,
              onChanged: (v) => setState(() => _ville = v),
            ),
            const SizedBox(height: 16),
            SbField(
              label: 'WhatsApp de la boutique (facultatif)',
              hint: '+221 77 000 00 00',
              icon: Icons.phone_outlined,
              controller: _telCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),
          ],
          const SizedBox(height: 22),
          SbPrimaryButton(
            label: _page < 2 ? 'Continuer' : 'Créer ma boutique',
            icon: Icons.arrow_forward_rounded,
            loading: _loading,
            onPressed: _continuer,
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LibelleChamp(label),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Sb.textMid,
          ),
          style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Sb.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: Sb.surface,
            isDense: true,
            prefixIcon: Icon(icon, size: 20, color: Sb.navy),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Sb.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Sb.navy, width: 1.5),
            ),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
