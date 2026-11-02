import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart';
import '../bloc/promotions_bloc.dart';
import '../bloc/promotions_event.dart';
import '../bloc/promotions_state.dart';
import 'nouvelle_campagne_page.dart';
import 'promotion_form_page.dart';

class _C {
  static const green = Color(0xFF01154B);
  static const black = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F8);
  static const sub = Color(0xFF5B6C8A);
  static const border = Color(0xFFE3E8F0);
}

/// Promotions du vendeur connecté (GET/POST/PUT/DELETE /promotions).
class MesPromotionsPage extends StatelessWidget {
  const MesPromotionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PromotionsBloc>()..add(LoadMesPromotions()),
      child: const _MesPromotionsView(),
    );
  }
}

class _MesPromotionsView extends StatelessWidget {
  const _MesPromotionsView();

  Future<void> _ouvrirForm(BuildContext context, {dynamic promotion}) async {
    final bloc = context.read<PromotionsBloc>();
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PromotionFormPage(promotion: promotion),
      ),
    );
    if (res == true) bloc.add(LoadMesPromotions());
  }

  Future<void> _nouvelleCampagne(
    BuildContext context,
    TypeCampagne type,
  ) async {
    final bloc = context.read<PromotionsBloc>();
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NouvelleCampagnePage(type: type)),
    );
    if (res == true) bloc.add(LoadMesPromotions());
  }

  Widget _boutonsCreation(BuildContext context) {
    return Container(
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _nouvelleCampagne(context, TypeCampagne.promotion),
              icon: const Icon(Icons.local_offer_outlined, size: 18),
              label: const Text('Ajouter une promotion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                foregroundColor: _C.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  _nouvelleCampagne(context, TypeCampagne.information),
              icon: const Icon(Icons.campaign_outlined, size: 18),
              label: const Text('Informer mes clients'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.green,
                side: const BorderSide(color: _C.green),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: const Text('Mes promotions'),
      ),
      body: Column(
        children: [
          // Créer une promotion (remise sur des produits) ou informer ses
          // clients (boutique ouverte, nouveautés, message libre).
          _boutonsCreation(context),
          Expanded(
            child: BlocConsumer<PromotionsBloc, PromotionsState>(
              listener: (context, state) {
                if (state is PromotionsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is PromotionsLoading || state is PromotionsInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is PromotionsLoaded) {
                  if (state.promotions.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune promotion créée pour le moment',
                        style: TextStyle(color: _C.sub),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<PromotionsBloc>().add(LoadMesPromotions()),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: state.promotions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final p = state.promotions[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: _C.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.border),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.titre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _C.black,
                                      ),
                                    ),
                                    Text(
                                      '${p.prixPromo.toStringAsFixed(0)} FCFA',
                                      style: const TextStyle(
                                        color: _C.green,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (p.dateFin != null)
                                      Text(
                                        'Jusqu\'au ${DateFormat('dd/MM/yyyy').format(p.dateFin!)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _C.sub,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    _ouvrirForm(context, promotion: p);
                                  } else if (v == 'delete') {
                                    context.read<PromotionsBloc>().add(
                                      SupprimerPromotion(p.id),
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Modifier'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Supprimer'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
