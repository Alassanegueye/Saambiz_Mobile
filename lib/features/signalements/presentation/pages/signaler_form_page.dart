import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../bloc/signalements_bloc.dart';
import '../bloc/signalements_event.dart';
import '../bloc/signalements_state.dart';

class _C {
  static const green = Color(0xFF1B3A6B);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7F2);
  static const border = Color(0xFFE3EAD0);
}

/// Formulaire générique de signalement (POST /signalements) — utilisable
/// pour signaler un produit ou une boutique.
class SignalerFormPage extends StatelessWidget {
  final String type; // 'produit' | 'boutique'
  final String cibleId;
  const SignalerFormPage({super.key, required this.type, required this.cibleId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SignalementsBloc>(),
      child: _SignalerFormView(type: type, cibleId: cibleId),
    );
  }
}

class _SignalerFormView extends StatefulWidget {
  final String type;
  final String cibleId;
  const _SignalerFormView({required this.type, required this.cibleId});
  @override
  State<_SignalerFormView> createState() => _SignalerFormViewState();
}

class _SignalerFormViewState extends State<_SignalerFormView> {
  final _formKey = GlobalKey<FormState>();
  final _raisonCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _raisonCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _envoyer() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SignalementsBloc>().add(CreerSignalement(
          type: widget.type,
          raison: _raisonCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          cibleId: widget.cibleId,
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
        title: Text(
            widget.type == 'boutique' ? 'Signaler cette boutique' : 'Signaler ce produit'),
      ),
      body: BlocConsumer<SignalementsBloc, SignalementsState>(
        listener: (context, state) {
          if (state is SignalementsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is SignalementEnvoye) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Signalement envoyé, merci.')),
            );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          final loading = state is SignalementsLoading;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _raisonCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Raison requise' : null,
                  decoration: const InputDecoration(labelText: 'Raison'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Description requise' : null,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: loading ? null : _envoyer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
                      : const Text('Envoyer le signalement',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
