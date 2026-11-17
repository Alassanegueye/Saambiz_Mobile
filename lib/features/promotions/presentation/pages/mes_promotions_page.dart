import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/onglets_conserves.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/confirmation.dart';
import '../../../../core/widgets/page_vendeur.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/theme/police.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/image_reseau.dart';
import '../../../../injection_container.dart';
import '../../../catalogue/presentation/widgets/produit_card.dart'
    show formaterPrix;
import '../../data/models/promotion_model.dart';
import '../bloc/promotions_bloc.dart';
import '../bloc/promotions_event.dart';
import '../bloc/promotions_state.dart';
import 'nouvelle_campagne_page.dart';
import 'promotion_form_page.dart';
import 'promotions_actives_page.dart' show libelleFinPromo;
import '../../../../core/utils/dates.dart';

/// Où en est une promotion, d'après ses dates.
enum EtatPromo { enCours, bientotFinie, aVenir, terminee }

/// L'état d'une promotion et sa phrase : « Terminée le 11/11/2026 »,
/// « Commence le 20/11/2026 », « En cours · plus que 5 jours ». Bientôt
/// finie à moins de deux jours de la fin, comme sur la page des clients.
(EtatPromo, String) etatPromo(PromotionModel p, {DateTime? maintenant}) {
  final m = maintenant ?? DateTime.now();
  final debut = p.dateDebut?.toLocal();
  final fin = p.dateFin?.toLocal();
  if (fin != null && fin.isBefore(m)) {
    return (EtatPromo.terminee, 'Terminée le ${dateCourte.format(fin)}');
  }
  if (debut != null && debut.isAfter(m)) {
    return (EtatPromo.aVenir, 'Commence le ${dateCourte.format(debut)}');
  }
  final reste = libelleFinPromo(fin, maintenant: m);
  if (fin == null || reste == null) return (EtatPromo.enCours, 'En cours');
  final etat = fin.difference(m).inDays <= 1
      ? EtatPromo.bientotFinie
      : EtatPromo.enCours;
  return (etat, 'En cours · ${reste[0].toLowerCase()}${reste.substring(1)}');
}

/// Promotions du vendeur connecté (GET/POST/PUT/DELETE /promotions).
class MesPromotionsPage extends StatelessWidget {
  const MesPromotionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PromotionsBloc>()..add(LoadMesPromotions()),
      child: ActualiserAuRetour(
        onRetour: (context) =>
            context.read<PromotionsBloc>().add(LoadMesPromotions()),
        child: const _MesPromotionsView(),
      ),
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

  // Elle partait au premier appui, depuis un menu dont l'entrée voisine est
  // « Modifier ».
  Future<void> _supprimer(BuildContext context, PromotionModel p) async {
    final bloc = context.read<PromotionsBloc>();
    final confirme = await confirmerAction(
      context,
      icone: Icons.local_offer_outlined,
      titre: 'Supprimer cette promotion ?',
      message:
          'Les clients ne la verront plus, et le prix '
          'barré redeviendra le prix normal.',
      action: 'Supprimer la promotion',
    );
    if (confirme) bloc.add(SupprimerPromotion(p.id));
  }

