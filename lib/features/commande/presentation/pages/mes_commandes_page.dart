import 'package:saambiz/core/widgets/page_vendeur.dart';
import 'package:saambiz/core/widgets/onglets_conserves.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/police.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/barre_navigation_verre.dart'
    show kEspaceBarreBas;
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../injection_container.dart';
import '../../../home/presentation/pages/acheteur/main_client_page.dart'
    show ongletAcheteurDemande;
import '../../../catalogue/presentation/pages/categories_page.dart'
    show explorerBoutiquesDemande;
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';
import '../../data/models/commande_model.dart';
import '../widgets/commande_card.dart';
import 'commande_detail_page.dart';

/// Définition des filtres de statut de commande.
const List<({String cle, String label})> _kFiltresStatut = [
  (cle: 'tous', label: 'Tous'),
  (cle: 'en_attente', label: 'En attente'),
  (cle: 'en_preparation', label: 'En préparation'),
  (cle: 'en_livraison', label: 'En livraison'),
  (cle: 'livree', label: 'Livrées'),
  (cle: 'annulee', label: 'Annulées'),
];

/// Onglet « Commandes » :
/// - invité        → recherche + filtres de statut + invitation à se connecter ;
/// - client connecté → recherche + filtres dynamiques + commandes en temps réel.
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

class _ListeState extends State<_Liste> with RetourSurOnglet {
  @override
  void surRetourOnglet() => _recharger();

  Timer? _polling;
  final TextEditingController _rechercheCtrl = TextEditingController();
  String _recherche = '';
  String _statutFiltre = 'tous';

