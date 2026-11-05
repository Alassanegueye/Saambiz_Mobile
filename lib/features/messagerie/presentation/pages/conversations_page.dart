import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/utils/texte.dart';
import 'package:saambiz/core/widgets/ui_kit.dart';
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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:saambiz/core/utils/image_url.dart';

class _C {
  static const green = Color(0xFF01154B);
  static const black = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F8);
  static const sub = Color(0xFF5B6C8A);
  static const border = Color(0xFFE3E8F0);
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
      appBar: AppBar(title: const Text('Messages')),
      body: BlocConsumer<MessagerieBloc, MessagerieState>(
        listener: (context, state) {
          if (state is MessagerieError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
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
                child: EtatVide(
                  icone: Icons.chat_bubble_outline_rounded,
                  titre: 'Aucune conversation',
                  message: 'Vos échanges avec vos clients apparaîtront ici.',
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<MessagerieBloc>().add(LoadConversations()),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.conversations.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72, color: _C.border),
                itemBuilder: (context, i) {
                  final c = state.conversations[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColor.kPrimaryLight,
                      backgroundImage: (c.interlocuteurPhoto ?? '').isNotEmpty
                          ? CachedNetworkImageProvider(
                              imageOptimisee(c.interlocuteurPhoto!),
                            )
                          : null,
                      child: (c.interlocuteurPhoto ?? '').isEmpty
                          ? Text(
                              c.interlocuteurNom.trim().isEmpty
                                  ? '?'
                                  : initialesDe(c.interlocuteurNom),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColor.kPrimary,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      c.interlocuteurNom,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      c.dernierMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (c.dateDernierMessage != null)
                          Text(
                            DateFormat('HH:mm').format(c.dateDernierMessage!),
                            style: const TextStyle(fontSize: 11, color: _C.sub),
                          ),
                        if (c.nombreNonLus > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _C.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${c.nombreNonLus}',
                              style: const TextStyle(
                                color: _C.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            interlocuteurId: c.interlocuteurId,
                            interlocuteurNom: c.interlocuteurNom,
                          ),
                        ),
                      );
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