  @override
  Widget build(BuildContext context) {
    return PageVendeur(
      titre: 'Promotions',
      actions: [
        BoutonEnteteVendeur(
          icone: Icons.campaign_outlined,
          infobulle: 'Informer les abonnés',
          onTap: () => _nouvelleCampagne(context, TypeCampagne.information),
        ),
      ],
      boutonFlottant: FloatingActionButton.extended(
        onPressed: () => _nouvelleCampagne(context, TypeCampagne.promotion),
        backgroundColor: AppColor.kSecondary,
        foregroundColor: AppColor.kPrimary,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Créer une promo',
          style: TextStyle(fontFamily: kPolice, fontWeight: FontWeight.w700),
        ),
      ),
      corps: BlocConsumer<PromotionsBloc, PromotionsState>(
        buildWhen: (avant, apres) =>
            apres is! PromotionActionSucces &&
            !(apres is PromotionsLoading && avant is PromotionsLoaded),
        listener: (context, state) {
          if (state is PromotionsError) {
            afficherErreur(context, state.message);
          } else if (state is PromotionActionSucces) {
            afficherSucces(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is PromotionsLoading || state is PromotionsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PromotionsLoaded) {
            if (state.promotions.isEmpty) {
              return const _AucunePromotion();
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<PromotionsBloc>().add(LoadMesPromotions()),
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  espaceBasVendeur(context) + 72,
                ),
                itemCount: state.promotions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = state.promotions[i];
                  return _CartePromoVendeur(
                    promotion: p,
                    onModifier: () => _ouvrirForm(context, promotion: p),
                    onSupprimer: () => _supprimer(context, p),
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

/// État vide : ce qu'est une promo, et le conseil de prévenir ses abonnés.
class _AucunePromotion extends StatelessWidget {
  const _AucunePromotion();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: espaceBasVendeur(context)),
      child: const EtatVide(
        icone: Icons.local_offer_outlined,
        titre: 'Aucune promotion en cours',
        message:
            'Créez une réduction sur vos produits, puis prévenez vos abonnés '
            'pour booster vos ventes.',
      ),
    );
  }
}

/// Une promotion du vendeur : la photo et la remise, le titre et le
/// produit, le prix promo et le prix barré, puis son état daté. Le toucher
/// ouvre la promotion à modifier ; terminée, elle pâlit.
class _CartePromoVendeur extends StatelessWidget {
  final PromotionModel promotion;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;
  const _CartePromoVendeur({
    required this.promotion,
    required this.onModifier,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final p = promotion;
    final remise = p.remise;
    final (etat, libelle) = etatPromo(p);
    final terminee = etat == EtatPromo.terminee;
    final (fond, teinte, icone) = switch (etat) {
      EtatPromo.enCours => (
        AppColor.kSuccesLight,
        AppColor.kSucces,
        Icons.bolt_rounded,
      ),
      EtatPromo.bientotFinie => (
        AppColor.kSecondaryLight,
        AppColor.kSecondaryDark,
        Icons.timer_outlined,
      ),
      EtatPromo.aVenir => (
        AppColor.kPrimaryLight,
        AppColor.kPrimary,
        Icons.event_outlined,
      ),
      EtatPromo.terminee => (
        AppColor.kBackground2,
        AppColor.kGrayscale40,
        Icons.history_rounded,
      ),
    };
    const repli = ColoredBox(
      color: AppColor.kPrimaryLight,
      child: Center(
        child: Icon(
          Icons.local_offer_outlined,
          size: 26,
          color: AppColor.kPrimary,
        ),
      ),
    );

    return Material(
      color: AppColor.kWhite,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onModifier,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.kLine),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: terminee ? 0.5 : 1,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: (p.produitImage ?? '').isNotEmpty
                              ? ImageReseau(
                                  p.produitImage!,
                                  largeurServeur: 240,
                                  fit: BoxFit.cover,
                                  repli: repli,
                                )
                              : repli,
                        ),
                      ),
                      if (remise != null)
                        Positioned(
                          top: 5,
                          left: 5,
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
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColor.kPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 14.5,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    if ((p.produitNom ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          p.produitNom!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontSize: 12.5,
                            color: AppColor.kGrayscale40,
                          ),
                        ),
                      ),
                    const SizedBox(height: 5),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 6,
                      children: [
                        Text(
                          formaterPrix(p.prixPromo),
                          style: TextStyle(
                            fontFamily: kPolice,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: terminee
                                ? AppColor.kGrayscale40
                                : AppColor.kPrimary,
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
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: fond,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icone, size: 13, color: teinte),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              libelle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: kPolice,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: teinte,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Plus d’actions',
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColor.kGrayscale40,
                  size: 20,
                ),
                onSelected: (v) {
                  if (v == 'edit') {
                    onModifier();
                  } else if (v == 'delete') {
                    onSupprimer();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Supprimer',
                      style: TextStyle(color: AppColor.kErreur),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
