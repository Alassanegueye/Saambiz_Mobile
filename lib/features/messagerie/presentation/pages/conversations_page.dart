import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:saambiz/core/utils/texte.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/page_vendeur.dart';
import 'package:saambiz/core/widgets/ui_kit.dart';

import '../../../../core/services/socket_service.dart';
import '../../../../core/utils/dates.dart';
import '../../../../injection_container.dart';
import '../../../abonnes/abonnes_page.dart';
import '../bloc/messagerie_bloc.dart';
import '../bloc/messagerie_event.dart';
import '../bloc/messagerie_state.dart';
import 'chat_page.dart';

/// Liste des conversations (GET /messages/conversations), rafraîchie en
/// temps réel via l'événement socket `message:new`.
///
/// Côté vendeur, [pourVendeur] ajoute « Nouveau message » : on choisit un
/// client parmi les abonnés de la boutique. Côté client, une conversation
/// s'ouvre depuis la page d'une boutique (bouton « Message »).
class ConversationsPage extends StatelessWidget {
  final bool pourVendeur;
  const ConversationsPage({super.key, this.pourVendeur = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MessagerieBloc>()..add(LoadConversations()),
      child: _ConversationsView(pourVendeur: pourVendeur),
    );
  }
}

class _ConversationsView extends StatefulWidget {
  final bool pourVendeur;
  const _ConversationsView({required this.pourVendeur});
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

