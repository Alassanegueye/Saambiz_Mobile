import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/page_vendeur.dart';
import 'package:saambiz/core/widgets/onglets_conserves.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:flutter/material.dart';
import 'package:saambiz/core/widgets/logo_boutique.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:saambiz/core/widgets/empty_state.dart';

import '../../../catalogue/data/produit_catalogue.dart' show BoutiqueResume;
import '../../../catalogue/presentation/pages/boutique_publique_page.dart';
import '../../../catalogue/presentation/pages/categories_page.dart'
    show explorerBoutiquesDemande;
import '../../../home/presentation/pages/acheteur/main_client_page.dart'
    show ongletAcheteurDemande;
import '../../domain/entities/boutique_suivie.dart';

import '../../../../injection_container.dart';
import '../bloc/favoris_bloc.dart';
import '../bloc/favoris_event.dart';
import '../bloc/favoris_state.dart';

import '../../../catalogue/data/favoris_produits.dart';
import '../../../catalogue/presentation/widgets/produit_card.dart';

class _C {
  static const black = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
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
      child: ActualiserAuRetour(
        onRetour: (context) => context.read<FavorisBloc>().add(LoadFavoris()),
        child: const _FavorisView(),
      ),
    );
  }
}

class _FavorisView extends StatelessWidget {
  const _FavorisView();

  @override
  Widget build(BuildContext context) {
    return PageVendeur(
      titre: 'Mes favoris',
      corps: Column(
        children: [
          // Produits aimés (cœur des cartes produits), puis boutiques suivies.
          const _ProduitsAimes(),
          Expanded(
            child: BlocConsumer<FavorisBloc, FavorisState>(
              buildWhen: (avant, apres) =>
                  !(apres is FavorisLoading && avant is FavorisLoaded),
              listener: (context, state) {
                if (state is FavorisError) {
                  afficherErreur(context, state.message);
                } else if (state is FavorisLoaded && state.succes != null) {
                  afficherSucces(context, state.succes!);
                }
              },
              builder: (context, state) {
                if (state is FavorisLoading || state is FavorisInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is FavorisLoaded) {
                  // Une boutique suivie deux fois côté serveur n'apparaît
                  // qu'une fois.
                  final vues = <String>{};
                  final boutiques = state.boutiques
                      .where((b) => vues.add(b.id))
                      .toList(growable: false);
                  if (boutiques.isEmpty) {
                    return EmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'Aucune boutique suivie',
                      subtitle:
                          'Touchez le cœur d’une boutique pour la retrouver ici.',
                      actionLabel: 'Découvrir les boutiques',
                      onAction: () {
                        explorerBoutiquesDemande.value++;
                        ongletAcheteurDemande.value = 1;
                      },
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<FavorisBloc>().add(LoadFavoris()),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      itemCount: boutiques.length + 1,
                      separatorBuilder: (_, i) =>
                          SizedBox(height: i == 0 ? 12 : 10),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return _EnTeteSection(
                            titre: 'Boutiques suivies',
                            nombre: boutiques.length,
                          );
                        }
                        return _CarteBoutiqueSuivie(boutique: boutiques[i - 1]);
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

class _EnTeteSection extends StatelessWidget {
  final String titre;
  final int nombre;
  const _EnTeteSection({required this.titre, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          titre,
          style: const TextStyle(
            fontFamily: kPolice,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: _C.black,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColor.kPrimaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$nombre',
            style: const TextStyle(
              fontFamily: kPolice,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: _C.black,
            ),
          ),
        ),
      ],
    );
  }
}

/// Une boutique suivie : touchez la carte pour l'ouvrir, la pastille
/// « Alertes » pour les notifications, le cœur pour ne plus la suivre.
class _CarteBoutiqueSuivie extends StatelessWidget {
  final BoutiqueSuivie boutique;
  const _CarteBoutiqueSuivie({required this.boutique});

  void _ouvrir(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BoutiquePubliquePage(
          boutiqueId: boutique.id,
          apercu: BoutiqueResume(
            id: boutique.id,
            nom: boutique.nom,
            logo: boutique.logo,
            localisation: boutique.localisation ?? '',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = boutique;
    final lieu = (b.localisation ?? '').trim();
    return Material(
      color: _C.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _ouvrir(context),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
            boxShadow: [
              BoxShadow(
                color: _C.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: (b.logo ?? '').isNotEmpty
                    ? ImageReseau(
                        b.logo!,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        repli: _logoParDefaut(),
                      )
                    : _logoParDefaut(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: _C.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: _C.sub,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            lieu.isEmpty ? 'Localisation non précisée' : lieu,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: kPolice,
                              color: _C.sub,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _PastilleAlertes(
                      active: b.clocheActive,
                      onTap: () => context.read<FavorisBloc>().add(
                        ToggleClocheFavori(b.id, !b.clocheActive),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ne plus suivre',
                onPressed: () =>
                    context.read<FavorisBloc>().add(SupprimerFavori(b.id)),
                icon: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColor.kErreurLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFE5484D),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoParDefaut() =>
      const SizedBox(width: 58, height: 58, child: LogoBoutiqueParDefaut());
}

class _PastilleAlertes extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _PastilleAlertes({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: active ? 'Désactiver les alertes' : 'Activer les alertes',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? AppColor.kSecondaryLight : AppColor.kPrimaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_outlined,
                size: 14,
                color: active ? AppColor.kSecondaryDark : _C.sub,
              ),
              const SizedBox(width: 5),
              Text(
                active ? 'Alertes activées' : 'Alertes désactivées',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColor.kSecondaryDark : _C.sub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
                child: Text(
                  'Produits aimés (${produits.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _C.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: largeur / ratioCarteProduit,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: produits.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => SizedBox(
                    width: largeur,
                    child: ProduitCard(produit: produits[i]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