  @override
  void initState() {
    super.initState();
    // Recharge régulière : les statuts changent côté vendeur.
    _polling = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && OngletsConserves.estVisible(context)) _recharger();
    });
  }

  @override
  void dispose() {
    _polling?.cancel();
    _rechercheCtrl.dispose();
    super.dispose();
  }

  void _recharger() => context.read<CommandeBloc>().add(LoadMesCommandes());

  int _calculerNombre(List<CommandeModel> toutes, String cle) {
    if (cle == 'tous') return toutes.length;
    if (cle == 'en_preparation') {
      return toutes
          .where(
            (c) =>
                c.statut == 'en_preparation' ||
                c.statut == 'confirmee' ||
                c.statut == 'acceptee',
          )
          .length;
    }
    if (cle == 'en_livraison') {
      return toutes
          .where((c) => c.statut == 'en_livraison' || c.statut == 'prete')
          .length;
    }
    if (cle == 'annulee') {
      return toutes
          .where((c) => c.statut == 'annulee' || c.statut == 'rejetee')
          .length;
    }
    return toutes.where((c) => c.statut == cle).length;
  }

  List<CommandeModel> _filtrer(List<CommandeModel> toutes) {
    var liste = toutes;

    // Filtre statut
    if (_statutFiltre != 'tous') {
      if (_statutFiltre == 'en_preparation') {
        liste = liste
            .where(
              (c) =>
                  c.statut == 'en_preparation' ||
                  c.statut == 'confirmee' ||
                  c.statut == 'acceptee',
            )
            .toList();
      } else if (_statutFiltre == 'en_livraison') {
        liste = liste
            .where((c) => c.statut == 'en_livraison' || c.statut == 'prete')
            .toList();
      } else if (_statutFiltre == 'annulee') {
        liste = liste
            .where((c) => c.statut == 'annulee' || c.statut == 'rejetee')
            .toList();
      } else {
        liste = liste.where((c) => c.statut == _statutFiltre).toList();
      }
    }

    // Filtre recherche
    if (_recherche.trim().isNotEmpty) {
      final q = _recherche.trim().toLowerCase();
      liste = liste.where((c) {
        final ref = c.referenceCommande.toLowerCase();
        final shop = (c.vendeurNom ?? '').toLowerCase();
        final articles = c.lignes
            .map((l) => l.nomProduit.toLowerCase())
            .join(' ');
        return ref.contains(q) || shop.contains(q) || articles.contains(q);
      }).toList();
    }

    return liste;
  }

  @override
  Widget build(BuildContext context) {
    return PageVendeur(
      titre: 'Mes commandes',
      corps: BlocBuilder<CommandeBloc, CommandeState>(
          buildWhen: (avant, apres) =>
              !(apres is CommandeLoading && avant is CommandesLoaded),
          builder: (context, state) {
            if (state is CommandeLoading || state is CommandeInitial) {
              return const ShimmerList();
            }
            if (state is CommandeError) {
              return _Erreur(message: state.message, onRetry: _recharger);
            }
            if (state is CommandesLoaded) {
              final toutes = state.commandes;
              final filtrees = _filtrer(toutes);

              return RefreshIndicator(
                color: AppColor.kPrimary,
                onRefresh: () async => _recharger(),
                child: Column(
                  children: [
                    // Barre de recherche de commande (comme sur l'image)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      child: _BarreRechercheColis(
                        controller: _rechercheCtrl,
                        onChanged: (v) => setState(() => _recherche = v),
                        onClear: () {
                          _rechercheCtrl.clear();
                          setState(() => _recherche = '');
                        },
                      ),
                    ),

                    // Filtres horizontaux par statut avec compteur
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _kFiltresStatut.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final f = _kFiltresStatut[i];
                          final count = _calculerNombre(toutes, f.cle);
                          final actif = _statutFiltre == f.cle;

                          return _PuceFiltreCommande(
                            label: f.label,
                            count: count,
                            actif: actif,
                            onTap: () => setState(() => _statutFiltre = f.cle),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Liste des commandes ou état vide
                    Expanded(
                      child: filtrees.isEmpty
                          ? (toutes.isEmpty
                                ? EmptyState(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'Aucune commande',
                                    subtitle:
                                        'Vos commandes passées apparaîtront ici.',
                                    actionLabel: 'Découvrir les boutiques',
                                    scrollable: false,
                                    onAction: () {
                                      explorerBoutiquesDemande.value++;
                                      ongletAcheteurDemande.value = 1;
                                    },
                                  )
                                : const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.search_off_rounded,
                                            size: 42,
                                            color: AppColor.kGrayscale40,
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Aucune commande trouvée',
                                            style: TextStyle(
                                              fontFamily: kPolice,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColor.kGrayscaleDark100,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Modifiez vos termes de recherche ou sélectionnez un autre statut.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: kPolice,
                                              fontSize: 12.5,
                                              color: AppColor.kGrayscale40,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                kEspaceBarreBas,
                              ),
                              itemCount: filtrees.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, i) {
                                final c = filtrees[i];
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
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
    );
  }
}

/// Invité : Titre centré + barre de recherche + filtres de statut + invitation à se connecter.
class _Invite extends StatefulWidget {
  const _Invite();

  @override
  State<_Invite> createState() => _InviteState();
}

class _InviteState extends State<_Invite> {
  final TextEditingController _ctrl = TextEditingController();
  String _statutFiltre = 'tous';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageVendeur(
      titre: 'Mes commandes',
      corps: Column(
          children: [
            // Barre de recherche (identique connecté)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: _BarreRechercheColis(
                controller: _ctrl,
                onChanged: (_) {},
                onClear: () => _ctrl.clear(),
              ),
            ),

            // Filtres de statut avec compteurs à 0 pour invité
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _kFiltresStatut.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _kFiltresStatut[i];
                  final actif = _statutFiltre == f.cle;

                  return _PuceFiltreCommande(
                    label: f.label,
                    count: 0,
                    actif: actif,
                    onTap: () => setState(() => _statutFiltre = f.cle),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Carte d'invitation à se connecter
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    kEspaceBarreBas,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                    decoration: BoxDecoration(
                      color: AppColor.kWhite,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColor.kLine),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.kPrimary.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: AppColor.kPrimaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_shipping_outlined,
                            size: 28,
                            color: AppColor.kPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Suivez vos commandes',
                          style: TextStyle(
                            fontFamily: kPolice,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColor.kGrayscaleDark100,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Connectez-vous pour retrouver vos achats, vérifier la préparation de vos colis et suivre la livraison en temps réel.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: kPolice,
                            fontSize: 13,
                            height: 1.45,
                            color: AppColor.kGrayscale40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushNamed(AppRouter.loginRoute),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColor.kPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Se connecter',
                              style: TextStyle(
                                fontFamily: kPolice,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColor.kWhite,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRouter.profileChoiceRoute),
                          child: RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Pas encore de compte ? ',
                                  style: TextStyle(
                                    fontFamily: kPolice,
                                    fontSize: 13,
                                    color: AppColor.kGrayscale40,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Créer un compte',
                                  style: TextStyle(
                                    fontFamily: kPolice,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.kPrimary,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }
}

/// Barre de recherche arrondie en pilule comme sur l'image de référence "My Shipping".
class _BarreRechercheColis extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _BarreRechercheColis({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColor.kLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColor.kGrayscale40,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColor.kGrayscaleDark100,
              ),
              decoration: const InputDecoration(
                hintText: 'Rechercher une commande, un colis...',
                hintStyle: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColor.kGrayscale40,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Icon(
                Icons.cancel_rounded,
                size: 18,
                color: AppColor.kGrayscale40,
              ),
            ),
        ],
      ),
    );
  }
}

/// Pastille filtre de statut avec badge de décompte (style Image 2).
class _PuceFiltreCommande extends StatelessWidget {
  final String label;
  final int count;
  final bool actif;
  final VoidCallback onTap;

  const _PuceFiltreCommande({
    required this.label,
    required this.count,
    required this.actif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: actif ? AppColor.kPrimary : AppColor.kWhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: actif ? AppColor.kPrimary : AppColor.kLine,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: actif ? 0.08 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 12.5,
                fontWeight: actif ? FontWeight.w700 : FontWeight.w600,
                color: actif ? Colors.white : AppColor.kGrayscaleDark100,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: actif
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppColor.kPrimaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: actif ? Colors.white : AppColor.kPrimary,
                ),
              ),
            ),
          ],
        ),
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
          const Icon(
            Icons.error_outline,
            color: AppColor.kGrayscale40,
            size: 48,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColor.kGrayscale40),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
