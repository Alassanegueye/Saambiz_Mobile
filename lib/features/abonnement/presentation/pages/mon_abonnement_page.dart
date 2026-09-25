import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../injection_container.dart';
import '../bloc/abonnement_bloc.dart';
import '../bloc/abonnement_event.dart';
import '../bloc/abonnement_state.dart';

class _C {
  static const green = Color(0xFF1B3A6B);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7F2);
  static const sub = Color(0xFF7A8473);
  static const border = Color(0xFFE3EAD0);
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
                decoration: const InputDecoration(labelText: 'Numéro de téléphone'),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: methode,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'orange_money', child: Text('Orange Money')),
                  DropdownMenuItem(value: 'wave', child: Text('Wave')),
                ],
                onChanged: (v) => setStateDialog(() => methode = v ?? 'orange_money'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Payer')),
          ],
        ),
      ),
    );
    if (res == true && numeroCtrl.text.trim().isNotEmpty && context.mounted) {
      final bloc = context.read<AbonnementBloc>();
      final state = bloc.state;
      final montant = state is AbonnementLoaded ? state.abonnement.montant : null;
      bloc.add(PayerAbonnement(
        montant: montant ?? 0,
        numeroTelephone: numeroCtrl.text.trim(),
        methode: methode,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
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
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(a.type.isNotEmpty ? a.type : 'Abonnement',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18, color: _C.black)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (actif ? _C.green : _C.orange).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      actif ? 'Actif' : a.statut,
                      style: TextStyle(
                          color: actif ? _C.green : _C.orange,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (a.dateDebut != null)
                _row('Début', _dateFmt.format(a.dateDebut!)),
              if (a.dateFin != null) _row('Fin', _dateFmt.format(a.dateFin!)),
              _row('Montant', '${a.montant.toStringAsFixed(0)} FCFA'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _renouveler(context),
          icon: const Icon(Icons.autorenew),
          label: const Text('Renouveler mon abonnement'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.green,
            foregroundColor: _C.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () =>
              context.read<AbonnementBloc>().add(LoadHistoriquePaiements()),
          icon: const Icon(Icons.history),
          label: const Text('Voir l\'historique des paiements'),
        ),
      ],
    );
  }

  Widget _historiqueView(BuildContext context, HistoriquePaiementsLoaded state) {
    if (state.paiements.isEmpty) {
      return const Center(
        child: Text('Aucun paiement pour le moment', style: TextStyle(color: _C.sub)),
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
                      Text('${p.montant.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: _C.black)),
                      if (p.date != null)
                        Text(_dateFmt.format(p.date!),
                            style: const TextStyle(color: _C.sub, fontSize: 12)),
                    ],
                  ),
                ),
                Text(p.statut,
                    style: TextStyle(
                        color: p.statut == 'reussi' ? _C.green : _C.orange,
                        fontWeight: FontWeight.w700)),
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
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700, color: _C.black)),
          ],
        ),
      );
}
