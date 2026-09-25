import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart';
import '../bloc/signalements_bloc.dart';
import '../bloc/signalements_event.dart';
import '../bloc/signalements_state.dart';

class _C {
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7F2);
  static const sub = Color(0xFF7A8473);
  static const border = Color(0xFFE3EAD0);
  static const orange = Color(0xFFFF8F00);
}

/// Signalements envoyés par l'utilisateur connecté (GET /signalements/mes-signalements).
class MesSignalementsPage extends StatelessWidget {
  const MesSignalementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SignalementsBloc>()..add(LoadMesSignalements()),
      child: const _MesSignalementsView(),
    );
  }
}

class _MesSignalementsView extends StatelessWidget {
  const _MesSignalementsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: const Text('Mes signalements'),
      ),
      body: BlocConsumer<SignalementsBloc, SignalementsState>(
        listener: (context, state) {
          if (state is SignalementsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is SignalementsLoading || state is SignalementsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SignalementsLoaded) {
            if (state.signalements.isEmpty) {
              return const Center(
                child: Text('Aucun signalement envoyé', style: TextStyle(color: _C.sub)),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<SignalementsBloc>().add(LoadMesSignalements()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.signalements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final s = state.signalements[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _C.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _C.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                                s.type == 'boutique'
                                    ? Icons.storefront_outlined
                                    : Icons.inventory_2_outlined,
                                size: 16,
                                color: _C.sub),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(s.raison,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _C.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(s.statut,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: _C.orange,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(s.description),
                        if (s.createdAt != null) ...[
                          const SizedBox(height: 6),
                          Text(DateFormat('dd/MM/yyyy').format(s.createdAt!),
                              style: const TextStyle(fontSize: 11, color: _C.sub)),
                        ],
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
