import 'package:saambiz/core/widgets/libelle_obligatoire.dart';
import 'package:flutter/material.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/features/commande/presentation/widgets/commande_card.dart'
    show montantFcfa;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../data/services/panier_service.dart';
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';

class _C {
  static const green = Color(0xFF01154B);
  static const black = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F8);
  static const sub = Color(0xFF5B6C8A);
  static const border = Color(0xFFE3E8F0);
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
    context.read<CommandeBloc>().add(
      CreerCommande(
        items: _panier.toApiItems(),
        modeLivraison: _modeLivraison,
        modePaiement: _modePaiement,
        adresseLivraison: _modeLivraison == 'livraison'
            ? _adresseCtrl.text.trim()
            : null,
        numeroTelephone: _telCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(title: const Text('Validation de la commande')),
      body: BlocConsumer<CommandeBloc, CommandeState>(
        listener: (context, state) async {
          if (state is CommandeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is CommandeCreee) {
            // Le client paie plus tard, une fois la commande acceptée.
            await _panier.vider();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.commande.modePaiement == 'en_ligne'
                      ? 'Commande envoyée. Vous pourrez la payer dès que le vendeur l\'aura acceptée.'
                      : 'Commande envoyée au vendeur.',
                ),
              ),
            );
            _allerMesCommandes(context);
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
                  _choix(
                    ['livraison', 'retrait'],
                    _modeLivraison,
                    {
                      'livraison': (Icons.local_shipping_outlined, 'Livraison'),
                      'retrait': (Icons.storefront_outlined, 'Retrait'),
                    },
                    (v) => setState(() => _modeLivraison = v),
                  ),
                  if (_modeLivraison == 'livraison') ...[
                    const SizedBox(height: 12),
                    _input(
                      _adresseCtrl,
                      'Adresse de livraison',
                      obligatoire: true,
                      validator: (v) =>
                          (_modeLivraison == 'livraison' &&
                              (v == null || v.trim().isEmpty))
                          ? 'Adresse requise'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _input(
                    _telCtrl,
                    'Téléphone',
                    obligatoire: true,
                    keyboard: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Téléphone requis'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _section('Paiement'),
                  _choix(
                    ['en_ligne', 'a_la_livraison'],
                    _modePaiement,
                    {
                      'en_ligne': (
                        Icons.phone_iphone_rounded,
                        'Wave ou Orange Money',
                      ),
                      'a_la_livraison': (
                        Icons.payments_outlined,
                        'À la réception',
                      ),
                    },
                    (v) => setState(() => _modePaiement = v),
                  ),
                  if (_modePaiement == 'en_ligne')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Vous paierez une fois la commande acceptée par le vendeur.',
                        style: TextStyle(fontSize: 12.5, color: _C.sub),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _section('Note (optionnel)'),
                  _input(
                    _noteCtrl,
                    'Une précision pour le vendeur ?',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loading ? null : () => _soumettre(context),
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
                        : Text(
                            _modeLivraison == 'livraison'
                                ? 'Confirmer · ${montantFcfa(_panier.total)} + livraison'
                                : 'Confirmer · ${montantFcfa(_panier.total)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
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
    child: Text(
      t,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: _C.black,
        fontSize: 15,
      ),
    ),
  );

  Widget _input(
    TextEditingController c,
    String hint, {
    bool obligatoire = false,
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: obligatoire ? null : hint,
        label: obligatoire ? LibelleObligatoire(hint) : null,
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

  Widget _choix(
    List<String> valeurs,
    String selected,
    Map<String, (IconData, String)> options,
    ValueChanged<String> onSelect,
  ) {
    return Row(
      children: [
        for (var i = 0; i < valeurs.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _option(valeurs[i], selected, options, onSelect)),
        ],
      ],
    );
  }

  Widget _option(
    String v,
    String selected,
    Map<String, (IconData, String)> options,
    ValueChanged<String> onSelect,
  ) {
    final sel = v == selected;
    final (icone, libelle) = options[v]!;
    return Material(
      color: sel ? AppColor.kPrimaryLight : _C.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: sel ? _C.green : _C.border,
          width: sel ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onSelect(v),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icone, size: 22, color: sel ? _C.green : _C.sub),
              const SizedBox(height: 6),
              Text(
                libelle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: sel ? _C.green : _C.sub,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
