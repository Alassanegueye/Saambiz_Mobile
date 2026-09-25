import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';
import '../widgets/commande_card.dart';
import 'commande_detail_page.dart';

class MesCommandesPage extends StatelessWidget {
  const MesCommandesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CommandeBloc>()..add(LoadMesCommandes()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F2),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: const Color(0xFF1A1A1A),
          title: const Text('Mes commandes'),
        ),
        body: BlocBuilder<CommandeBloc, CommandeState>(
          builder: (context, state) {
            if (state is CommandeLoading || state is CommandeInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CommandeError) {
              return _Erreur(
                message: state.message,
                onRetry: () =>
                    context.read<CommandeBloc>().add(LoadMesCommandes()),
              );
            }
            if (state is CommandesLoaded) {
              if (state.commandes.isEmpty) {
                return const Center(
                  child: Text('Aucune commande pour le moment',
                      style: TextStyle(color: Color(0xFF7A8473))),
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<CommandeBloc>().add(LoadMesCommandes()),
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
                        arguments: CommandeDetailArgs(c),
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
          const Icon(Icons.error_outline, color: Color(0xFF7A8473), size: 48),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF7A8473))),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

