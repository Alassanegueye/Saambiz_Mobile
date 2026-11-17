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
import '../../../../core/widgets/barre_pagination.dart';
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
            // Groupées par jour, dans l'ordre du serveur (les plus
            // récentes d'abord) : un titre à chaque changement de jour.
            final maintenant = DateTime.now();
            final lignes = <Object>[];
            String? jour;
            for (final n in state.notifications) {
              final j = libelleJourNotification(n.date, maintenant: maintenant);
              if (j != jour) {
                lignes.add(j);
                jour = j;
              }
              lignes.add(n);
            }
            return RefreshIndicator(
              color: AppColor.kPrimary,
              onRefresh: () async => context.read<NotificationsBloc>().add(
                LoadNotifications(page: state.pagination.page),
              ),
              // +1 : la barre « Précédent / Suivant » en pied de liste. Les
              // intertitres par jour valent pour la page affichée.
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: lignes.length + 1,
                itemBuilder: (context, i) {
                  if (i == lignes.length) {
                    return BarrePagination(
                      pagination: state.pagination,
                      onPage: (page) => context.read<NotificationsBloc>().add(
                        LoadNotifications(page: page),
                      ),
                    );
                  }
                  final ligne = lignes[i];
                  if (ligne is String) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(4, i == 0 ? 8 : 18, 4, 8),
                      child: Text(
                        ligne,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: AppColor.kGrayscale40,
                        ),
                      ),
                    );
                  }
                  final n = ligne as NotificationModel;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LigneNotification(
                      notification: n,
                      maintenant: maintenant,
                      // Ouvrir une commande demande un aller-retour au
                      // serveur : sans ce signe, l'appui semble perdu.
                      enOuverture: _enOuverture == n.id,
                      onTap: () => _ouvrir(n),
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

/// Le jour d'une notification, pour les titres de groupe.
String libelleJourNotification(DateTime date, {DateTime? maintenant}) {
  final m = maintenant ?? DateTime.now();
  final d = date.toLocal();
  final ecart = DateTime(
    m.year,
    m.month,
    m.day,
  ).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (ecart <= 0) return 'Aujourd’hui';
  if (ecart == 1) return 'Hier';
  if (ecart < 7) return 'Cette semaine';
  return 'Plus tôt';
}

/// L'icône et la couleur d'une notification, d'après ce qu'elle annonce.
/// Le type passe avant le reste, comme pour l'écran à ouvrir : une
/// notification de commande qui nomme un interlocuteur reste une commande.
({IconData icone, Color couleur}) apparenceNotification(NotificationModel n) {
  switch (n.type) {
    case 'commande':
      return (icone: Icons.receipt_long_rounded, couleur: AppColor.kPrimary);
    case 'promotion':
      return (
        icone: Icons.local_offer_rounded,
        couleur: AppColor.kSecondaryDark,
      );
    case 'nouveau_produit':
      return (
        icone: Icons.new_releases_rounded,
        couleur: AppColor.kPrimaryMedium,
      );
    case 'abonnement':
      return (
        icone: Icons.workspace_premium_rounded,
        couleur: AppColor.kSecondaryDark,
      );
  }
  if (n.interlocuteurId != null) {
    return (icone: Icons.chat_bubble_rounded, couleur: AppColor.kSucces);
  }
  return (icone: Icons.notifications_rounded, couleur: AppColor.kGrayscale60);
}

/// Une notification : icône du type, titre, message, heure ; fond teinté et
/// point tant qu'elle n'est pas lue.
class _LigneNotification extends StatelessWidget {
  final NotificationModel notification;
  final DateTime maintenant;
  final bool enOuverture;
  final VoidCallback onTap;
  const _LigneNotification({
    required this.notification,
    required this.maintenant,
    required this.enOuverture,
    required this.onTap,
  });

  String _heure() {
    final d = notification.date.toLocal();
    final ecart = maintenant.difference(d);
    if (libelleJourNotification(d, maintenant: maintenant) == 'Aujourd’hui') {
      if (ecart.inMinutes < 1) return 'À l’instant';
      if (ecart.inMinutes < 60) return 'Il y a ${ecart.inMinutes} min';
      return 'Il y a ${ecart.inHours} h';
    }
    return DateFormat('dd/MM à HH:mm').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final a = apparenceNotification(n);
    return Material(
      color: n.lue ? AppColor.kWhite : AppColor.kPrimaryLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: n.lue ? AppColor.kLine : Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: n.lue
                      ? a.couleur.withValues(alpha: 0.10)
                      : AppColor.kWhite,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: enOuverture
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: a.couleur,
                        ),
                      )
                    : Icon(a.icone, size: 21, color: a.couleur),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            n.titre,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: AppColor.kGrayscaleDark100,
                              fontWeight: n.lue
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _heure(),
                          style: const TextStyle(fontSize: 11.5, color: _C.sub),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            n.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: _C.sub,
                            ),
                          ),
                        ),
                        if (!n.lue) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: const BoxDecoration(
                              color: AppColor.kPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
