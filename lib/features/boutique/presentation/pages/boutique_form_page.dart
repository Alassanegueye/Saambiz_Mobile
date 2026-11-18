import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/page_vendeur.dart';
import 'package:saambiz/core/widgets/libelle_obligatoire.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'dart:io';
import 'package:saambiz/core/utils/telephone.dart';
import 'package:saambiz/core/widgets/bouton_indicatif.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/police.dart';
import '../../../../injection_container.dart';
import '../../../categories/presentation/widgets/selecteur_categories.dart';
import '../../domain/entities/boutique.dart';
import '../bloc/boutique_bloc.dart';
import '../bloc/boutique_event.dart';
import '../bloc/boutique_state.dart';

class _C {
  static const green = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F8);
  static const border = Color(0xFFE3E8F0);
}

/// Création (POST /vendeur/creer-boutique) ou modification
/// (PUT /vendeur/modifier-boutique) de la boutique du vendeur connecté.
class BoutiqueFormPage extends StatelessWidget {
  final Boutique? boutique; // null = création
  const BoutiqueFormPage({super.key, this.boutique});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BoutiqueBloc>(),
      child: _BoutiqueFormView(boutique: boutique),
    );
  }
}

class _BoutiqueFormView extends StatefulWidget {
  final Boutique? boutique;
  const _BoutiqueFormView({this.boutique});

  @override
  State<_BoutiqueFormView> createState() => _BoutiqueFormViewState();
}