  Future<void> _ouvrirChat(String id, String nom) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(interlocuteurId: id, interlocuteurNom: nom),
      ),
    );
    // Au retour, la conversation qu'on vient d'écrire apparaît en tête.
    if (mounted) context.read<MessagerieBloc>().add(LoadConversations());
  }

  Future<void> _nouveauMessage() async {
    final client = await showModalBottomSheet<Abonne>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChoixClient(),
    );
    if (client != null && mounted) {
      await _ouvrirChat(client.id, client.nomComplet);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageVendeur(
      titre: 'Messages',
      actions: [
        if (widget.pourVendeur)
          BoutonEnteteVendeur(
            icone: Icons.edit_square,
            infobulle: 'Nouveau message',
            principal: true,
            onTap: _nouveauMessage,
          ),
      ],
      corps: BlocConsumer<MessagerieBloc, MessagerieState>(
        listener: (context, state) {
          if (state is MessagerieError) {
            afficherErreur(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is MessagerieLoading || state is MessagerieInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! ConversationsLoaded) {
            return EtatVide(
              icone: Icons.cloud_off_rounded,
              titre: 'Messages indisponibles',
              message: 'Vérifiez votre connexion puis réessayez.',
              action: 'Réessayer',
              onAction: () =>
                  context.read<MessagerieBloc>().add(LoadConversations()),
            );
          }
          if (state.conversations.isEmpty) {
            return widget.pourVendeur
                ? EtatVide(
                    icone: Icons.chat_bubble_outline_rounded,
                    titre: 'Aucune conversation',
                    message:
                        'Écrivez à un client abonné à votre boutique : '
                        'ses réponses arriveront ici.',
                    action: 'Écrire à un client',
                    onAction: _nouveauMessage,
                  )
                : const EtatVide(
                    icone: Icons.chat_bubble_outline_rounded,
                    titre: 'Aucune conversation',
                    message:
                        'Pour écrire à une boutique, ouvrez sa page puis '
                        'touchez « Message ».',
                  );
          }
          return RefreshIndicator(
            color: AppColor.kPrimary,
            onRefresh: () async =>
                context.read<MessagerieBloc>().add(LoadConversations()),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                24 + MediaQuery.of(context).viewPadding.bottom,
              ),
              itemCount: state.conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = state.conversations[i];
                final nonLu = c.nombreNonLus > 0;
                return Material(
                  color: AppColor.kWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: nonLu ? AppColor.kPrimaryBorder : AppColor.kLine,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () =>
                        _ouvrirChat(c.interlocuteurId, c.interlocuteurNom),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _Avatar(
                            nom: c.interlocuteurNom,
                            photo: c.interlocuteurPhoto,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.interlocuteurNom,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: kPolice,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.kGrayscaleDark100,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.dernierMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: kPolice,
                                    fontSize: 13,
                                    fontWeight: nonLu
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: nonLu
                                        ? AppColor.kGrayscaleDark100
                                        : AppColor.kGrayscale40,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (c.dateDernierMessage != null)
                                Text(
                                  heureCourte.format(c.dateDernierMessage!),
                                  style: const TextStyle(
                                    fontFamily: kPolice,
                                    fontSize: 11,
                                    color: AppColor.kGrayscale40,
                                  ),
                                ),
                              if (nonLu)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColor.kPrimary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${c.nombreNonLus}',
                                    style: const TextStyle(
                                      color: AppColor.kWhite,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String nom;
  final String? photo;
  const _Avatar({required this.nom, this.photo});

  @override
  Widget build(BuildContext context) {
    final aPhoto = (photo ?? '').isNotEmpty;
    return CircleAvatar(
      radius: 23,
      backgroundColor: AppColor.kPrimaryLight,
      backgroundImage: aPhoto ? fournisseurImageReseau(photo!) : null,
      child: aPhoto
          ? null
          : Text(
              nom.trim().isEmpty ? '?' : initialesDe(nom),
              style: const TextStyle(
                fontFamily: kPolice,
                fontWeight: FontWeight.w700,
                color: AppColor.kPrimary,
              ),
            ),
    );
  }
}

/// Feuille « Nouveau message » du vendeur : ses clients abonnés, avec une
/// recherche par nom.
class _ChoixClient extends StatefulWidget {
  const _ChoixClient();

  @override
  State<_ChoixClient> createState() => _ChoixClientState();
}

class _ChoixClientState extends State<_ChoixClient> {
  late final Future<List<Abonne>> _abonnes = AbonnesService.charger();
  String _filtre = '';

  @override
  Widget build(BuildContext context) {
    final hauteur = MediaQuery.of(context).size.height * 0.75;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: hauteur,
        decoration: const BoxDecoration(
          color: AppColor.kBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.kGrayscale20,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'Nouveau message',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColor.kGrayscaleDark100,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Choisissez un client abonné à votre boutique.',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 13,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ChampRecherche(
                indication: 'Rechercher un client',
                surFondClair: true,
                onChanged: (v) =>
                    setState(() => _filtre = v.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Abonne>>(
                future: _abonnes,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return const EtatVide(
                      compact: true,
                      icone: Icons.cloud_off_rounded,
                      titre: 'Clients indisponibles',
                      message: 'Vérifiez votre connexion puis réessayez.',
                    );
                  }
                  final tous = snap.data ?? const <Abonne>[];
                  if (tous.isEmpty) {
                    return const EtatVide(
                      compact: true,
                      icone: Icons.people_outline_rounded,
                      titre: 'Pas encore d\'abonnés',
                      message:
                          'Les clients qui suivent votre boutique '
                          'apparaîtront ici.',
                    );
                  }
                  final liste = _filtre.isEmpty
                      ? tous
                      : tous
                            .where(
                              (a) =>
                                  a.nomComplet.toLowerCase().contains(_filtre),
                            )
                            .toList();
                  if (liste.isEmpty) {
                    return const EtatVide(
                      compact: true,
                      icone: Icons.search_off_rounded,
                      titre: 'Aucun client trouvé',
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      8,
                      0,
                      8,
                      16 + MediaQuery.of(context).viewPadding.bottom,
                    ),
                    itemCount: liste.length,
                    itemBuilder: (context, i) {
                      final a = liste[i];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: _Avatar(nom: a.nomComplet, photo: a.photo),
                        title: Text(
                          a.nomComplet,
                          style: const TextStyle(
                            fontFamily: kPolice,
                            fontWeight: FontWeight.w700,
                            color: AppColor.kGrayscaleDark100,
                          ),
                        ),
                        subtitle: a.telephone == null
                            ? null
                            : Text(
                                a.telephone!,
                                style: const TextStyle(
                                  fontFamily: kPolice,
                                  fontSize: 12.5,
                                  color: AppColor.kGrayscale40,
                                ),
                              ),
                        trailing: const Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: AppColor.kPrimaryMedium,
                        ),
                        onTap: () => Navigator.of(context).pop(a),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
