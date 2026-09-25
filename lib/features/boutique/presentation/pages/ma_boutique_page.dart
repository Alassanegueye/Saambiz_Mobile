import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../injection_container.dart';
import '../bloc/boutique_bloc.dart';
import '../bloc/boutique_event.dart';
import '../bloc/boutique_state.dart';
import 'boutique_form_page.dart';

class _C {
  static const green = Color(0xFF1B3A6B);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7F2);
  static const sub = Color(0xFF7A8473);
  static const border = Color(0xFFE3EAD0);
  static const orange = Color(0xFFFF8F00);
}

/// Écran de gestion de la boutique du vendeur connecté.
class MaBoutiquePage extends StatelessWidget {
  const MaBoutiquePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BoutiqueBloc>()..add(LoadMaBoutique()),
      child: const _MaBoutiqueView(),
    );
  }
}

class _MaBoutiqueView extends StatelessWidget {
  const _MaBoutiqueView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: const Text('Ma boutique'),
      ),
      body: BlocConsumer<BoutiqueBloc, BoutiqueState>(
        listener: (context, state) {
          if (state is BoutiqueError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is BoutiqueLoading || state is BoutiqueInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BoutiqueInexistante) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_outlined, color: _C.sub, size: 48),
                    const SizedBox(height: 12),
                    const Text('Vous n\'avez pas encore de boutique',
                        style: TextStyle(color: _C.sub)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final res = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BoutiqueFormPage()),
                        );
                        if (res != null && context.mounted) {
                          context.read<BoutiqueBloc>().add(LoadMaBoutique());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.green,
                        foregroundColor: _C.white,
                      ),
                      child: const Text('Créer ma boutique'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is BoutiqueLoaded) {
            final b = state.boutique;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _C.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _C.border),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (b.logo ?? '').isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: b.logo!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover)
                                : Container(
                                    width: 64,
                                    height: 64,
                                    color: _C.bg,
                                    child: const Icon(Icons.storefront_outlined,
                                        color: _C.sub),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.nom,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: _C.black)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: b.enPause
                                        ? _C.orange.withOpacity(0.12)
                                        : _C.green.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    b.enPause ? 'En pause' : 'Active',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: b.enPause ? _C.orange : _C.green),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(b.description, style: const TextStyle(color: _C.sub)),
                      const SizedBox(height: 8),
                      _info(Icons.location_on_outlined, b.localisation),
                      if (b.telephone != null) _info(Icons.phone_outlined, b.telephone!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => BoutiqueFormPage(boutique: b)),
                    );
                    if (context.mounted) {
                      context.read<BoutiqueBloc>().add(LoadMaBoutique());
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier la boutique'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.white,
                    foregroundColor: _C.black,
                    side: const BorderSide(color: _C.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<BoutiqueBloc>().add(b.enPause
                        ? ReactiverBoutiqueRequested()
                        : PauseBoutiqueRequested());
                  },
                  icon: Icon(b.enPause ? Icons.play_arrow : Icons.pause),
                  label: Text(b.enPause ? 'Réactiver la boutique' : 'Mettre en pause'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: b.enPause ? _C.green : _C.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _info(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 16, color: _C.sub),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(color: _C.black))),
          ],
        ),
      );
}
