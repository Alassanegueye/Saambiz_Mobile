import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/widgets/ui_kit.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/widgets/page_vendeur.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart';
import '../../../home/domain/entities/notification_model.dart';
import '../../../messagerie/presentation/pages/chat_page.dart';
import '../../../messagerie/presentation/pages/conversations_page.dart';
import '../../../../core/services/socket_service.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';

class _C {
  static const sub = Color(0xFF5B6C8A);
}

/// Notifications (GET /notifications), mises à jour en temps réel via
/// l'événement socket `notification:new`.
class NotificationsPage extends StatelessWidget {
  /// Espace vendeur : la messagerie s'ouvre côté vendeur.
  final bool pourVendeur;
  const NotificationsPage({super.key, this.pourVendeur = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsBloc>()..add(LoadNotifications()),
      child: _NotificationsView(pourVendeur: pourVendeur),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  final bool pourVendeur;
  const _NotificationsView({required this.pourVendeur});
  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = sl<SocketService>().onNewNotification.listen((data) {
      if (mounted) {
        context.read<NotificationsBloc>().add(NotificationRecueTempsReel(data));
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Toucher une notification la marque comme lue et ouvre la conversation
  /// concernée : celle avec la boutique (ou le client) qui l'a envoyée. Les
  /// anciennes notifications, sans interlocuteur connu, ouvrent la messagerie.
  void _ouvrir(NotificationModel n) {
    if (!n.lue) {
      context.read<NotificationsBloc>().add(MarquerNotificationLue(n.id));
    }
    final id = n.interlocuteurId;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => id != null
            ? ChatPage(
                interlocuteurId: id,
                interlocuteurNom: n.interlocuteurNom.isNotEmpty
                    ? n.interlocuteurNom
                    : n.titre,
              )
            : ConversationsPage(pourVendeur: widget.pourVendeur),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageVendeur(
      titre: 'Notifications',
      actions: [
        BoutonEnteteVendeur(
          icone: Icons.done_all_rounded,
          infobulle: 'Tout marquer comme lu',
          onTap: () =>
              context.read<NotificationsBloc>().add(MarquerToutesLues()),
        ),
      ],
      corps: BlocConsumer<NotificationsBloc, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationsError) {
            afficherErreur(context, state.message);
          } else if (state is NotificationsLoaded && state.succes != null) {
            afficherSucces(context, state.succes!);
          }
        },
        builder: (context, state) {
          if (state is NotificationsLoading || state is NotificationsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return const Center(
                child: EtatVide(
                  icone: Icons.notifications_none_rounded,
                  titre: 'Aucune notification',
                  message: 'Vos commandes et vos alertes apparaîtront ici.',
                ),
              );
            }
            return RefreshIndicator(
              color: AppColor.kPrimary,
              onRefresh: () async =>
                  context.read<NotificationsBloc>().add(LoadNotifications()),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: state.notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final n = state.notifications[i];
                  return Material(
                    color: n.lue ? AppColor.kWhite : AppColor.kPrimaryLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: n.lue ? AppColor.kLine : Colors.transparent,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _ouvrir(n),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: n.lue
                                  ? AppColor.kPrimaryLight
                                  : AppColor.kPrimary,
                              child: Icon(
                                Icons.notifications_none_rounded,
                                size: 20,
                                color: n.lue
                                    ? AppColor.kPrimary
                                    : AppColor.kWhite,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.titre,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColor.kGrayscaleDark100,
                                      fontWeight: n.lue
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    n.message,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: _C.sub,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('dd/MM à HH:mm').format(n.date),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: _C.sub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
