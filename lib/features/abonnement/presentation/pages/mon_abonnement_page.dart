import 'package:saambiz/core/config/env.dart';
import 'package:saambiz/core/paiement/feuille_paiement_mobile.dart';
import 'package:saambiz/core/paiement/paiement_simule.dart';
import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/config_publique_service.dart';
import '../../../../core/utils/libelles.dart';
import '../../../../injection_container.dart';
import '../bloc/abonnement_bloc.dart';
import '../bloc/abonnement_event.dart';
import '../bloc/abonnement_state.dart';

class _C {
  static const green = Color(0xFF01154B);
  static const black = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F8);
  static const sub = Color(0xFF5B6C8A);
  static const border = Color(0xFFE3E8F0);
  static const orange = Color(0xFFFF8F00);
}

/// Écran abonnement + historique des paiements du vendeur.
class MonAbonnementPage extends StatelessWidget {
  const MonAbonnementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AbonnementBloc>()..add(LoadAbonnement()),
      child: const _MonAbonnementView(),
    );
  }
}

class _MonAbonnementView extends StatefulWidget {
  const _MonAbonnementView();
  @override
  State<_MonAbonnementView> createState() => _MonAbonnementViewState();
}

class _MonAbonnementViewState extends State<_MonAbonnementView> {
  final _dateFmt = DateFormat('dd/MM/yyyy');

  Future<void> _renouveler(BuildContext context) async {
    final bloc = context.read<AbonnementBloc>();
    final state = bloc.state;
    num? montant = state is AbonnementLoaded ? state.abonnement.montant : null;

    // Le backend refuse tout montant non positif : tant que la fiche n'est
    // pas chargée (ou pendant l'essai gratuit, à 0), le prix est demandé au
    // serveur, qui en est la source.
    if (montant == null || montant <= 0) {
      montant = await sl<ConfigPubliqueService>().prixAbonnement();
    }
    if (!context.mounted) return;

    final choix = await choisirPaiementMobile(
      context,
      titre: 'Renouveler mon abonnement',
      montant: montant,
    );
    if (choix == null || !context.mounted) return;

    if (Env.paiementSimule) {
      await _payerEnSimulation(context, choix, montant ?? 0);
      return;
    }

    if (montant == null || montant <= 0) {
      afficherErreur(
        context,
        "Le montant de l'abonnement n'a pas pu être récupéré. "
        'Vérifiez votre connexion puis réessayez.',
      );
      return;
    }

    bloc.add(
      PayerAbonnement(
        montant: montant,
        numeroTelephone: choix.numero,
        methode: choix.methode,
      ),
    );
  }

  /// Paiement simulé, le temps que les API Orange Money / Wave soient
  /// branchées : une attente « confirmez sur votre téléphone », puis l'issue
  /// prévue pour le numéro de test choisi.
  Future<void> _payerEnSimulation(
    BuildContext context,
    ChoixPaiementMobile choix,
    num montant,
  ) async {
    final operateur = choix.methode == 'wave'
        ? Operateur.wave
        : Operateur.orangeMoney;
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LogoOperateur(operateur, taille: 56),
                const SizedBox(height: 18),
                const Text(
                  'Confirmez le paiement',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Validez la demande ${operateur.nom} reçue sur le '
                  '${choix.numero}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: _C.sub),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: operateur.couleur,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final r = await simulerPaiement(
      numero: choix.numero,
      methode: choix.methode,
      montant: montant,
    );
    navigator.pop();
    if (!context.mounted) return;
    if (r.reussi) {
      afficherSucces(context, '${r.message}\nRéférence : ${r.reference}');
    } else {
      afficherErreur(context, r.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text('Mon abonnement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique des paiements',
            onPressed: () =>
                context.read<AbonnementBloc>().add(LoadHistoriquePaiements()),
          ),
        ],
      ),
      body: BlocConsumer<AbonnementBloc, AbonnementState>(
        listener: (context, state) async {
          if (state is AbonnementError) {
            afficherErreur(context, state.message);
          } else if (state is PaiementInitieAbonnement) {
            final url = state.paymentUrl;
            final uri = (url == null || url.isEmpty) ? null : Uri.tryParse(url);
            if (uri == null) {
              afficherSucces(
                context,
                'Confirmez le paiement sur votre téléphone pour renouveler '
                'votre abonnement.',
                titre: 'Paiement lancé',
              );
              return;
            }
            final ouvert = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            if (!context.mounted) return;
            ouvert
                ? afficherInfo(
                    context,
                    'Terminez le paiement dans la page qui vient de s\'ouvrir.',
                    titre: 'Paiement lancé',
                  )
                : afficherErreur(
                    context,
                    'La page de paiement n\'a pas pu s\'ouvrir. Réessayez.',
                  );
          }
        },
        builder: (context, state) {
          if (state is AbonnementLoading || state is AbonnementInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HistoriquePaiementsLoaded) {
            return _historiqueView(context, state);
          }
          if (state is AbonnementLoaded) {
            return _abonnementView(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _abonnementView(BuildContext context, AbonnementLoaded state) {
    final a = state.abonnement;
    final actif = a.statut == 'actif';
    final fin = a.dateFin;
    final joursRestants = fin?.difference(DateTime.now()).inDays;
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // La question qui compte, sur le bleu de l'en-tête : jusqu'à quand ?
        Container(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          decoration: const BoxDecoration(
            color: AppColor.kPrimary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: actif ? AppColor.kSuccesLight : AppColor.kSecondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  libelle(a.statut),
                  style: TextStyle(
                    color: actif ? AppColor.kSucces : AppColor.kPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                libelle(a.type, vide: 'Abonnement'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  color: _C.white,
                ),
              ),
              if (joursRestants != null) ...[
                const SizedBox(height: 4),
                Text(
                  joursRestants >= 0
                      ? 'Encore $joursRestants jour${joursRestants > 1 ? 's' : ''}'
                      : 'Votre abonnement est expiré',
                  style: TextStyle(
                    fontSize: 14,
                    color: _C.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.border),
                ),
                child: Column(
                  children: [
                    if (a.dateDebut != null)
                      _row('Début', _dateFmt.format(a.dateDebut!)),
                    if (fin != null) _row('Fin', _dateFmt.format(fin)),
                    _row('Montant', '${a.montant.toStringAsFixed(0)} FCFA'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _renouveler(context),
                icon: const Icon(Icons.autorenew_rounded, size: 20),
                label: const Text('Renouveler mon abonnement'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.kSecondary,
                  foregroundColor: AppColor.kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.read<AbonnementBloc>().add(
                  LoadHistoriquePaiements(),
                ),
                icon: const Icon(Icons.history_rounded, size: 20),
                label: const Text('Historique des paiements'),
                style: TextButton.styleFrom(foregroundColor: AppColor.kPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _historiqueView(
    BuildContext context,
    HistoriquePaiementsLoaded state,
  ) {
    if (state.paiements.isEmpty) {
      return const Center(
        child: Text(
          'Aucun paiement pour le moment',
          style: TextStyle(color: _C.sub),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<AbonnementBloc>().add(LoadHistoriquePaiements()),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.paiements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final p = state.paiements[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.montant.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _C.black,
                        ),
                      ),
                      if (p.date != null)
                        Text(
                          _dateFmt.format(p.date!),
                          style: const TextStyle(color: _C.sub, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Text(
                  libelle(p.statut),
                  style: TextStyle(
                    color: p.statut == 'reussi' ? _C.green : _C.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: _C.sub)),
        Text(
          v,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _C.black),
        ),
      ],
    ),
  );
}
