import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/barre_navigation_verre.dart' show kEspaceBarreBas;
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../injection_container.dart';
import '../../../home/presentation/pages/acheteur/main_client_page.dart' show ongletAcheteurDemande;
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';
import '../widgets/commande_card.dart';
import 'commande_detail_page.dart';

/// Onglet « Commandes » — même écran que Yobante Boutique :
/// - invité        → invitation à se connecter ;
/// - client connecté → ses commandes, rechargées toutes les 30 secondes pour
///   suivre l'évolution des statuts.
class MesCommandesPage extends StatelessWidget {
  final bool isGuest;
  const MesCommandesPage({super.key, this.isGuest = false});

  @override
  Widget build(BuildContext context) {
    if (isGuest) return const _Invite();
    return BlocProvider(
      create: (_) => sl<CommandeBloc>()..add(LoadMesCommandes()),
      child: const _Liste(),
    );
  }
}

class _Liste extends StatefulWidget {
  const _Liste();

  @override
  State<_Liste> createState() => _ListeState();
}

class _ListeState extends State<_Liste> {
  Timer? _polling;

  @override
  void initState() {
    super.initState();
    // Recharge régulière : les statuts changent côté vendeur.
    _polling = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) context.read<CommandeBloc>().add(LoadMesCommandes());
    });
  }

  @override
  void dispose() {
    _polling?.cancel();
    super.dispose();
  }

  void _recharger() => context.read<CommandeBloc>().add(LoadMesCommandes());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: const AppAppBar(title: 'Mes commandes', implyLeading: false),
      body: BlocBuilder<CommandeBloc, CommandeState>(
        builder: (context, state) {
          if (state is CommandeLoading || state is CommandeInitial) {
            return const ShimmerList();
          }
          if (state is CommandeError) {
            return _Erreur(message: state.message, onRetry: _recharger);
          }
          if (state is CommandesLoaded) {
            if (state.commandes.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Aucune commande',
                subtitle: 'Vos commandes passées apparaîtront ici.',
                actionLabel: 'Découvrir les boutiques',
                scrollable: false,
                onAction: () => ongletAcheteurDemande.value = 0,
              );
            }
            return RefreshIndicator(
              color: AppColor.kPrimary,
              onRefresh: () async => _recharger(),
              child: ListView.separated(
                // Marge basse : la barre de navigation flotte dessus.
                padding: const EdgeInsets.fromLTRB(16, 16, 16, kEspaceBarreBas),
                itemCount: state.commandes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final c = state.commandes[i];
                  return CommandeCard(
                    commande: c,
                    onTap: () async {
                      await Navigator.of(context).pushNamed(
                        AppRouter.commandeDetailRoute,
                        arguments: CommandeDetailArgs(c),
                      );
                      if (mounted) _recharger();
                    },
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

class _Erreur extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Erreur({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColor.kGrayscale40, size: 48),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColor.kGrayscale40)),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

/// Invité : invitation à se connecter (carte blanche centrée).
class _Invite extends StatelessWidget {
  const _Invite();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Center(
                child: Text('Mes commandes',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100)),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
                    decoration: BoxDecoration(
                      color: AppColor.kWhite,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: AppColor.kPrimary.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppColor.kPrimaryLight,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: AppColor.kPrimary, size: 34),
                        ),
                        const SizedBox(height: 18),
                        Text('Suivez vos commandes',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18, fontWeight: FontWeight.w700, color: AppColor.kGrayscaleDark100)),
                        const SizedBox(height: 8),
                        Text(
                          'Connectez-vous pour retrouver l\'historique de vos '
                          'commandes, suivre leur état et consulter les détails.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.5, color: AppColor.kGrayscale40),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: AppColor.kPrimary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text('Se connecter',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.kWhite)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed(AppRouter.profileChoiceRoute),
                          child: RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: 'Pas encore de compte ? ',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kGrayscale40),
                              ),
                              TextSpan(
                                text: 'Créer un compte',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.kPrimary),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
