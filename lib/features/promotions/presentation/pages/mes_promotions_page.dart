import 'package:saambiz/core/widgets/onglets_conserves.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/page_vendeur.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/theme/police.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../injection_container.dart';
import '../bloc/promotions_bloc.dart';
import '../bloc/promotions_event.dart';
import '../bloc/promotions_state.dart';
import 'nouvelle_campagne_page.dart';
import 'promotion_form_page.dart';

class _C {
  static const green = Color(0xFF01154B);
  static const black = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
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
      child: ActualiserAuRetour(
        onRetour: (context) => context.read<PromotionsBloc>().add(LoadMesPromotions()),
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

  @override
  Widget build(BuildContext context) {
    return PageVendeur(
      titre: 'Promotions',
      sousTitre: 'Réductions et messages aux abonnés',
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
                  !(apres is PromotionsLoading && avant is PromotionsLoaded),
              listener: (context, state) {
                if (state is PromotionsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
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
                        return Container(
                          decoration: BoxDecoration(
                            color: _C.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.border),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.titre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _C.black,
                                      ),
                                    ),
                                    Text(
                                      '${p.prixPromo.toStringAsFixed(0)} FCFA',
                                      style: const TextStyle(
                                        color: _C.green,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (p.dateFin != null)
                                      Text(
                                        'Jusqu\'au ${DateFormat('dd/MM/yyyy').format(p.dateFin!)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _C.sub,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    _ouvrirForm(context, promotion: p);
                                  } else if (v == 'delete') {
                                    context.read<PromotionsBloc>().add(
                                      SupprimerPromotion(p.id),
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Modifier'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Supprimer'),
                                  ),
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
