import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typo.dart';
import '../../../../core/theme/police.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/messages.dart';
import '../../../../core/widgets/onglets_conserves.dart';
import '../../../../core/widgets/page_vendeur.dart';
import '../../../../core/widgets/profil_kit.dart' show confirmerAction;
import '../../../../core/widgets/ui_kit.dart' show EtatVide;
import '../../../../injection_container.dart';
import '../../../catalogue/data/favoris_produits.dart';
import '../../../catalogue/data/produit_catalogue.dart';
import '../../../catalogue/presentation/pages/categories_page.dart'
    show explorerBoutiquesDemande;
import '../../../catalogue/presentation/widgets/produit_card.dart';
import '../../../home/presentation/pages/acheteur/main_client_page.dart'
    show ongletAcheteurDemande;
import '../../../home/presentation/widgets/carte_boutique_grille.dart';
import '../../domain/entities/boutique_suivie.dart';
import '../bloc/favoris_bloc.dart';
import '../bloc/favoris_event.dart';
import '../bloc/favoris_state.dart';

/// Rouge du cœur, le même que sur les cartes produit.
const _rougeCoeur = Color(0xFFE5484D);

/// Favoris de l'acheteur : les produits aimés sur une ligne qui défile, puis
/// les boutiques suivies en cartes, deux par ligne, chacune avec ses alertes
/// et le cœur pour ne plus la suivre.
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

  /// Ouvre l'onglet Explorer sur la liste des boutiques.
  static void _decouvrir() {
    explorerBoutiquesDemande.value++;
    ongletAcheteurDemande.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    return PageVendeur(
      titre: 'Mes favoris',
      sousTitre: 'Vos boutiques et produits préférés',
      corps: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: FavorisProduits.liste,
        builder: (context, _, __) => BlocConsumer<FavorisBloc, FavorisState>(
          // Une actualisation garde la liste à l'écran au lieu du squelette.
          buildWhen: (avant, apres) =>
              !(apres is FavorisLoading && avant is FavorisLoaded),
          listener: (context, state) {
            if (state is FavorisError) {
              afficherErreur(context, state.message);
            } else if (state is FavorisLoaded && state.succes != null) {
              afficherSucces(context, state.succes!);
            }
          },
          builder: (context, state) =>
              _contenu(context, state, FavorisProduits.produits),
        ),
      ),
    );
  }

  Widget _contenu(
    BuildContext context,
    FavorisState state,
    List<ProduitCatalogue> produits,
  ) {
    if (state is FavorisLoading || state is FavorisInitial) {
      return const SqueletteCartesBoutiques();
    }
    // Le bloc remet la liste après un échec d'action : l'erreur seule ne
    // reste à l'écran que si rien n'a jamais pu être chargé.
    if (state is FavorisError) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Chargement impossible',
        subtitle: 'Vérifiez votre connexion puis réessayez.',
        actionLabel: 'Réessayer',
        onAction: () => context.read<FavorisBloc>().add(LoadFavoris()),
      );
    }

    // Une boutique suivie deux fois côté serveur n'apparaît qu'une fois.
    final vues = <String>{};
    final boutiques = state is FavorisLoaded
        ? state.boutiques.where((b) => vues.add(b.id)).toList()
        : const <BoutiqueSuivie>[];

    if (boutiques.isEmpty && produits.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'Aucun favori pour le moment',
        subtitle:
            'Suivez une boutique ou touchez le cœur d’un produit pour le retrouver ici.',
        actionLabel: 'Découvrir les boutiques',
        onAction: _decouvrir,
      );
    }

    final alertes = boutiques.where((b) => b.clocheActive).length;
    final resumeAlertes = boutiques.isEmpty
        ? null
        : alertes == 0
        ? 'Activez les alertes pour être prévenu de leurs nouveautés.'
        : alertes == boutiques.length
        ? 'Alertes activées pour toutes vos boutiques.'
        : '$alertes sur ${boutiques.length} avec les alertes activées.';

    return RefreshIndicator(
      color: AppColor.kPrimary,
      onRefresh: () async {
        final bloc = context.read<FavorisBloc>()..add(LoadFavoris());
        await bloc.stream.firstWhere(
          (s) => s is FavorisLoaded || s is FavorisError,
        );
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (produits.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _EnTeteSection(
                titre: 'Produits aimés',
                nombre: produits.length,
              ),
            ),
            SliverToBoxAdapter(child: _RangeeProduits(produits: produits)),
          ],
          SliverToBoxAdapter(
            child: _EnTeteSection(
              titre: 'Boutiques suivies',
              nombre: boutiques.length,
              sousTitre: resumeAlertes,
            ),
          ),
          if (boutiques.isEmpty)
            const SliverToBoxAdapter(child: _InvitationBoutiques())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: CarteBoutiqueGrille.grille(context),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Apparition(
                    rang: i,
                    child: _CarteSuivie(boutique: boutiques[i]),
                  ),
                  childCount: boutiques.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: espaceBasVendeur(context)),
          ),
        ],
      ),
    );
  }
}

