import 'package:saambiz/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saambiz/core/utils/telephone.dart';
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
    final numeroCtrl = TextEditingController();
    // Orange Money et Wave : numéros sénégalais uniquement.
    final paysPaiement = ValueNotifier<PaysTelephone>(senegal);
    String? erreurNumero;
    String methode = 'orange_money';
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Renouveler mon abonnement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numeroCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FormatTelephone(paysPaiement)],
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: senegal.exemple,
                  prefixText: '${senegal.drapeau} ${senegal.indicatif}  ',
                  errorText: erreurNumero,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: methode,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'orange_money',
                    child: Text('Orange Money'),
                  ),
                  DropdownMenuItem(value: 'wave', child: Text('Wave')),
                ],
                onChanged: (v) =>
                    setStateDialog(() => methode = v ?? 'orange_money'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final erreur = verifierTelephone(numeroCtrl.text, senegal);
                if (erreur != null) {
                  setStateDialog(() => erreurNumero = erreur);
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Payer'),
            ),
          ],
        ),
      ),
    );
    if (res == true && numeroCtrl.text.trim().isNotEmpty && context.mounted) {
      final bloc = context.read<AbonnementBloc>();
      final state = bloc.state;
      num? montant = state is AbonnementLoaded
          ? state.abonnement.montant
          : null;

      // Le repli valait `0`, et le backend refuse tout montant non positif :
      // tant que la fiche d'abonnement n'était pas chargée, le paiement
      // échouait à coup sûr sur « Le montant doit être positif ». Le prix est
      // désormais demandé au serveur, qui en est la source.
      if (montant == null || montant <= 0) {
        montant = await sl<ConfigPubliqueService>().prixAbonnement();
      }

      if (!context.mounted) return;

      if (montant == null || montant <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Le montant de l'abonnement n'a pas pu être récupéré. "
              'Vérifiez votre connexion puis réessayez.',
            ),
          ),
        );
        return;
      }

      bloc.add(
        PayerAbonnement(
          montant: montant,
          numeroTelephone: chiffresNationaux(numeroCtrl.text, senegal),
          methode: methode,
        ),
      );
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is PaiementInitieAbonnement) {
            final url = state.paymentUrl;
            if (url != null && url.isNotEmpty) {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
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
