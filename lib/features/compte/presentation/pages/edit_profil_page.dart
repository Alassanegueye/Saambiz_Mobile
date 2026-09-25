import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../injection_container.dart';
import '../../../auth/domain/entities/user.dart';
import '../bloc/compte_bloc.dart';
import '../bloc/compte_event.dart';
import '../bloc/compte_state.dart';

class _C {
  static const green = Color(0xFF1B3A6B);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7F2);
  static const sub = Color(0xFF7A8473);
  static const border = Color(0xFFE3EAD0);
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
  late final _prenomCtrl = TextEditingController(text: widget.user?.prenom ?? '');
  late final _adresseCtrl = TextEditingController(text: widget.user?.adresse ?? '');
  late final _telephoneCtrl = TextEditingController(text: widget.user?.telephone ?? '');
  String? _photoPath;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _adresseCtrl.dispose();
    _telephoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (x != null) setState(() => _photoPath = x.path);
  }

  void _soumettre() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CompteBloc>().add(ModifierProfilRequested(
          nom: _nomCtrl.text.trim(),
          prenom: _prenomCtrl.text.trim(),
          adresse: _adresseCtrl.text.trim(),
          telephone: _telephoneCtrl.text.trim(),
          photoProfilPath: _photoPath,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: const Text('Modifier le profil'),
      ),
      body: BlocConsumer<CompteBloc, CompteState>(
        listener: (context, state) {
          if (state is CompteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is CompteActionSucces) {
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
                Center(
                  child: GestureDetector(
                    onTap: _choisirPhoto,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: _C.green.withOpacity(0.15),
                      backgroundImage: _photoPath != null
                          ? null
                          : (widget.user?.photoProfil != null &&
                                  widget.user!.photoProfil!.isNotEmpty)
                              ? NetworkImage(widget.user!.photoProfil!)
                              : null,
                      child: const Icon(Icons.camera_alt_outlined, color: _C.green),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _input(_prenomCtrl, 'Prénom'),
                const SizedBox(height: 12),
                _input(_nomCtrl, 'Nom'),
                const SizedBox(height: 12),
                _input(_telephoneCtrl, 'Téléphone', keyboard: TextInputType.phone),
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
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Enregistrer',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _input(TextEditingController c, String label,
      {TextInputType? keyboard}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      validator: (v) => (v == null || v.trim().isEmpty) ? '$label requis' : null,
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
