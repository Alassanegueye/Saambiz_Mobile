import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart';
import '../bloc/promotions_bloc.dart';
import '../bloc/promotions_event.dart';
import '../bloc/promotions_state.dart';
import 'package:saambiz/core/utils/image_url.dart';

class _C {
  static const green = Color(0xFF0D1B3D);
  static const black = Color(0xFF0D1B3D);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF5B6C8A);
  static const border = Color(0xFFE3E8F0);
}

/// Promotions actives, publiques (GET /promotions/actives) — affichées côté
/// accueil acheteur.
class PromotionsActivesPage extends StatelessWidget {
  const PromotionsActivesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PromotionsBloc>()..add(LoadPromotionsActives()),
      child: const _PromotionsActivesView(),
    );
  }
}

class _PromotionsActivesView extends StatelessWidget {
  const _PromotionsActivesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: const Text('Promotions'),
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
                child: Text('Aucune promotion active pour le moment',
                    style: TextStyle(color: _C.sub)),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<PromotionsBloc>().add(LoadPromotionsActives()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (p.produitImage ?? '').isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageOptimisee(p.produitImage!),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover)
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: _C.bg,
                                  child: const Icon(Icons.local_offer_outlined,
                                      color: _C.sub)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.titre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, color: _C.black)),
                              Text(p.produitNom ?? '',
                                  style: const TextStyle(color: _C.sub, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('${p.prixPromo.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                      color: _C.green,
                                      fontWeight: FontWeight.w700)),
                              if (p.dateFin != null)
                                Text(
                                    'Jusqu\'au ${DateFormat('dd/MM/yyyy').format(p.dateFin!)}',
                                    style:
                                        const TextStyle(fontSize: 11, color: _C.sub)),
                            ],
                          ),
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
