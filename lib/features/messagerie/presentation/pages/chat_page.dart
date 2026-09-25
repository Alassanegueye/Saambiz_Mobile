import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../../../core/services/socket_service.dart';
import '../bloc/messagerie_bloc.dart';
import '../bloc/messagerie_event.dart';
import '../bloc/messagerie_state.dart';

class _C {
  static const green = Color(0xFF1B3A6B);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7F2);
  static const sub = Color(0xFF7A8473);
  static const border = Color(0xFFE3EAD0);
}

/// Conversation 1-à-1 (GET /messages/:userId + POST /messages), mise à jour
/// en temps réel via l'événement socket `message:new`.
class ChatPage extends StatelessWidget {
  final String interlocuteurId;
  final String interlocuteurNom;
  const ChatPage({super.key, required this.interlocuteurId, required this.interlocuteurNom});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MessagerieBloc>()..add(LoadHistorique(interlocuteurId)),
      child: _ChatView(interlocuteurId: interlocuteurId, interlocuteurNom: interlocuteurNom),
    );
  }
}

class _ChatView extends StatefulWidget {
  final String interlocuteurId;
  final String interlocuteurNom;
  const _ChatView({required this.interlocuteurId, required this.interlocuteurNom});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _msgCtrl = TextEditingController();
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = sl<SocketService>().onNewMessage.listen((data) {
      if (mounted) context.read<MessagerieBloc>().add(MessageRecuTempsReel(data));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _msgCtrl.dispose();
    super.dispose();
  }

  void _envoyer() {
    if (_msgCtrl.text.trim().isEmpty) return;
    context.read<MessagerieBloc>().add(EnvoyerMessage(
          destinataireId: widget.interlocuteurId,
          contenu: _msgCtrl.text.trim(),
        ));
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: Text(widget.interlocuteurNom),
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
          final loading = state is MessagerieLoading;
          final messages = state is HistoriqueLoaded ? state.messages : const [];
          return Column(
            children: [
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[messages.length - 1 - i];
                          final mine = m.destinataireId == widget.interlocuteurId;
                          return Align(
                            alignment:
                                mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: mine ? _C.green : _C.white,
                                borderRadius: BorderRadius.circular(14),
                                border: mine ? null : Border.all(color: _C.border),
                              ),
                              child: Text(
                                m.contenu,
                                style: TextStyle(color: mine ? _C.white : _C.black),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: _C.white,
                  border: Border(top: BorderSide(color: _C.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          decoration: InputDecoration(
                            hintText: 'Écrire un message...',
                            filled: true,
                            fillColor: _C.bg,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: _C.green,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: _C.white, size: 18),
                          onPressed: _envoyer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
