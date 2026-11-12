import 'package:saambiz/core/widgets/messages.dart';
import 'dart:io';
import 'package:saambiz/core/widgets/image_reseau.dart';

import 'package:saambiz/core/widgets/libelle_obligatoire.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saambiz/core/utils/telephone.dart';
import 'package:saambiz/core/widgets/bouton_indicatif.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../injection_container.dart';
import '../../../auth/domain/entities/user.dart';
import '../bloc/compte_bloc.dart';
import '../bloc/compte_event.dart';
import '../bloc/compte_state.dart';

class _C {
  static const green = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F8);
  static const border = Color(0xFFE3E8F0);
}

/// Édition du profil (PUT /account/modifier-profil).
class EditProfilePage extends StatelessWidget {
  final User? user;
  const EditProfilePage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CompteBloc>(),
      child: _EditProfileView(user: user),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  final User? user;
  const _EditProfileView({this.user});

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final _nomCtrl = TextEditingController(text: widget.user?.nom ?? '');
  late final _prenomCtrl = TextEditingController(
    text: widget.user?.prenom ?? '',
  );
  late final _adresseCtrl = TextEditingController(
    text: widget.user?.adresse ?? '',
  );
  // Le numéro enregistré (« +221771234567 ») est découpé en pays + numéro.
  late final _telLu = lireTelephone(widget.user?.telephone ?? '');
  late final _telephoneCtrl = TextEditingController(text: _telLu.national);
  late final _paysTel = ValueNotifier<PaysTelephone>(_telLu.pays);
  String? _photoPath;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _adresseCtrl.dispose();
    _telephoneCtrl.dispose();
    _paysTel.dispose();
    super.dispose();
  }

  Future<void> _choisirPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (x != null) setState(() => _photoPath = x.path);
  }

  /// La photo tout juste choisie, sinon la photo actuelle, sinon une icône.
  /// Le petit appareil photo reste visible : il dit qu'on peut en changer.
  Widget _avatar() {
    final actuelle = widget.user?.photoProfil;
    final ImageProvider? image = _photoPath != null
        ? FileImage(File(_photoPath!))
        : (actuelle != null && actuelle.isNotEmpty)
        ? fournisseurImageReseau(actuelle)
        : null;
    return GestureDetector(
      onTap: _choisirPhoto,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: _C.green.withValues(alpha: 0.15),
            backgroundImage: image,
            child: image == null
                ? const Icon(Icons.person_outline_rounded, color: _C.green)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _C.green,
                shape: BoxShape.circle,
                border: Border.all(color: _C.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 14,
                color: _C.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _soumettre() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CompteBloc>().add(
      ModifierProfilRequested(
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        adresse: _adresseCtrl.text.trim(),
        telephone: telephoneInternational(_telephoneCtrl.text, _paysTel.value),
        photoProfilPath: _photoPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: BlocConsumer<CompteBloc, CompteState>(
        listener: (context, state) {
          if (state is CompteError) {
            afficherErreur(context, state.message);
          } else if (state is CompteActionSucces) {
            afficherSucces(context, 'Profil mis à jour avec succès');
            Navigator.of(context).pop(state.user);
          }
        },
        builder: (context, state) {
          final loading = state is CompteActionEnCours;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(child: _avatar()),
                const SizedBox(height: 20),
                _input(_prenomCtrl, 'Prénom'),
                const SizedBox(height: 12),
                _input(_nomCtrl, 'Nom'),
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
                const SizedBox(height: 12),
                _input(_adresseCtrl, 'Adresse'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: loading ? null : _soumettre,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.green,
                    foregroundColor: _C.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      : const Text(
                          'Enregistrer',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String label, {
    TextInputType? keyboard,
    String? Function(String)? verifier,
    List<TextInputFormatter>? formats,
    Widget? prefixe,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
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
