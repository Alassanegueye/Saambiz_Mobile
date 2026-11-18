import 'dart:async';

import 'package:saambiz/core/widgets/champ_code.dart';
import 'package:saambiz/core/widgets/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/police.dart';

import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../../auth/presentation/signup/signup_kit.dart';
import '../../../auth/presentation/widgets/mise_en_page_auth.dart'
    show LibelleChamp;
import '../bloc/compte_bloc.dart';
import '../bloc/compte_event.dart';
import '../bloc/compte_state.dart';

/// POST /account/reset-password
///
/// Le code reçu par e-mail, puis le nouveau mot de passe : avec son œil et
/// les quatre règles du serveur, cochées pendant la frappe. L'écran disait
/// « Au moins 6 caractères » alors que le serveur en exige 8, avec une
/// majuscule, un chiffre et un caractère spécial : un mot de passe accepté
/// ici était refusé à l'envoi.
class ResetPasswordPage extends StatelessWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CompteBloc>(),
      child: _ResetPasswordView(email: email),
    );
  }
}

class _ResetPasswordView extends StatefulWidget {
  final String email;
  const _ResetPasswordView({required this.email});
  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  /// Attente avant de pouvoir redemander un code, comme à l'inscription.
  static const _attente = 30;

  final _nouveauCtrl = TextEditingController();
  String _code = '';
  String? _erreurCode;
  String? _erreurMdp;

  int _secondes = _attente;
  Timer? _minuteur;

  /// Vrai pendant un renvoi du code : son succès ne doit pas être pris pour
  /// celui de la réinitialisation (même bloc, même état de succès).
  bool _renvoi = false;

  @override
  void initState() {
    super.initState();
    // Un code vient d'être envoyé : le renvoi attend comme après un envoi.
    _lancerAttente();
    _nouveauCtrl.addListener(() {
      if (_erreurMdp != null) setState(() => _erreurMdp = null);
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _nouveauCtrl.dispose();
    super.dispose();
  }

  void _lancerAttente() {
    _minuteur?.cancel();
    _secondes = _attente;
    _minuteur = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondes--);
      if (_secondes <= 0) t.cancel();
    });
  }

  void _renvoyer() {
    _renvoi = true;
    context.read<CompteBloc>().add(ForgotPasswordRequested(widget.email));
  }

  void _confirmer() {
    final codeOk = _code.length == 6;
    final erreurMdp = validateMotDePasse(_nouveauCtrl.text);
    setState(() {
      _erreurCode = codeOk ? null : 'Saisissez les 6 chiffres du code.';
      _erreurMdp = erreurMdp;
    });
    if (!codeOk || erreurMdp != null) return;
    _renvoi = false;
    context.read<CompteBloc>().add(
      ResetPasswordRequested(
        email: widget.email,
        code: _code,
        nouveauMotDePasse: _nouveauCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompteBloc, CompteState>(
      listener: (context, state) {
        if (state is CompteError) {
          _renvoi = false;
          afficherErreur(context, state.message);
        } else if (state is CompteMessageSucces) {
          if (_renvoi) {
            _renvoi = false;
            afficherSucces(context, 'Nouveau code envoyé à ${widget.email}');
            setState(_lancerAttente);
            return;
          }
          afficherSucces(
            context,
            'Mot de passe réinitialisé : connectez-vous avec le nouveau',
          );
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
        }
      },
      builder: (context, state) {
        final loading = state is CompteLoading;
        return SbPageAuth(
          icone: Icons.password_rounded,
          titre: 'Nouveau mot de passe',
          sousTitre: 'Code envoyé à ${widget.email}',
          carte: [
            const LibelleChamp('Code à 6 chiffres', obligatoire: true),
            ChampCode(
              autofocus: true,
              erreur: _erreurCode != null,
              onChanged: (code) {
                _code = code;
                if (_erreurCode != null) {
                  setState(() => _erreurCode = null);
                }
              },
            ),
            if (_erreurCode != null) ...[
              const SizedBox(height: 6),
              Text(
                _erreurCode!,
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 12,
                  color: Sb.error,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SbChampMotDePasse(
              label: 'Nouveau mot de passe',
              hint: 'Votre nouveau mot de passe',
              controller: _nouveauCtrl,
              textInputAction: TextInputAction.done,
              autofillHint: AutofillHints.newPassword,
              errorText: _erreurMdp,
              onSubmitted: (_) => _confirmer(),
            ),
            const SizedBox(height: 14),
            SbReglesMotDePasse(controller: _nouveauCtrl),
            const SizedBox(height: 12),
            SbPrimaryButton(
              label: 'Changer mon mot de passe',
              loading: loading && !_renvoi,
              onPressed: loading ? null : _confirmer,
            ),
            const SizedBox(height: 12),
            // Si l'e-mail n'est pas arrivé : il fallait revenir à l'écran
            // précédent pour en demander un autre.
            Center(
              child: loading && _renvoi
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : _secondes > 0
                  ? Text(
                      'Renvoyer le code dans $_secondes s',
                      style: Sb.body(13),
                    )
                  : TextButton(
                      onPressed: loading ? null : _renvoyer,
                      child: const Text(
                        'Renvoyer le code',
                        style: TextStyle(
                          fontFamily: kPolice,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Sb.navy,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
