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
import '../../../../core/routes/app_router.dart';
import '../../../abonnement/presentation/pages/mon_abonnement_page.dart';
import '../../../catalogue/presentation/pages/boutique_publique_page.dart';
import '../../../commande/data/datasources/commande_remote_datasource.dart';
import '../../../commande/presentation/pages/commande_detail_page.dart'
    show CommandeDetailArgs;
import '../destination_notification.dart';
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

  /// Une notification en cours d'ouverture : la fiche d'une commande demande
  /// un aller-retour au serveur, et deux appuis ne doivent pas ouvrir deux
  /// écrans.
  String? _enOuverture;

  /// Toucher une notification la marque comme lue et ouvre l'écran qu'elle
  /// annonce : la commande concernée, la boutique qui publie, l'abonnement,
  /// ou la conversation. Voir `destinationNotification` pour la règle.
  Future<void> _ouvrir(NotificationModel n) async {
    if (_enOuverture != null) return;
    if (!n.lue) {
      context.read<NotificationsBloc>().add(MarquerNotificationLue(n.id));
    }

    final destination = destinationNotification(n);
    final navigateur = Navigator.of(context);

    switch (destination.cible) {
      case CibleNotification.commande:
        // La notification ne porte que l'identifiant ; la fiche attend la
        // commande entière. On la lit, en montrant que quelque chose se passe.
        setState(() => _enOuverture = n.id);
        try {
          final commande = await sl<CommandeRemoteDataSource>().getCommande(
            destination.id!,
          );
          if (!mounted) return;
          navigateur.pushNamed(
            AppRouter.commandeDetailRoute,
            arguments: CommandeDetailArgs(
              commande,
              isVendeur: widget.pourVendeur,
            ),
          );
        } catch (_) {
          // Commande supprimee, ou reseau coupe : le dire, et ne pas bouger.
          if (mounted) {
            afficherErreur(context, 'Cette commande n’est plus accessible.');
          }
        } finally {
          if (mounted) setState(() => _enOuverture = null);
        }

      case CibleNotification.boutique:
        navigateur.push(
          MaterialPageRoute(
            builder: (_) => BoutiquePubliquePage(boutiqueId: destination.id!),
          ),
        );

      case CibleNotification.abonnement:
        navigateur.push(
          MaterialPageRoute(builder: (_) => const MonAbonnementPage()),
        );

      case CibleNotification.conversation:
        navigateur.push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              interlocuteurId: destination.id!,
              interlocuteurNom: n.interlocuteurNom.isNotEmpty
                  ? n.interlocuteurNom
                  : n.titre,
            ),
          ),
        );

      case CibleNotification.messagerie:
        navigateur.push(
          MaterialPageRoute(
            builder: (_) => ConversationsPage(pourVendeur: widget.pourVendeur),
          ),
        );
    }
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
                              // Ouvrir une commande demande un aller-retour au
                              // serveur : sans ce signe, l'appui semble perdu.
                              child: _enOuverture == n.id
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: n.lue
                                            ? AppColor.kPrimary
                                            : AppColor.kWhite,
                                      ),
                                    )
                                  : Icon(
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
