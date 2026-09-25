import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../data/services/panier_service.dart';
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';

class _C {
  static const green = Color(0xFF1B3A6B);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7F2);
  static const sub = Color(0xFF7A8473);
  static const border = Color(0xFFE3EAD0);
}

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CommandeBloc>(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();
  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  final _adresseCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _modeLivraison = 'livraison';
  String _modePaiement = 'en_ligne';
  String _methode = 'orange_money';

  final _panier = sl<PanierService>();

  @override
  void dispose() {
    _adresseCtrl.dispose();
    _telCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _soumettre(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<CommandeBloc>().add(CreerCommande(
          items: _panier.toApiItems(),
          modeLivraison: _modeLivraison,
          modePaiement: _modePaiement,
          adresseLivraison:
              _modeLivraison == 'livraison' ? _adresseCtrl.text.trim() : null,
          numeroTelephone: _telCtrl.text.trim(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        ));
  }

  Future<void> _ouvrirPaiement(String? url) async {
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
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
        title: const Text('Validation de la commande'),
      ),
      body: BlocConsumer<CommandeBloc, CommandeState>(
        listener: (context, state) async {
          if (state is CommandeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is CommandeCreee) {
            // Paiement à la livraison → terminé. En ligne → on lance le paiement.
            if (state.commande.modePaiement == 'a_la_livraison') {
              await _panier.vider();
              if (context.mounted) _allerMesCommandes(context);
            } else {
              context.read<CommandeBloc>().add(
                    PayerCommande(state.commande.id,
                        methode: _methode, numeroTelephone: _telCtrl.text.trim()),
                  );
            }
          } else if (state is PaiementInitie) {
            await _ouvrirPaiement(state.paymentUrl);
            await _panier.vider();
            if (context.mounted) _allerMesCommandes(context);
          }
        },
        builder: (context, state) {
          final loading = state is CommandeLoading;
          return AbsorbPointer(
            absorbing: loading,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section('Mode de réception'),
                  _choix(['livraison', 'retrait'], _modeLivraison,
                      {'livraison': 'Livraison', 'retrait': 'Retrait'},
                      (v) => setState(() => _modeLivraison = v)),
                  if (_modeLivraison == 'livraison') ...[
                    const SizedBox(height: 12),
                    _input(_adresseCtrl, 'Adresse de livraison',
                        validator: (v) => (_modeLivraison == 'livraison' &&
                                (v == null || v.trim().isEmpty))
                            ? 'Adresse requise'
                            : null),
                  ],
                  const SizedBox(height: 12),
                  _input(_telCtrl, 'Téléphone',
                      keyboard: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Téléphone requis'
                          : null),
                  const SizedBox(height: 20),
                  _section('Paiement'),
                  _choix(['en_ligne', 'a_la_livraison'], _modePaiement, {
                    'en_ligne': 'En ligne',
                    'a_la_livraison': 'À la livraison'
                  }, (v) => setState(() => _modePaiement = v)),
                  if (_modePaiement == 'en_ligne') ...[
                    const SizedBox(height: 12),
                    _choix(['orange_money', 'wave'], _methode, {
                      'orange_money': 'Orange Money',
                      'wave': 'Wave'
                    }, (v) => setState(() => _methode = v)),
                  ],
                  const SizedBox(height: 20),
                  _section('Note (optionnel)'),
                  _input(_noteCtrl, 'Une précision pour le vendeur ?',
                      maxLines: 3),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loading ? null : () => _soumettre(context),
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
                        : Text(
                            'Confirmer (${_panier.total.toStringAsFixed(0)} FCFA + livraison)',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _allerMesCommandes(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.mesCommandesRoute,
      (route) => route.isFirst,
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: _C.black, fontSize: 15)),
      );

  Widget _input(TextEditingController c, String hint,
      {TextInputType? keyboard,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: _C.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  Widget _choix(List<String> valeurs, String selected,
      Map<String, String> labels, ValueChanged<String> onSelect) {
    return Row(
      children: valeurs.map((v) {
        final sel = v == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelect(v),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? _C.green.withValues(alpha: 0.10) : _C.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? _C.green : _C.border),
                ),
                alignment: Alignment.center,
                child: Text(labels[v] ?? v,
                    style: TextStyle(
                        color: sel ? _C.green : _C.sub,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
