import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../injection_container.dart';
import '../../../categories/presentation/widgets/selecteur_categories.dart';
import '../../domain/entities/boutique.dart';
import '../bloc/boutique_bloc.dart';
import '../bloc/boutique_event.dart';
import '../bloc/boutique_state.dart';
import 'package:saambiz/core/utils/image_url.dart';

class _C {
  static const green = Color(0xFF0D1B3D);
  static const black = Color(0xFF0D1B3D);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF5B6C8A);
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
  late final _descCtrl =
      TextEditingController(text: widget.boutique?.description ?? '');
  late final _localisationCtrl =
      TextEditingController(text: widget.boutique?.localisation ?? '');
  late final _telephoneCtrl =
      TextEditingController(text: widget.boutique?.telephone ?? '');
  String? _logoPath;
  late List<String> _categories = List.of(widget.boutique?.categories ?? const <String>[]);
  String? _erreurCategories;

  bool get _isEdit => widget.boutique != null;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    _localisationCtrl.dispose();
    _telephoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirLogo() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1000);
    if (x != null) setState(() => _logoPath = x.path);
  }

  void _soumettre() {
    final formulaireValide = _formKey.currentState!.validate();
    setState(() => _erreurCategories =
        _categories.isEmpty ? 'Choisissez au moins une catégorie.' : null);
    if (!formulaireValide || _categories.isEmpty) return;
    final bloc = context.read<BoutiqueBloc>();
    if (_isEdit) {
      bloc.add(ModifierBoutiqueRequested(
        nom: _nomCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        localisation: _localisationCtrl.text.trim(),
        telephone: _telephoneCtrl.text.trim(),
        categories: _categories,
        logoPath: _logoPath,
      ));
    } else {
      bloc.add(CreerBoutiqueRequested(
        nom: _nomCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        localisation: _localisationCtrl.text.trim(),
        telephone: _telephoneCtrl.text.trim(),
        categories: _categories,
        logoPath: _logoPath,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: Text(_isEdit ? 'Modifier ma boutique' : 'Créer ma boutique'),
      ),
      body: BlocConsumer<BoutiqueBloc, BoutiqueState>(
        listener: (context, state) {
          if (state is BoutiqueError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is BoutiqueLoaded) {
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
                const SizedBox(height: 16),
                _input(_nomCtrl, 'Nom de la boutique',
                    verifier: (v) => RegExp(r'^\p{L}', unicode: true).hasMatch(v)
                        ? null
                        : 'Le nom de la boutique doit commencer par une lettre.'),
                const SizedBox(height: 12),
                _input(_descCtrl, 'Description', maxLines: 3),
                const SizedBox(height: 12),
                _input(_localisationCtrl, 'Localisation (ville)'),
                const SizedBox(height: 12),
                _input(_telephoneCtrl, 'Téléphone', keyboard: TextInputType.phone),
                const SizedBox(height: 20),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_isEdit ? 'Enregistrer' : 'Créer la boutique',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _logoPicker() {
    Widget content;
    if (_logoPath != null) {
      content = Image.file(File(_logoPath!), fit: BoxFit.cover);
    } else if (_isEdit && (widget.boutique!.logo ?? '').isNotEmpty) {
      content = CachedNetworkImage(imageUrl: imageOptimisee(widget.boutique!.logo!), fit: BoxFit.cover);
    } else {
      content = const Center(
        child: Icon(Icons.storefront_outlined, color: _C.sub, size: 32),
      );
    }
    return GestureDetector(
      onTap: _choisirLogo,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }

  Widget _input(TextEditingController c, String label,
      {TextInputType? keyboard, int maxLines = 1, String? Function(String)? verifier}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: (v) => (v == null || v.trim().isEmpty)
          ? '$label requis'
          : verifier?.call(v.trim()),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _C.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