/// Titre de section : barre dorée, titre, nombre, et une ligne d'aide.
class _EnTeteSection extends StatelessWidget {
  final String titre;
  final int nombre;
  final String? sousTitre;
  const _EnTeteSection({
    required this.titre,
    required this.nombre,
    this.sousTitre,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColor.kSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypo.titreM,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColor.kPrimaryLight,
                  borderRadius: BorderRadius.circular(AppDim.rayonPastille),
                ),
                child: Text(
                  '$nombre',
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (sousTitre != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(sousTitre!, style: AppTypo.petit),
            ),
          ],
        ],
      ),
    );
  }
}

/// Les produits aimés, sur une ligne qui défile.
class _RangeeProduits extends StatelessWidget {
  final List<ProduitCatalogue> produits;
  const _RangeeProduits({required this.produits});

  @override
  Widget build(BuildContext context) {
    const largeur = 150.0;
    return SizedBox(
      height: largeur / ratioCarteProduit,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: produits.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(
          width: largeur,
          child: ProduitCard(produit: produits[i]),
        ),
      ),
    );
  }
}

/// Aucune boutique suivie alors qu'il y a des produits aimés.
class _InvitationBoutiques extends StatelessWidget {
  const _InvitationBoutiques();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: AppDim.brCarte,
        border: Border.all(color: AppColor.kLine),
      ),
      child: const EtatVide(
        icone: Icons.storefront_outlined,
        titre: 'Aucune boutique suivie',
        message:
            'Touchez « Suivre » sur la page d’une boutique pour la retrouver ici.',
        action: 'Découvrir les boutiques',
        onAction: _FavorisView._decouvrir,
        compact: true,
      ),
    );
  }
}

/// Une boutique suivie : la carte des boutiques, avec le cœur sur la
/// couverture et les alertes à la place de « Voir la boutique ».
class _CarteSuivie extends StatelessWidget {
  final BoutiqueSuivie boutique;
  const _CarteSuivie({required this.boutique});

  /// Ne plus suivre se confirme : un cœur se touche par mégarde, et la
  /// boutique disparaissait aussitôt de la liste.
  Future<void> _nePlusSuivre(BuildContext context) async {
    final bloc = context.read<FavorisBloc>();
    final confirme = await confirmerAction(
      context,
      icone: Icons.heart_broken_rounded,
      titre: 'Ne plus suivre ${boutique.nom} ?',
      message:
          'Elle quittera vos favoris et vous ne recevrez plus ses alertes.',
      action: 'Ne plus suivre',
    );
    if (confirme) bloc.add(SupprimerFavori(boutique.id));
  }

  @override
  Widget build(BuildContext context) {
    final b = boutique;
    return CarteBoutiqueGrille(
      donnees: {
        'id': b.id,
        'nom': b.nom,
        'logo': b.logo,
        'banniere': b.banniere,
        'categorie': b.categorie,
        'localisation': b.localisation,
      },
      coin: _BoutonCoeur(onTap: () => _nePlusSuivre(context)),
      action: _BoutonAlertes(
        active: b.clocheActive,
        onTap: () => context.read<FavorisBloc>().add(
          ToggleClocheFavori(b.id, !b.clocheActive),
        ),
      ),
    );
  }
}

/// Cœur plein sur pastille blanche : la boutique est suivie ; le toucher
/// propose de ne plus la suivre. Zone tactile de 44 points.
class _BoutonCoeur extends StatelessWidget {
  final VoidCallback onTap;
  const _BoutonCoeur({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ne plus suivre',
      child: Semantics(
        button: true,
        label: 'Ne plus suivre',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColor.kWhite.withValues(alpha: 0.96),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.kPrimary.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: _rougeCoeur,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Alertes de la boutique : dorées quand elles sont actives, bleues
/// (« Activer les alertes ») sinon.
class _BoutonAlertes extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _BoutonAlertes({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final couleur = active ? AppColor.kSecondaryDark : AppColor.kPrimary;
    return Semantics(
      button: true,
      toggled: active,
      label: active ? 'Alertes activées' : 'Activer les alertes',
      excludeSemantics: true,
      child: Material(
        color: active ? AppColor.kSecondaryLight : AppColor.kPrimaryLight,
        borderRadius: AppDim.brMoyen,
        child: InkWell(
          borderRadius: AppDim.brMoyen,
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  active
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  size: 16,
                  color: couleur,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    active ? 'Alertes activées' : 'Activer les alertes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: couleur,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
