import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';
import '../widgets/commande_card.dart';
import 'commande_detail_page.dart';

class VendeurCommandesPage extends StatelessWidget {
  const VendeurCommandesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CommandeBloc>()..add(LoadCommandesVendeur()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F2),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: const Color(0xFF1A1A1A),
          title: const Text('Commandes reçues'),
        ),
        body: BlocBuilder<CommandeBloc, CommandeState>(
          builder: (context, state) {
            if (state is CommandeLoading || state is CommandeInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CommandeError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF7A8473))),
                    TextButton(
                      onPressed: () => context
                          .read<CommandeBloc>()
                          .add(LoadCommandesVendeur()),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }
            if (state is CommandesLoaded) {
              if (state.commandes.isEmpty) {
                return const Center(
                  child: Text('Aucune commande reçue',
                      style: TextStyle(color: Color(0xFF7A8473))),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => context
                    .read<CommandeBloc>()
                    .add(LoadCommandesVendeur()),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.commandes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = state.commandes[i];
                    return CommandeCard(
                      commande: c,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRouter.commandeDetailRoute,
                        arguments: CommandeDetailArgs(c, isVendeur: true),
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
    );
  }
}
