import 'package:saambiz/core/widgets/page_vendeur.dart';
import 'package:saambiz/core/widgets/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/theme/police.dart';

import '../../../../injection_container.dart';
import '../../../auth/presentation/signup/signup_kit.dart';
import '../../../auth/presentation/widgets/mise_en_page_auth.dart'
    show CarteAuth;
import '../bloc/compte_bloc.dart';
import '../bloc/compte_event.dart';
import '../bloc/compte_state.dart';

/// PUT /account/change-password
///
/// Dans l'application (Compte → Sécurité) : la barre bleue des pages du
/// compte, puis les trois champs avec leur œil, les règles du serveur sous
/// le nouveau mot de passe et une coche quand la confirmation correspond.
/// On tapait trois mots de passe à l'aveugle, sans savoir ce qui était
/// exigé.
class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CompteBloc>(),
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();
  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  final _actuelCtrl = TextEditingController();
  final _nouveauCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _erreurActuel;
  String? _erreurNouveau;
  String? _erreurConfirm;

  @override
  void initState() {
    super.initState();
    // Chaque erreur s'efface dès qu'on corrige son champ.
    _actuelCtrl.addListener(() {
      if (_erreurActuel != null) setState(() => _erreurActuel = null);
    });
    _nouveauCtrl.addListener(() {
      if (_erreurNouveau != null) setState(() => _erreurNouveau = null);
    });
    _confirmCtrl.addListener(() {
      if (_erreurConfirm != null) setState(() => _erreurConfirm = null);
    });
  }

  @override
  void dispose() {
    _actuelCtrl.dispose();
    _nouveauCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _soumettre() {
    final actuel = _actuelCtrl.text;
    final nouveau = _nouveauCtrl.text;
    setState(() {
      _erreurActuel = actuel.isEmpty
          ? 'Saisissez votre mot de passe actuel.'
          : null;
      _erreurNouveau = validateMotDePasse(nouveau);
      _erreurConfirm = _confirmCtrl.text != nouveau
          ? 'Les mots de passe ne correspondent pas.'
          : null;
    });
    if (_erreurActuel != null ||
        _erreurNouveau != null ||
        _erreurConfirm != null) {
      return;
    }
    context.read<CompteBloc>().add(
      ChangePasswordRequested(
        ancienMotDePasse: actuel,
        nouveauMotDePasse: nouveau,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMarine(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: const Text('Changer le mot de passe')),
      body: BlocConsumer<CompteBloc, CompteState>(
        listener: (context, state) {
          if (state is CompteError) {
            afficherErreur(context, state.message);
          } else if (state is CompteActionSucces ||
              state is CompteMessageSucces) {
            afficherSucces(context, 'Mot de passe modifié avec succès');
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          final loading =
              state is CompteActionEnCours || state is CompteLoading;
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: AppColor.kGrayscale40,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saisissez d’abord votre mot de passe actuel, puis '
                        'le nouveau.',
                        style: TextStyle(
                          fontFamily: kPolice,
                          fontSize: 13,
                          height: 1.4,
                          color: AppColor.kGrayscale40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CarteAuth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SbChampMotDePasse(
                      label: 'Mot de passe actuel',
                      hint: 'Votre mot de passe actuel',
                      controller: _actuelCtrl,
                      autofillHint: AutofillHints.password,
                      errorText: _erreurActuel,
                    ),
                    const SizedBox(height: 16),
                    SbChampMotDePasse(
                      label: 'Nouveau mot de passe',
                      hint: 'Votre nouveau mot de passe',
                      icon: Icons.lock_reset_rounded,
                      controller: _nouveauCtrl,
                      autofillHint: AutofillHints.newPassword,
                      errorText: _erreurNouveau,
                    ),
                    const SizedBox(height: 14),
                    SbReglesMotDePasse(controller: _nouveauCtrl),
                    const SizedBox(height: 8),
                    SbChampMotDePasse(
                      label: 'Confirmer le nouveau mot de passe',
                      hint: 'Le même, une seconde fois',
                      icon: Icons.lock_reset_rounded,
                      controller: _confirmCtrl,
                      textInputAction: TextInputAction.done,
                      autofillHint: AutofillHints.newPassword,
                      errorText: _erreurConfirm,
                      onSubmitted: (_) => _soumettre(),
                    ),
                    _Correspondance(
                      nouveau: _nouveauCtrl,
                      confirmation: _confirmCtrl,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SbPrimaryButton(
                label: 'Enregistrer le nouveau mot de passe',
                loading: loading,
                onPressed: _soumettre,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// La coche verte sous la confirmation, dès qu'elle reprend le nouveau mot
/// de passe. Rien tant qu'elle est vide ou différente : l'erreur vient à
/// l'envoi, pas à chaque lettre.
class _Correspondance extends StatelessWidget {
  final TextEditingController nouveau;
  final TextEditingController confirmation;
  const _Correspondance({required this.nouveau, required this.confirmation});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([nouveau, confirmation]),
      builder: (context, _) {
        final identiques =
            confirmation.text.isNotEmpty && confirmation.text == nouveau.text;
        if (!identiques) return const SizedBox.shrink();
        return const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 18, color: Sb.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Les deux mots de passe sont identiques',
                  style: TextStyle(
                    fontFamily: kPolice,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Sb.navy,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
