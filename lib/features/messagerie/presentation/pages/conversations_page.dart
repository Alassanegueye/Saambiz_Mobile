import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/core/utils/texte.dart';
import 'package:saambiz/core/widgets/ui_kit.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../../../core/services/socket_service.dart';
import '../bloc/messagerie_bloc.dart';
import '../bloc/messagerie_event.dart';
import '../bloc/messagerie_state.dart';
import 'chat_page.dart';
import '../../data/datasources/messages_site_datasource.dart';
import '../../data/models/message_model.dart';
import '../../../../core/utils/url_externe.dart';
import '../../../../core/widgets/page_vendeur.dart';
import '../../../../core/utils/dates.dart';

class _C {
  static const green = Color(0xFF01154B);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F8);
  static const sub = Color(0xFF5B6C8A);
  static const border = Color(0xFFE3E8F0);
}

/// « Messages » : les messages laissés sur la page Contact du site de la
/// boutique (en tête, ce sont des clients qui attendent une réponse), puis
/// les conversations dans l'application (GET /messages/conversations),
/// rafraîchies en temps réel via l'événement socket `message:new`.
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
  final _site = MessagesSiteDataSource(sl());
  List<MessageSite> _messagesSite = const [];

  @override
  void initState() {
    super.initState();
    _chargerSite();
    _sub = sl<SocketService>().onNewMessage.listen((_) {
      if (mounted) context.read<MessagerieBloc>().add(LoadConversations());
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Un acheteur n'a pas de site : la liste revient vide, et une erreur ici
  /// ne doit pas masquer ses conversations.
  Future<void> _chargerSite() async {
    try {
      final liste = await _site.lister();
      if (mounted) setState(() => _messagesSite = liste);
    } catch (_) {}
  }

  Future<void> _rafraichir() async {
    context.read<MessagerieBloc>().add(LoadConversations());
    await _chargerSite();
  }

  void _ouvrirMessageSite(MessageSite m) {
    if (!m.lu) {
      setState(() {
        _messagesSite = [
          for (final x in _messagesSite) x.id == m.id ? x.copieLu() : x,
        ];
      });
      _site.marquerLu(m.id).catchError((_) {});
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (feuille) => _DetailMessageSite(
        message: m,
        onSupprimer: () async {
          Navigator.of(feuille).pop();
          try {
            await _site.supprimer(m.id);
            if (!mounted) return;
            setState(() {
              _messagesSite = _messagesSite.where((x) => x.id != m.id).toList();
            });
            _dire('Message supprimé.');
          } catch (_) {
            _dire('Suppression impossible. Vérifiez votre connexion.');
          }
        },
      ),
    );
  }

  void _dire(String texte) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(texte), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMarine(
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
          final enChargement =
              state is MessagerieLoading || state is MessagerieInitial;
          final List<ConversationModel> conversations =
              state is ConversationsLoaded ? state.conversations : const [];
          if (enChargement && _messagesSite.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final elements = <Widget>[];
          if (_messagesSite.isNotEmpty) {
            final nonLus = _messagesSite.where((m) => !m.lu).length;
            elements.add(
              _TitreSection(
                titre: 'Depuis votre site',
                detail: nonLus > 0
                    ? '$nonLus non lu${nonLus > 1 ? 's' : ''}'
                    : null,
              ),
            );
            for (final m in _messagesSite) {
              elements.add(
                _TuileMessageSite(
                  message: m,
                  onTap: () => _ouvrirMessageSite(m),
                ),
              );
            }
          }
          if (conversations.isNotEmpty) {
            if (_messagesSite.isNotEmpty) {
              elements.add(const _TitreSection(titre: 'Conversations'));
            }
            for (var i = 0; i < conversations.length; i++) {
              if (i > 0) {
                elements.add(
                  const Divider(height: 1, indent: 72, color: _C.border),
                );
              }
              elements.add(_tuileConversation(context, conversations[i]));
            }
          }

          return RefreshIndicator(
            onRefresh: _rafraichir,
            child: elements.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      EtatVide(
                        icone: Icons.chat_bubble_outline_rounded,
                        titre: 'Aucun message',
                        message:
                            'Vos échanges avec vos clients, et les messages laissés sur votre site, apparaîtront ici.',
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: 24 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: elements,
                  ),
          );
        },
      ),
    );
  }

  Widget _tuileConversation(BuildContext context, ConversationModel c) {
    return ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColor.kPrimaryLight,
          backgroundImage: (c.interlocuteurPhoto ?? '').isNotEmpty
              ? fournisseurImageReseau(c.interlocuteurPhoto!)
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
                heureCourte.format(c.dateDernierMessage!),
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
  }
}

class _TitreSection extends StatelessWidget {
  final String titre;
  final String? detail;
  const _TitreSection({required this.titre, this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            titre,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _C.sub,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColor.kPrimaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                detail!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Un message du site dans la liste : l'auteur, le début du message, la date.
class _TuileMessageSite extends StatelessWidget {
  final MessageSite message;
  final VoidCallback onTap;
  const _TuileMessageSite({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = message;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: m.lu ? _C.border : AppColor.kPrimary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColor.kPrimaryLight,
                  child: const Icon(
                    Icons.language_rounded,
                    size: 20,
                    color: AppColor.kPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.auteur,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: m.lu ? FontWeight.w600 : FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (m.date != null)
                            Text(
                              _quand(m.date!),
                              style: const TextStyle(fontSize: 11, color: _C.sub),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        m.contenu,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          color: m.lu ? _C.sub : const Color(0xFF1E2A44),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!m.lu) ...[
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColor.kPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Aujourd'hui : l'heure ; sinon : la date.
String _quand(DateTime d) {
  final maintenant = DateTime.now();
  final memeJour = d.year == maintenant.year &&
      d.month == maintenant.month &&
      d.day == maintenant.day;
  return memeJour ? heureCourte.format(d) : dateCourte.format(d);
}

/// Le message en entier, et les deux façons de répondre au visiteur.
class _DetailMessageSite extends StatelessWidget {
  final MessageSite message;
  final VoidCallback onSupprimer;
  const _DetailMessageSite({required this.message, required this.onSupprimer});

  Future<void> _ouvrir(BuildContext context, String url) async {
    final ok = await UrlExterne.lancer(url);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir ce lien sur cet appareil.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = message;
    final chiffres = m.telephone.replaceAll(RegExp(r'\D'), '');
    final texte = Uri.encodeComponent(
      'Bonjour${(m.nom ?? '').trim().isEmpty ? '' : ' ${m.nom!.trim()}'}, '
      'merci pour votre message sur notre site. ',
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              m.auteur,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              [
                m.telephone,
                if (m.date != null) dateEtHeure.format(m.date!),
              ].join('  ·  '),
              style: const TextStyle(fontSize: 13, color: _C.sub),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.4,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    m.contenu,
                    style: const TextStyle(fontSize: 15, height: 1.45),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    _ouvrir(context, 'https://wa.me/$chiffres?text=$texte'),
                icon: const Icon(Icons.chat_rounded, size: 19),
                label: const Text('Répondre sur WhatsApp'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1FA855),
                  foregroundColor: _C.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _ouvrir(context, 'tel:+$chiffres'),
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: const Text('Appeler'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSupprimer,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Supprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
