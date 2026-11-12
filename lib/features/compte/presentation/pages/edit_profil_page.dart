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

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/police.dart';
import '../../../../core/widgets/page_vendeur.dart';
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

  String get _initiales {
    final p = _prenomCtrl.text.trim();
    final n = _nomCtrl.text.trim();
    final i = '${p.isNotEmpty ? p[0] : ''}${n.isNotEmpty ? n[0] : ''}';
    return i.isEmpty ? '?' : i.toUpperCase();
  }

  /// La photo tout juste choisie, sinon la photo actuelle, sinon les
  /// initiales. Le petit appareil photo dit qu'on peut en changer.
  Widget _avatar() {
    final actuelle = widget.user?.photoProfil;
    final ImageProvider? image = _photoPath != null
        ? FileImage(File(_photoPath!))
        : (actuelle != null && actuelle.isNotEmpty)
        ? fournisseurImageReseau(actuelle)
        : null;
    return Semantics(
      button: true,
      label: 'Changer la photo de profil',
      child: GestureDetector(
        onTap: _choisirPhoto,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.kSecondary,
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: _C.white,
                backgroundImage: image,
                child: image == null
                    ? Text(
                        _initiales,
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: _C.green,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _C.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.white, width: 3),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  size: 16,
                  color: _C.white,
                ),
              ),
            ),
          ],
        ),
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
    final email = (widget.user?.email ?? '').trim();
    return ScaffoldMarine(
      backgroundColor: _C.bg,
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: BlocConsumer<CompteBloc, CompteState>(
        listener: (context, state) {
          if (state is CompteError) {
            afficherErreur(context, state.message);
          } else if (state is CompteActionSucces) {
            afficherSucces(
              context,
              'Vos informations ont été enregistrées.',
              titre: 'Profil mis à jour',
            );
            Navigator.of(context).pop(state.user);
          }
        },
        builder: (context, state) {
          final loading = state is CompteActionEnCours;
          return Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    children: [
                      Center(child: _avatar()),
                      const SizedBox(height: 6),
                      Center(
                        child: TextButton(
                          onPressed: _choisirPhoto,
                          child: const Text(
                            'Changer la photo',
                            style: TextStyle(
                              fontFamily: kPolice,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _C.green,
                            ),
                          ),
                        ),
                      ),
                      if (email.isNotEmpty)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.kPrimaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.mail_outline_rounded,
                                  size: 15,
                                  color: _C.green,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: kPolice,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _C.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _Groupe(
                        titre: 'Informations personnelles',
                        champs: [
                          _champ(
                            _prenomCtrl,
                            'Prénom',
                            Icons.person_outline_rounded,
                            majuscules: true,
                          ),
                          _champ(
                            _nomCtrl,
                            'Nom',
                            Icons.badge_outlined,
                            majuscules: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _Groupe(
                        titre: 'Coordonnées',
                        champs: [
                          _champ(
                            _telephoneCtrl,
                            'Téléphone',
                            null,
                            keyboard: TextInputType.phone,
                            verifier: (v) =>
                                verifierTelephone(v, _paysTel.value),
                            formats: [FormatTelephone(_paysTel)],
                            prefixe: BoutonIndicatif(
                              pays: _paysTel,
                              onChange: () => setState(_telephoneCtrl.clear),
                            ),
                          ),
                          _champ(
                            _adresseCtrl,
                            'Adresse',
                            Icons.location_on_outlined,
                            aide: 'Quartier et ville, pour vos livraisons',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: const BoxDecoration(
                    color: _C.white,
                    boxShadow: [
                      BoxShadow(color: Color(0x12000000), blurRadius: 16),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: loading ? null : _soumettre,
                        style: FilledButton.styleFrom(
                          backgroundColor: _C.green,
                          foregroundColor: _C.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
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
                            : const Text('Enregistrer'),
                      ),
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

  /// Un champ : libellé au-dessus, icône à gauche, fond gris clair.
  Widget _champ(
    TextEditingController c,
    String label,
    IconData? icone, {
    TextInputType? keyboard,
    String? Function(String)? verifier,
    List<TextInputFormatter>? formats,
    Widget? prefixe,
    String? aide,
    bool majuscules = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LibelleObligatoire(
          label,
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: _C.green,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          keyboardType: keyboard,
          inputFormatters: formats,
          textCapitalization: majuscules
              ? TextCapitalization.words
              : TextCapitalization.sentences,
          // Les initiales de l'avatar suivent le prénom et le nom.
          onChanged: majuscules ? (_) => setState(() {}) : null,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? '$label requis'
              : verifier?.call(v.trim()),
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B1F27),
          ),
          decoration: InputDecoration(
            prefixIcon:
                prefixe ??
                (icone == null
                    ? null
                    : Icon(icone, size: 20, color: const Color(0xFF8A93A6))),
            helperText: aide,
            helperStyle: const TextStyle(fontFamily: kPolice, fontSize: 12),
            filled: true,
            fillColor: _C.bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _C.green, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColor.kErreur),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColor.kErreur, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Une carte blanche titrée qui regroupe des champs.
class _Groupe extends StatelessWidget {
  final String titre;
  final List<Widget> champs;
  const _Groupe({required this.titre, required this.champs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            titre.toUpperCase(),
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColor.kGrayscale40,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < champs.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                champs[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
