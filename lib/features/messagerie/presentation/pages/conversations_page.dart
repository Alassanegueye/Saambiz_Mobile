import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart';
import '../../../../core/services/socket_service.dart';
import '../bloc/messagerie_bloc.dart';
import '../bloc/messagerie_event.dart';
import '../bloc/messagerie_state.dart';
import 'chat_page.dart';

class _C {
  static const green = Color(0xFF1B3A6B);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7F2);
  static const sub = Color(0xFF7A8473);
  static const border = Color(0xFFE3EAD0);
}

/// Liste des conversations (GET /messages/conversations), rafraîchie en
/// temps réel via l'événement socket `message:new`.
class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MessagerieBloc>()..add(LoadConversations()),
      child: const _ConversationsView(),
    );
  }
}

class _ConversationsView extends StatefulWidget {
  const _ConversationsView();
  @override
  State<_ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<_ConversationsView> {
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = sl<SocketService>().onNewMessage.listen((_) {
      if (mounted) context.read<MessagerieBloc>().add(LoadConversations());
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: const Text('Messages'),
      ),
      body: BlocConsumer<MessagerieBloc, MessagerieState>(
        listener: (context, state) {
          if (state is MessagerieError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is MessagerieLoading || state is MessagerieInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ConversationsLoaded) {
            if (state.conversations.isEmpty) {
              return const Center(
                child: Text('Aucune conversation pour le moment',
                    style: TextStyle(color: _C.sub)),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<MessagerieBloc>().add(LoadConversations()),
              child: ListView.separated(
                itemCount: state.conversations.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: _C.border),
                itemBuilder: (context, i) {
                  final c = state.conversations[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _C.green.withOpacity(0.15),
                      backgroundImage: (c.interlocuteurPhoto ?? '').isNotEmpty
                          ? NetworkImage(c.interlocuteurPhoto!)
                          : null,
                      child: (c.interlocuteurPhoto ?? '').isEmpty
                          ? Text(
                              c.interlocuteurNom.isNotEmpty
                                  ? c.interlocuteurNom[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: _C.green))
                          : null,
                    ),
                    title: Text(c.interlocuteurNom,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(c.dernierMessage,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (c.dateDernierMessage != null)
                          Text(DateFormat('HH:mm').format(c.dateDernierMessage!),
                              style: const TextStyle(fontSize: 11, color: _C.sub)),
                        if (c.nombreNonLus > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _C.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${c.nombreNonLus}',
                                style: const TextStyle(
                                    color: _C.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatPage(
                          interlocuteurId: c.interlocuteurId,
                          interlocuteurNom: c.interlocuteurNom,
                        ),
                      ));
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
