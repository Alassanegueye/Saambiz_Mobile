import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart';
import '../bloc/promotions_bloc.dart';
import '../bloc/promotions_event.dart';
import '../bloc/promotions_state.dart';
import 'promotion_form_page.dart';

class _C {
  static const green = Color(0xFF0D1B3D);
  static const black = Color(0xFF0D1B3D);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
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
      MaterialPageRoute(builder: (_) => PromotionFormPage(promotion: promotion)),
    );
    if (res == true) bloc.add(LoadMesPromotions());
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _C.green,
        foregroundColor: _C.white,
        onPressed: () => _ouvrirForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Créer'),
      ),
      body: BlocConsumer<PromotionsBloc, PromotionsState>(
        listener: (context, state) {
          if (state is PromotionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
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
                child: Text('Aucune promotion créée pour le moment',
                    style: TextStyle(color: _C.sub)),
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
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _C.border),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.titre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, color: _C.black)),
                              Text('${p.prixPromo.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                      color: _C.green, fontWeight: FontWeight.w700)),
                              if (p.dateFin != null)
                                Text(
                                    'Jusqu\'au ${DateFormat('dd/MM/yyyy').format(p.dateFin!)}',
                                    style:
                                        const TextStyle(fontSize: 11, color: _C.sub)),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') {
                              _ouvrirForm(context, promotion: p);
                            } else if (v == 'delete') {
                              context
                                  .read<PromotionsBloc>()
                                  .add(SupprimerPromotion(p.id));
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Modifier')),
                            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
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
    );
  }
}
