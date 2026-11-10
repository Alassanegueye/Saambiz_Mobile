import 'package:saambiz/core/widgets/onglets_conserves.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/page_vendeur.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/routes/app_router.dart';
import '../../data/models/commande_model.dart';
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';
import '../widgets/commande_card.dart';
import 'commande_detail_page.dart';
import 'nouvelle_commande_vendeur_page.dart';
import '../../../../core/theme/police.dart';

class VendeurCommandesPage extends StatelessWidget {
  const VendeurCommandesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CommandeBloc>()..add(LoadCommandesVendeur()),
      child: ActualiserAuRetour(
        onRetour: (context) =>
            context.read<CommandeBloc>().add(LoadCommandesVendeur()),
        child: Builder(
          builder: (context) => PageVendeur(
          titre: 'Commandes',
          boutonFlottant: FloatingActionButton.extended(
            onPressed: () async {
              final bloc = context.read<CommandeBloc>();
              final creee = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const NouvelleCommandeVendeurPage(),
                ),
              );
              if (creee == true) bloc.add(LoadCommandesVendeur());
            },
            backgroundColor: AppColor.kSecondary,
            foregroundColor: AppColor.kPrimary,
            elevation: 2,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Nouvelle commande',
              style: TextStyle(fontFamily: kPolice, fontWeight: FontWeight.w700),
            ),
          ),
          corps: BlocBuilder<CommandeBloc, CommandeState>(
            buildWhen: (avant, apres) =>
                !(apres is CommandeLoading && avant is CommandesLoaded),
            builder: (context, state) {
              if (state is CommandeLoading || state is CommandeInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is CommandeError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF5B6C8A)),
                      ),
                      TextButton(
                        onPressed: () => context.read<CommandeBloc>().add(
                          LoadCommandesVendeur(),
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }
              if (state is CommandesLoaded) {
                return _ListeCommandes(commandes: state.commandes);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        ),
      ),
    );
  }
}

/// Les commandes, classées par ce qu'elles demandent au vendeur.
class _ListeCommandes extends StatefulWidget {
  final List<CommandeModel> commandes;
  const _ListeCommandes({required this.commandes});

  @override
  State<_ListeCommandes> createState() => _ListeCommandesState();
}

class _ListeCommandesState extends State<_ListeCommandes> {
  static const _filtres = <String, Set<String>?>{
    'Toutes': null,
    'À traiter': {'en_attente'},
    'En cours': {
      'acceptee',
      'payee',
      'confirmee',
      'en_preparation',
      'prete',
      'en_livraison',
    },
    'Terminées': {'livree', 'annulee', 'rejetee'},
  };
  String _filtre = 'Toutes';

  @override
  Widget build(BuildContext context) {
    final statuts = _filtres[_filtre];
    final visibles = statuts == null
        ? widget.commandes
        : widget.commandes.where((c) => statuts.contains(c.statut)).toList();
    return Column(
      children: [
        // Les puces restent DANS la feuille : marge haute qui dépasse
        // l'arrondi des coins, et défilement coupé avant les bords pour
        // qu'aucune puce ne glisse sur la courbe.
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 8),
          child: SizedBox(
          height: 40,
          child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            children: [
              for (final entree in _filtres.entries) ...[
                PuceFiltre(
                  libelle: entree.value == null
                      ? entree.key
                      : '${entree.key} (${widget.commandes.where((c) => entree.value!.contains(c.statut)).length})',
                  active: _filtre == entree.key,
                  onTap: () => setState(() => _filtre = entree.key),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColor.kPrimary,
            onRefresh: () async =>
                context.read<CommandeBloc>().add(LoadCommandesVendeur()),
            child: visibles.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 90),
                      EtatVide(
                        icone: Icons.receipt_long_outlined,
                        titre: widget.commandes.isEmpty
                            ? 'Aucune commande reçue'
                            : 'Aucune commande ici',
                        message: widget.commandes.isEmpty
                            ? 'Les commandes de vos clients apparaîtront ici dès leur passage.'
                            : 'Choisissez un autre filtre pour voir vos commandes.',
                      ),
                    ],
                  )
                : ListView.separated(
                    // +72 : le bouton « Nouvelle commande » ne masque pas la dernière carte.
                    padding: EdgeInsets.fromLTRB(16, 4, 16, espaceBasVendeur(context) + 72),
                    itemCount: visibles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = visibles[i];
                      return CommandeCard(
                        commande: c,
                        isVendeur: true,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRouter.commandeDetailRoute,
                          arguments: CommandeDetailArgs(c, isVendeur: true),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
