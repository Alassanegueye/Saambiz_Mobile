import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../injection_container.dart';
import '../../../boutique/domain/usecases/creer_boutique.dart';
import '../../domain/entities/user.dart';
import 'signup_kit.dart';

const List<String> kCategoriesBoutique = [
  'Mode',
  'Chaussures',
  'Électronique',
  'Beauté',
  'Maison',
  'Alimentation',
  'Sport',
  'Artisanat',
  'Autres',
];

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
class CreerBoutiquePage extends StatefulWidget {
  final User? user;
  const CreerBoutiquePage({super.key, this.user});

  @override
  State<CreerBoutiquePage> createState() => _CreerBoutiquePageState();
}

class _CreerBoutiquePageState extends State<CreerBoutiquePage> {
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  String _categorie = kCategoriesBoutique.first;
  String _ville = kVilles.first;

  bool _loading = false;
  String? _error;
  String? _nomError;

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
      _nomError = nom.length < 2 ? 'Donnez un nom à votre boutique.' : null;
    });
    if (_nomError != null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await sl<CreerBoutique>()(
      nom: nom,
      // La description reste modifiable ensuite depuis « Ma boutique » : on ne
      // la demande pas ici pour garder la création en trois champs.
      description: 'Boutique $_categorie à $_ville',
      localisation: _ville,
      telephone: _telCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Sb.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Créons votre boutique 🏪', style: Sb.title(23)),
              const SizedBox(height: 10),
              Text(
                'Quelques informations suffisent pour ouvrir. Vous pourrez tout modifier plus tard.',
                style: Sb.body(14),
              ),
              const SizedBox(height: 26),

              SbErrorBanner(_error),

              SbField(
                label: 'Nom de la boutique',
                hint: 'Ex. Boutique Alassane',
                controller: _nomCtrl,
                errorText: _nomError,
              ),
              const SizedBox(height: 18),

              _Dropdown(
                label: 'Catégorie',
                value: _categorie,
                items: kCategoriesBoutique,
                icon: Icons.local_offer_outlined,
                onChanged: (v) => setState(() => _categorie = v),
              ),
              const SizedBox(height: 18),

              _Dropdown(
                label: 'Ville',
                value: _ville,
                items: kVilles,
                icon: Icons.location_on_outlined,
                onChanged: (v) => setState(() => _ville = v),
              ),
              const SizedBox(height: 18),

              SbField(
                label: 'Téléphone de la boutique (facultatif)',
                hint: '+221 77 000 00 00',
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 6),
              Text(
                'Vos clients pourront vous joindre sur WhatsApp à ce numéro.',
                style: Sb.body(12),
              ),

              const SizedBox(height: 28),
              SbPrimaryButton(
                label: 'Créer ma boutique',
                loading: _loading,
                onPressed: _creer,
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Vous pourrez modifier ces informations plus tard.',
                  textAlign: TextAlign.center,
                  style: Sb.body(12.5),
                ),
              ),
            ],
          ),
        ),
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
        Text(label, style: Sb.label()),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Sb.textMid,
          ),
          style: GoogleFonts.dmSans(fontSize: 15, color: Sb.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: Sb.white,
            prefixIcon: Icon(icon, size: 19, color: Sb.textMid),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Sb.border, width: 1.3),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Sb.gold, width: 1.6),
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
