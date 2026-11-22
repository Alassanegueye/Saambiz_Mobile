import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/police.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/image_produit.dart';
import '../../../../core/widgets/messages.dart';
import '../../../../core/widgets/page_vendeur.dart';
import '../../../../injection_container.dart';
import '../../../catalogue/data/catalogue_remote_datasource.dart';
import '../../../catalogue/presentation/pages/produit_detail_page.dart';
import '../../../catalogue/presentation/widgets/produit_card.dart'
    show formaterPrix;
import '../../data/models/promotion_model.dart';
import '../bloc/promotions_bloc.dart';
import '../bloc/promotions_event.dart';
import '../bloc/promotions_state.dart';

/// Ce qu'il reste d'une promotion, en mots : « Dernières heures », « Plus
/// qu'un jour », « Plus que 3 jours », puis la date au-delà d'un mois.
/// Nul pour une promotion sans fin ou déjà terminée.
String? libelleFinPromo(DateTime? fin, {DateTime? maintenant}) {
  if (fin == null) return null;
  final reste = fin.difference(maintenant ?? DateTime.now());
  if (reste.isNegative) return null;
  if (reste.inHours < 24) return 'Dernières heures';
  final jours = reste.inDays;
  if (jours <= 1) return 'Plus qu’un jour';
  if (jours <= 30) return 'Plus que $jours jours';
  return 'Jusqu’au ${dateCourte.format(fin)}';
}

/// Promotions actives, publiques (GET /promotions/actives) : la photo et la
/// remise du produit, son prix promo et son prix barré, ce qu'il reste de
/// temps. Celles qui finissent le plus tôt d'abord ; le toucher ouvre le
/// produit.
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
    // Même gabarit que Boutiques, Commandes ou Favoris : en-tête bleu, contenu
    // sur une carte aux coins arrondis.
    return PageVendeur(
      titre: 'Promotions',
      sousTitre: 'Les bons plans du moment',
      corps: BlocConsumer<PromotionsBloc, PromotionsState>(
        listener: (context, state) {
          if (state is PromotionsError) {
            afficherErreur(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is PromotionsLoading || state is PromotionsInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColor.kPrimary),
            );
          }
          if (state is! PromotionsLoaded) return const SizedBox.shrink();

          // Une promotion terminée n'a rien à faire ici, même si le serveur
          // l'envoyait encore ; les plus pressées d'abord.
          final maintenant = DateTime.now();
          final promotions =
              state.promotions
                  .where(
                    (p) => p.dateFin == null || p.dateFin!.isAfter(maintenant),
                  )
                  .toList()
                ..sort((a, b) {
                  final fa = a.dateFin, fb = b.dateFin;
                  if (fa == null) return fb == null ? 0 : 1;
                  if (fb == null) return -1;
                  return fa.compareTo(fb);
                });

          if (promotions.isEmpty) {
            return const EmptyState(
              icon: Icons.local_offer_outlined,
              title: 'Aucune promotion en ce moment',
              subtitle: 'Revenez bientôt : les boutiques en lancent souvent.',
            );
          }
          return RefreshIndicator(
            color: AppColor.kPrimary,
            onRefresh: () async =>
                context.read<PromotionsBloc>().add(LoadPromotionsActives()),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: promotions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _CartePromotion(promotion: promotions[i]),
            ),
          );
        },
      ),
    );
  }
}

/// Une promotion : photo et remise, nom de l'offre et du produit, prix
/// promo et prix barré, temps restant. Le toucher ouvre le produit.
class _CartePromotion extends StatefulWidget {
  final PromotionModel promotion;
  const _CartePromotion({required this.promotion});

  @override
  State<_CartePromotion> createState() => _CartePromotionState();
}

class _CartePromotionState extends State<_CartePromotion> {
  bool _ouverture = false;

  Future<void> _ouvrir() async {
    final id = widget.promotion.produitId;
    if (id.isEmpty || _ouverture) return;
    setState(() => _ouverture = true);
    try {
      final detail = await CatalogueRemoteDataSource(sl<Dio>()).detail(id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProduitDetailPage(produit: detail.produit),
        ),
      );
    } catch (_) {
      if (mounted) {
        afficherInfo(context, 'Ce produit n’est plus disponible.');
      }
    } finally {
      if (mounted) setState(() => _ouverture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.promotion;
    final remise = p.remise;
    final fin = libelleFinPromo(p.dateFin);
    final derniere = fin == 'Dernières heures' || fin == 'Plus qu’un jour';

    return Material(
      color: AppColor.kWhite,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _ouvrir,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.kLine),
          ),
          child: Row(
            children: [
              // Photo, remise en pastille dorée dans l'angle.
              ImageProduit(
                p.produitImage,
                cote: 92,
                largeurServeur: 240,
                superpositions: [
                  if (remise != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.kSecondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-$remise %',
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColor.kPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    if ((p.produitNom ?? '').isNotEmpty)
                      Text(
                        p.produitNom!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kPolice,
                          fontSize: 12.5,
                          color: AppColor.kGrayscale40,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 6,
                      children: [
                        Text(
                          formaterPrix(p.prixPromo),
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColor.kPrimary,
                          ),
                        ),
                        if (remise != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Text(
                              formaterPrix(p.produitPrix!),
                              style: const TextStyle(
                                fontFamily: kPolice,
                                fontSize: 12,
                                color: AppColor.kGrayscale30,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (fin != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: derniere
                              ? AppColor.kSecondaryLight
                              : AppColor.kPrimaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 13,
                              color: derniere
                                  ? AppColor.kSecondaryDark
                                  : AppColor.kPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              fin,
                              style: TextStyle(
                                fontFamily: kPolice,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: derniere
                                    ? AppColor.kSecondaryDark
                                    : AppColor.kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _ouverture
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColor.kGrayscale30,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
