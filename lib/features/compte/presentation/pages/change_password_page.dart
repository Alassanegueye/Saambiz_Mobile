import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../bloc/compte_bloc.dart';
import '../bloc/compte_event.dart';
import '../bloc/compte_state.dart';

class _C {
  static const green = Color(0xFF0D1B3D);
  static const black = Color(0xFF0D1B3D);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const border = Color(0xFFE3E8F0);
}

/// PUT /account/change-password
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
  final _formKey = GlobalKey<FormState>();
  final _ancienCtrl = TextEditingController();
  final _nouveauCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _ancienCtrl.dispose();
    _nouveauCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _soumettre() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CompteBloc>().add(ChangePasswordRequested(
          ancienMotDePasse: _ancienCtrl.text,
          nouveauMotDePasse: _nouveauCtrl.text,
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
        title: const Text('Changer le mot de passe'),
      ),
      body: BlocConsumer<CompteBloc, CompteState>(
        listener: (context, state) {
          if (state is CompteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is CompteActionSucces ||
              state is CompteMessageSucces) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mot de passe modifié')),
            );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          final loading = state is CompteActionEnCours || state is CompteLoading;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _input(_ancienCtrl, 'Ancien mot de passe'),
                const SizedBox(height: 12),
                _input(_nouveauCtrl, 'Nouveau mot de passe'),
                const SizedBox(height: 12),
                _input(
                  _confirmCtrl,
                  'Confirmer le nouveau mot de passe',
                  validator: (v) => v != _nouveauCtrl.text
                      ? 'Les mots de passe ne correspondent pas'
                      : null,
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
                      : const Text('Confirmer',
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
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      obscureText: true,
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty) ? '$label requis' : null,
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
