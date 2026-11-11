import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/widgets/ui_kit.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/widgets/page_vendeur.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart';
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
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsBloc>()..add(LoadNotifications()),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
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
                      onTap: () => context.read<NotificationsBloc>().add(
                        MarquerNotificationLue(n.id),
                      ),
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
