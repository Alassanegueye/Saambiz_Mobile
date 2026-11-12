import 'package:saambiz/core/widgets/champ_code.dart';
import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/libelle_obligatoire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../bloc/compte_bloc.dart';
import '../bloc/compte_event.dart';
import '../bloc/compte_state.dart';

class _C {
  static const green = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F8);
  static const border = Color(0xFFE3E8F0);
}

/// POST /account/reset-password
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
  final _formKey = GlobalKey<FormState>();
  final _nouveauCtrl = TextEditingController();
  String _code = '';
  String? _erreurCode;

  @override
  void dispose() {
    _nouveauCtrl.dispose();
    super.dispose();
  }

  void _confirmer() {
    final codeOk = _code.length == 6;
    setState(
      () => _erreurCode = codeOk ? null : 'Saisissez les 6 chiffres du code.',
    );
    final formOk = _formKey.currentState!.validate();
    if (!codeOk || !formOk) return;
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
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(title: const Text('Réinitialiser le mot de passe')),
      body: BlocConsumer<CompteBloc, CompteState>(
        listener: (context, state) {
          if (state is CompteError) {
            afficherErreur(context, state.message);
          } else if (state is CompteMessageSucces) {
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
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Code envoyé à ${widget.email}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5568),
                  ),
                ),
                const SizedBox(height: 14),
                const LibelleObligatoire(
                  'Code à 6 chiffres',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.green,
                  ),
                ),
                const SizedBox(height: 8),
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
                      fontSize: 12,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nouveauCtrl,
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Au moins 6 caractères'
                      : null,
                  decoration: _decoration('Nouveau mot de passe'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: loading ? null : _confirmer,
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
                          'Réinitialiser',
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

  InputDecoration _decoration(String label) => InputDecoration(
    label: LibelleObligatoire(label),
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
  );
}
