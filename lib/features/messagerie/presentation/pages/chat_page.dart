import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/page_vendeur.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/police.dart';
import '../../../../core/utils/texte.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/socket_service.dart';
import '../../data/models/message_model.dart';
import '../bloc/messagerie_bloc.dart';
import '../bloc/messagerie_event.dart';
import '../bloc/messagerie_state.dart';
import '../../../../core/services/fcm_service.dart';

/// Le jour d'un message, pour les séparateurs : « Aujourd'hui », « Hier »,
/// sinon la date en toutes lettres.
String libelleJourMessage(DateTime date, {DateTime? maintenant}) {
  final m = maintenant ?? DateTime.now();
  final d = date.toLocal();
  final ecart = DateTime(
    m.year,
    m.month,
    m.day,
  ).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (ecart <= 0) return 'Aujourd’hui';
  if (ecart == 1) return 'Hier';
  return dateLongue(d);
}

/// Conversation 1-à-1 (GET /messages/:userId + POST /messages), mise à jour
/// en temps réel via l'événement socket `message:new`.
class ChatPage extends StatelessWidget {
  final String interlocuteurId;
  final String interlocuteurNom;
  const ChatPage({
    super.key,
    required this.interlocuteurId,
    required this.interlocuteurNom,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MessagerieBloc>()..add(LoadHistorique(interlocuteurId)),
      child: _ChatView(
        interlocuteurId: interlocuteurId,
        interlocuteurNom: interlocuteurNom,
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final String interlocuteurId;
  final String interlocuteurNom;
  const _ChatView({
    required this.interlocuteurId,
    required this.interlocuteurNom,
  });

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _msgCtrl = TextEditingController();
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    // Tant que cette conversation est à l'écran, pas de bannière pour ses
    // propres messages : ils arrivent déjà dans le fil.
    FcmService.conversationOuverte(widget.interlocuteurId);
    _sub = sl<SocketService>().onNewMessage.listen((data) {
      if (mounted) {
        context.read<MessagerieBloc>().add(MessageRecuTempsReel(data));
      }
    });
  }

  @override
  void dispose() {
    FcmService.conversationOuverte(null);
    _sub?.cancel();
    _msgCtrl.dispose();
    super.dispose();
  }

  void _envoyer() {
    if (_msgCtrl.text.trim().isEmpty) return;
    context.read<MessagerieBloc>().add(
      EnvoyerMessage(
        destinataireId: widget.interlocuteurId,
        contenu: _msgCtrl.text.trim(),
      ),
    );
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final nom = widget.interlocuteurNom;
    return ScaffoldMarine(
      // La zone de saisie est blanche : en donnant ce fond au Scaffold,
      // elle reste collée au clavier au lieu de laisser paraître un
      // liseré derrière ses coins arrondis.
      fondClavier: AppColor.kWhite,
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppColor.kWhite,
              child: Text(
                initialesDe(nom).isEmpty ? '?' : initialesDe(nom),
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(nom, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: BlocConsumer<MessagerieBloc, MessagerieState>(
        listener: (context, state) {
          if (state is MessagerieError) {
            afficherErreur(context, state.message);
          }
        },
        builder: (context, state) {
          final loading = state is MessagerieLoading;
          final messages = state is HistoriqueLoaded
              ? state.messages
              : const <MessageModel>[];

          // Dans l'ordre du fil, un séparateur à chaque changement de jour ;
          // la liste s'affiche à l'envers, le plus récent en bas.
          final maintenant = DateTime.now();
          final entrees = <Object>[];
          String? jour;
          for (final m in messages) {
            final date = m.createdAt;
            if (date != null) {
              final j = libelleJourMessage(date, maintenant: maintenant);
              if (j != jour) {
                entrees.add(j);
                jour = j;
              }
            }
            entrees.add(m);
          }

          return Column(
            children: [
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColor.kPrimary,
                        ),
                      )
                    : entrees.isEmpty
                    ? _FilVide(nom: nom)
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        itemCount: entrees.length,
                        itemBuilder: (context, i) {
                          final e = entrees[entrees.length - 1 - i];
                          if (e is String) return _SeparateurJour(e);
                          final m = e as MessageModel;
                          return _Bulle(
                            message: m,
                            mien: m.destinataireId == widget.interlocuteurId,
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: const BoxDecoration(
                  color: AppColor.kWhite,
                  border: Border(top: BorderSide(color: AppColor.kLine)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Écrire un message…',
                            filled: true,
                            fillColor: AppColor.kSurface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(
                                color: AppColor.kLine,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(
                                color: AppColor.kLine,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColor.kPrimary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _envoyer,
                          child: const SizedBox(
                            width: 46,
                            height: 46,
                            child: Icon(
                              Icons.send_rounded,
                              color: AppColor.kWhite,
                              size: 20,
                              semanticLabel: 'Envoyer',
                            ),
                          ),
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

/// Le jour, en pastille au milieu du fil.
class _SeparateurJour extends StatelessWidget {
  final String texte;
  const _SeparateurJour(this.texte);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColor.kBackground2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            texte,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColor.kGrayscale40,
            ),
          ),
        ),
      ),
    );
  }
}

/// Une bulle : le texte, l'heure, et pour ses propres messages une coche
/// (envoyé) ou deux (lu).
class _Bulle extends StatelessWidget {
  final MessageModel message;
  final bool mien;
  const _Bulle({required this.message, required this.mien});

  @override
  Widget build(BuildContext context) {
    final date = message.createdAt?.toLocal();
    final couleurTexte = mien ? AppColor.kWhite : AppColor.kGrayscaleDark100;
    final couleurHeure = mien
        ? AppColor.kWhite.withValues(alpha: 0.7)
        : AppColor.kGrayscale40;
    const rond = Radius.circular(18);
    const pointe = Radius.circular(5);
    return Align(
      alignment: mien ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 9, 12, 7),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: mien ? AppColor.kPrimary : AppColor.kWhite,
          borderRadius: BorderRadius.only(
            topLeft: rond,
            topRight: rond,
            bottomLeft: mien ? rond : pointe,
            bottomRight: mien ? pointe : rond,
          ),
          border: mien ? null : Border.all(color: AppColor.kLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Text(
                message.contenu,
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 14.5,
                  height: 1.35,
                  color: couleurTexte,
                ),
              ),
            ),
            if (date != null) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(date),
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 10.5,
                      color: couleurHeure,
                    ),
                  ),
                  if (mien) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.lu ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 14,
                      color: message.lu ? AppColor.kSecondary : couleurHeure,
                      semanticLabel: message.lu ? 'Lu' : 'Envoyé',
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Aucun message encore : une invitation plutôt qu'un écran vide.
class _FilVide extends StatelessWidget {
  final String nom;
  const _FilVide({required this.nom});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColor.kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColor.kPrimary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Écrivez votre premier message',
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Une question sur un produit, une livraison ? $nom vous répond ici.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 13,
                height: 1.4,
                color: AppColor.kGrayscale40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