class _BoutiqueFormViewState extends State<_BoutiqueFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _nomCtrl = TextEditingController(text: widget.boutique?.nom ?? '');
  late final _descCtrl = TextEditingController(
    text: widget.boutique?.description ?? '',
  );
  late final _localisationCtrl = TextEditingController(
    text: widget.boutique?.localisation ?? '',
  );
  // Le numéro enregistré (« +221771234567 ») est découpé en pays + numéro.
  late final _telLu = lireTelephone(widget.boutique?.telephone);
  late final _telephoneCtrl = TextEditingController(text: _telLu.national);
  late final _paysTel = ValueNotifier<PaysTelephone>(_telLu.pays);
  String? _logoPath;
  late List<String> _categories = List.of(
    widget.boutique?.categories ?? const <String>[],
  );
  String? _erreurCategories;

  bool get _isEdit => widget.boutique != null;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    _localisationCtrl.dispose();
    _telephoneCtrl.dispose();
    _paysTel.dispose();
    super.dispose();
  }

  Future<void> _choisirLogo() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1000,
    );
    if (x != null) setState(() => _logoPath = x.path);
  }

  void _soumettre() {
    final formulaireValide = _formKey.currentState!.validate();
    setState(
      () => _erreurCategories = _categories.isEmpty
          ? 'Choisissez au moins une catégorie.'
          : null,
    );
    if (!formulaireValide || _categories.isEmpty) return;
    final bloc = context.read<BoutiqueBloc>();
    if (_isEdit) {
      bloc.add(
        ModifierBoutiqueRequested(
          nom: _nomCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          localisation: _localisationCtrl.text.trim(),
          telephone: telephoneInternational(
            _telephoneCtrl.text,
            _paysTel.value,
          ),
          categories: _categories,
          logoPath: _logoPath,
        ),
      );
    } else {
      bloc.add(
        CreerBoutiqueRequested(
          nom: _nomCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          localisation: _localisationCtrl.text.trim(),
          telephone: telephoneInternational(
            _telephoneCtrl.text,
            _paysTel.value,
          ),
          categories: _categories,
          logoPath: _logoPath,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMarine(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier ma boutique' : 'Créer ma boutique'),
      ),
      body: BlocConsumer<BoutiqueBloc, BoutiqueState>(
        listener: (context, state) {
          if (state is BoutiqueError) {
            afficherErreur(context, state.message);
          } else if (state is BoutiqueLoaded) {
            afficherSucces(
              context,
              _isEdit
                  ? 'Les informations de votre boutique sont à jour.'
                  : 'Votre boutique est prête.',
              titre: _isEdit ? 'Modifications enregistrées' : 'Boutique créée',
            );
            Navigator.of(context).pop(state.boutique);
          }
        },
        builder: (context, state) {
          final loading = state is BoutiqueLoading;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _logoPicker(),
                const SizedBox(height: 22),
                _titreSection('Identité'),
                _input(
                  _nomCtrl,
                  'Nom de la boutique',
                  verifier: (v) => RegExp(r'^\p{L}', unicode: true).hasMatch(v)
                      ? null
                      : 'Le nom de la boutique doit commencer par une lettre.',
                ),
                const SizedBox(height: 12),
                _input(_descCtrl, 'Description', maxLines: 3),
                const SizedBox(height: 22),
                _titreSection('Coordonnées'),
                _input(_localisationCtrl, 'Localisation (ville)'),
                const SizedBox(height: 12),
                _input(
                  _telephoneCtrl,
                  'Téléphone',
                  keyboard: TextInputType.phone,
                  verifier: (v) => verifierTelephone(v, _paysTel.value),
                  formats: [FormatTelephone(_paysTel)],
                  prefixe: BoutonIndicatif(
                    pays: _paysTel,
                    onChange: () => setState(_telephoneCtrl.clear),
                  ),
                ),
                const SizedBox(height: 22),
                SelecteurCategories(
                  initiales: _categories,
                  erreur: _erreurCategories,
                  onChanged: (choix) => setState(() {
                    _categories = choix;
                    if (choix.isNotEmpty) _erreurCategories = null;
                  }),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: loading ? null : _soumettre,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.green,
                    foregroundColor: _C.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit
                              ? 'Enregistrer les modifications'
                              : 'Créer la boutique',
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Le logo : un aperçu carré avec sa pastille d'appareil photo, et ce
  /// que fait le toucher. C'était un grand cadre vide, sans un mot.
  Widget _logoPicker() {
    final aUnLogo =
        _logoPath != null ||
        (_isEdit && (widget.boutique!.logo ?? '').isNotEmpty);
    const vide = Center(
      child: Icon(
        Icons.add_photo_alternate_outlined,
        color: AppColor.kPrimary,
        size: 34,
      ),
    );
    final Widget apercu = _logoPath != null
        ? Image.file(File(_logoPath!), fit: BoxFit.cover)
        : aUnLogo
        ? ImageReseau(widget.boutique!.logo!, fit: BoxFit.cover, repli: vide)
        : vide;
    return Center(
      child: Semantics(
        button: true,
        label: aUnLogo ? 'Changer le logo' : 'Ajouter un logo',
        child: GestureDetector(
          onTap: _choisirLogo,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: AppColor.kPrimaryLight,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColor.kPrimaryBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: apercu,
                  ),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColor.kSecondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColor.kWhite, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        size: 17,
                        color: AppColor.kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                aUnLogo ? 'Changer le logo' : 'Ajouter un logo',
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Une image carrée rend le mieux',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 12,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Titre gris au-dessus d'un groupe de champs, comme sur « Ma boutique ».
  Widget _titreSection(String titre) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      titre,
      style: const TextStyle(
        fontFamily: kPolice,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColor.kGrayscale40,
      ),
    ),
  );

  Widget _input(
    TextEditingController c,
    String label, {
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String)? verifier,
    List<TextInputFormatter>? formats,
    Widget? prefixe,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      inputFormatters: formats,
      validator: (v) => (v == null || v.trim().isEmpty)
          ? '$label requis'
          : verifier?.call(v.trim()),
      decoration: InputDecoration(
        label: LibelleObligatoire(label),
        prefixIcon: prefixe,
        filled: true,
        fillColor: _C.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.green),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border),
        ),
      ),
    );
  }
}
