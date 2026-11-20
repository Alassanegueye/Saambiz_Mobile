import 'package:saambiz/core/widgets/messages.dart';
import 'package:flutter/material.dart';
import 'package:saambiz/core/utils/email.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../../auth/presentation/signup/signup_kit.dart';
import '../bloc/compte_bloc.dart';
import '../bloc/compte_event.dart';
import '../bloc/compte_state.dart';
import 'reset_password_page.dart';

/// POST /account/forgot-password
///
/// On y arrive depuis l'écran de connexion : même présentation que lui
/// (en-tête bleu, carte blanche, champ à icône).
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CompteBloc>(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();
  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _emailCtrl = TextEditingController();
  String? _erreurEmail;

  @override
  void initState() {
    super.initState();
    // L'erreur s'efface dès qu'on corrige.
    _emailCtrl.addListener(() {
      if (_erreurEmail != null) setState(() => _erreurEmail = null);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _envoyer() {
    final email = _emailCtrl.text.trim();
    final erreur = verifierEmail(email);
    setState(() => _erreurEmail = erreur);
    if (erreur != null) return;
    context.read<CompteBloc>().add(ForgotPasswordRequested(email));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompteBloc, CompteState>(
      listener: (context, state) {
        if (state is CompteError) {
          afficherErreur(context, state.message);
        } else if (state is CompteMessageSucces) {
          afficherSucces(context, 'Code envoyé : consultez votre boîte e-mail');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ResetPasswordPage(email: _emailCtrl.text.trim()),
            ),
          );
        }
      },
      builder: (context, state) {
        final loading = state is CompteLoading;
        return SbPageAuth(
          icone: Icons.lock_reset_rounded,
          titre: 'Mot de passe oublié ?',
          sousTitre:
              'Recevez un code par e-mail pour choisir un nouveau mot de passe.',
          carte: [
            SbField(
              obligatoire: true,
              label: 'E-mail',
              hint: 'exemple@mail.com',
              icon: Icons.mail_outline_rounded,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHint: AutofillHints.email,
              formatters: formatsEmail,
              errorText: _erreurEmail,
              onSubmitted: (_) => _envoyer(),
            ),
            const SizedBox(height: 20),
            SbPrimaryButton(
              label: 'Recevoir le code',
              icon: Icons.arrow_forward_rounded,
              loading: loading,
              onPressed: _envoyer,
            ),
          ],
        );
      },
    );
  }
}
