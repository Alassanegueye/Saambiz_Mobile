import 'package:saambiz/core/widgets/onglets_conserves.dart';
import 'package:flutter/material.dart';
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
  static const bg = Color(0xFFF4F5F8);
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

  /// Action secondaire, volontairement discrète : un message libre aux abonnés
  /// (boutique ouverte, nouveautés…).
  Widget _lienInformer(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _nouvelleCampagne(context, TypeCampagne.information),
        icon: const Icon(Icons.campaign_outlined, size: 20),
        label: const Text(
          'Informer les abonnés',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          foregroundColor: _C.green,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text('Mes promotions'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () =>
                  _nouvelleCampagne(context, TypeCampagne.promotion),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Créer une promo'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.kSecondary,
                foregroundColor: AppColor.kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _lienInformer(context),
          Expanded(
            child: BlocConsumer<PromotionsBloc, PromotionsState>(
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
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
          ),
        ],
      ),
    );
  }
}

/// État vide : le message, et un conseil sur ce qu'il faut faire ensuite.
class _AucunePromotion extends StatelessWidget {
  const _AucunePromotion();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aucune promotion en cours pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _C.black,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    color: AppColor.kSecondary,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Pensez à informer vos abonnés ',
                        children: [
                          TextSpan(
                            text:
                                'après avoir créé votre promotion pour booster vos ventes !',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: _C.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
