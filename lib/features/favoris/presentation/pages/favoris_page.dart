import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../injection_container.dart';
import '../bloc/favoris_bloc.dart';
import '../bloc/favoris_event.dart';
import '../bloc/favoris_state.dart';

class _C {
  static const green = Color(0xFF1B3A6B);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7F2);
  static const sub = Color(0xFF7A8473);
  static const border = Color(0xFFE3EAD0);
}

/// Boutiques favorites de l'acheteur connecté (GET/POST/DELETE /favoris).
class FavorisPage extends StatelessWidget {
  const FavorisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FavorisBloc>()..add(LoadFavoris()),
      child: const _FavorisView(),
    );
  }
}

class _FavorisView extends StatelessWidget {
  const _FavorisView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: const Text('Mes favoris'),
      ),
      body: BlocConsumer<FavorisBloc, FavorisState>(
        listener: (context, state) {
          if (state is FavorisError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is FavorisLoading || state is FavorisInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FavorisLoaded) {
            if (state.boutiques.isEmpty) {
              return const Center(
                child: Text('Aucune boutique favorite pour le moment',
                    style: TextStyle(color: _C.sub)),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<FavorisBloc>().add(LoadFavoris()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.boutiques.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final b = state.boutiques[i];
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
                          child: (b.logo ?? '').isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: b.logo!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => _fallback())
                              : _fallback(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.nom,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, color: _C.black)),
                              const SizedBox(height: 2),
                              Text(b.localisation ?? 'Localisation non précisée',
                                  style: const TextStyle(color: _C.sub, fontSize: 12)),
                            ],
                          ),
                        ),
                        // 🔔 Cloche : notifications nouveaux produits / promos
                        IconButton(
                          tooltip: b.clocheActive
                              ? 'Désactiver les notifications'
                              : 'Activer les notifications',
                          icon: Icon(
                            b.clocheActive
                                ? Icons.notifications_active
                                : Icons.notifications_off_outlined,
                            color: b.clocheActive ? _C.green : _C.sub,
                          ),
                          onPressed: () => context
                              .read<FavorisBloc>()
                              .add(ToggleClocheFavori(b.id, !b.clocheActive)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.redAccent),
                          onPressed: () => context
                              .read<FavorisBloc>()
                              .add(SupprimerFavori(b.id)),
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

  Widget _fallback() => Container(
        width: 56,
        height: 56,
        color: _C.bg,
        child: const Icon(Icons.storefront_outlined, color: _C.sub),
      );
}
