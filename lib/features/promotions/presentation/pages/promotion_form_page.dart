import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart';
import '../../../home/data/models/produit_model.dart';
import '../../../vendeur/data/datasources/vendeur_produit_datasource.dart';
import '../../data/models/promotion_model.dart';
import '../bloc/promotions_bloc.dart';
import '../bloc/promotions_event.dart';
import '../bloc/promotions_state.dart';

class _C {
  static const green = Color(0xFF1B3A6B);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7F2);
  static const sub = Color(0xFF7A8473);
  static const border = Color(0xFFE3EAD0);
}

/// Création (POST /promotions) ou modification (PUT /promotions/:id) d'une
/// promotion vendeur.
class PromotionFormPage extends StatelessWidget {
  final PromotionModel? promotion; // null = création
  const PromotionFormPage({super.key, this.promotion});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PromotionsBloc>(),
      child: _PromotionFormView(promotion: promotion),
    );
  }
}

class _PromotionFormView extends StatefulWidget {
  final PromotionModel? promotion;
  const _PromotionFormView({this.promotion});
  @override
  State<_PromotionFormView> createState() => _PromotionFormViewState();
}

class _PromotionFormViewState extends State<_PromotionFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _titreCtrl = TextEditingController(text: widget.promotion?.titre ?? '');
  late final _descCtrl =
      TextEditingController(text: widget.promotion?.description ?? '');
  late final _prixCtrl = TextEditingController(
      text: widget.promotion != null ? widget.promotion!.prixPromo.toString() : '');
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 7));
  String? _produitId;
  List<ProduitModel> _produits = [];
  bool _loadingProduits = true;

  bool get _isEdit => widget.promotion != null;

  @override
  void initState() {
    super.initState();
    if (widget.promotion?.dateDebut != null) _dateDebut = widget.promotion!.dateDebut!;
    if (widget.promotion?.dateFin != null) _dateFin = widget.promotion!.dateFin!;
    _produitId = widget.promotion?.produitId;
    _chargerProduits();
  }

  Future<void> _chargerProduits() async {
    try {
      final produits = await sl<VendeurProduitDataSource>().mesProduits();
      setState(() {
        _produits = produits;
        _loadingProduits = false;
      });
    } catch (_) {
      setState(() => _loadingProduits = false);
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _prixCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDate({required bool debut}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: debut ? _dateDebut : _dateFin,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (debut) {
          _dateDebut = date;
        } else {
          _dateFin = date;
        }
      });
    }
  }

  void _soumettre() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && (_produitId == null || _produitId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez un produit')),
      );
      return;
    }
    final bloc = context.read<PromotionsBloc>();
    final isoDebut = DateFormat('yyyy-MM-dd').format(_dateDebut);
    final isoFin = DateFormat('yyyy-MM-dd').format(_dateFin);
    final prix = num.tryParse(_prixCtrl.text.trim()) ?? 0;
    if (_isEdit) {
      bloc.add(ModifierPromotion(
        widget.promotion!.id,
        titre: _titreCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        prixPromo: prix,
        dateDebut: isoDebut,
        dateFin: isoFin,
      ));
    } else {
      bloc.add(CreerPromotion(
        titre: _titreCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        prixPromo: prix,
        dateDebut: isoDebut,
        dateFin: isoFin,
        produitId: _produitId!,
      ));
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
        title: Text(_isEdit ? 'Modifier la promotion' : 'Nouvelle promotion'),
      ),
      body: BlocConsumer<PromotionsBloc, PromotionsState>(
        listener: (context, state) {
          if (state is PromotionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is PromotionsLoaded) {
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          final loading = state is PromotionsLoading;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!_isEdit) ...[
                  _loadingProduits
                      ? const LinearProgressIndicator()
                      : DropdownButtonFormField<String>(
                          initialValue: _produitId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Produit'),
                          items: _produits
                              .map((p) =>
                                  DropdownMenuItem(value: p.id, child: Text(p.nom)))
                              .toList(),
                          onChanged: (v) => setState(() => _produitId = v),
                        ),
                  const SizedBox(height: 12),
                ],
                _input(_titreCtrl, 'Titre de la promotion'),
                const SizedBox(height: 12),
                _input(_descCtrl, 'Description', maxLines: 3),
                const SizedBox(height: 12),
                _input(_prixCtrl, 'Prix promo (FCFA)',
                    keyboard: TextInputType.number),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _choisirDate(debut: true),
                        child: Text(
                            'Début : ${DateFormat('dd/MM/yyyy').format(_dateDebut)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _choisirDate(debut: false),
                        child:
                            Text('Fin : ${DateFormat('dd/MM/yyyy').format(_dateFin)}'),
                      ),
                    ),
                  ],
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
                      : Text(_isEdit ? 'Enregistrer' : 'Créer la promotion',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _input(TextEditingController c, String label,
      {TextInputType? keyboard, int maxLines = 1}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: (v) => (v == null || v.trim().isEmpty) ? '$label requis' : null,
      decoration: InputDecoration(labelText: label),
    );
  }
}
