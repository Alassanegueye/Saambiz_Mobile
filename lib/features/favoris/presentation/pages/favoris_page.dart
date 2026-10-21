import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../injection_container.dart';
import '../bloc/favoris_bloc.dart';
import '../bloc/favoris_event.dart';
import '../bloc/favoris_state.dart';
import 'package:saambiz/core/utils/image_url.dart';

import '../../../catalogue/data/favoris_produits.dart';
import '../../../catalogue/presentation/widgets/produit_card.dart';

class _C {
  static const green = Color(0xFF0D1B3D);
  static const black = Color(0xFF0D1B3D);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF5B6C8A);
  static const border = Color(0xFFE3E8F0);
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
      body: Column(
        children: [
          // Produits aimés (cœur des cartes produits), puis boutiques suivies.
          const _ProduitsAimes(),
          Expanded(
            child: BlocConsumer<FavorisBloc, FavorisState>(
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
                                  imageUrl: imageOptimisee(b.logo!),
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
          ),
        ],
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

/// Les produits aimés, sur une ligne qui défile. Rien tant qu'il n'y en a pas.
class _ProduitsAimes extends StatelessWidget {
  const _ProduitsAimes();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: FavorisProduits.liste,
      builder: (context, liste, _) {
        if (liste.isEmpty) return const SizedBox.shrink();
        final produits = FavorisProduits.produits;
        const largeur = 150.0;
        return Container(
          color: _C.white,
          padding: const EdgeInsets.only(top: 14, bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Produits aimés (${produits.length})',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _C.black)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: largeur / ratioCarteProduit,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: produits.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => SizedBox(width: largeur, child: ProduitCard(produit: produits[i])),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
