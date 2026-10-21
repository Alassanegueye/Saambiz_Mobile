import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart';
import '../../../../core/services/socket_service.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';

class _C {
  static const green = Color(0xFF0D1B3D);
  static const black = Color(0xFF0D1B3D);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF5B6C8A);
  static const border = Color(0xFFE3E8F0);
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
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tout marquer comme lu',
            onPressed: () =>
                context.read<NotificationsBloc>().add(MarquerToutesLues()),
          ),
        ],
      ),
      body: BlocConsumer<NotificationsBloc, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
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
                child: Text('Aucune notification pour le moment',
                    style: TextStyle(color: _C.sub)),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<NotificationsBloc>().add(LoadNotifications()),
              child: ListView.separated(
                itemCount: state.notifications.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: _C.border),
                itemBuilder: (context, i) {
                  final n = state.notifications[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          (n.lue ? _C.sub : _C.green).withOpacity(0.12),
                      child: Icon(Icons.notifications_outlined,
                          color: n.lue ? _C.sub : _C.green),
                    ),
                    title: Text(n.titre,
                        style: TextStyle(
                            fontWeight: n.lue ? FontWeight.w500 : FontWeight.w800)),
                    subtitle: Text(n.message),
                    trailing: Text(DateFormat('dd/MM HH:mm').format(n.date),
                        style: const TextStyle(fontSize: 11, color: _C.sub)),
                    onTap: () => context
                        .read<NotificationsBloc>()
                        .add(MarquerNotificationLue(n.id)),
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
