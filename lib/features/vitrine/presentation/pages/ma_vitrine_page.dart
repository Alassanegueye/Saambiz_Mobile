import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/vitrine.dart';
import '../bloc/vitrine_bloc.dart';
import '../bloc/vitrine_event.dart';
import '../bloc/vitrine_state.dart';
import 'assistant_vitrine_page.dart';

/// Palette locale — même convention que les autres écrans vendeur.
class _C {
  static const navy      = Color(0xFF0D1B3D);
  static const navyLight = Color(0xFFE8EDF7);
  static const gold      = Color(0xFFF2B705);
  static const bg        = Color(0xFFF7F9FC);
  static const white     = Color(0xFFFFFFFF);
  static const border    = Color(0xFFE2E7F0);
  static const text      = Color(0xFF0D1B3D);
  static const muted     = Color(0xFF5B6C8A);
  static const success   = Color(0xFF15803D);
  static const successBg = Color(0xFFE9F8EE);
}

/// « Mon site web » — le point d'entrée du site public de la boutique.
///
/// Deux écrans en un, selon que le site existe ou non :
///
///   - pas encore créé : on explique ce qu'est ce site et on ouvre l'assistant.
///     C'est ici, dans l'application, que la création se fait — le tableau de
///     bord web renvoie vers cet écran ;
///   - déjà en ligne : l'adresse, de quoi la partager, et l'accès aux réglages.
///
/// Ce site est distinct de la fiche boutique affichée DANS l'application :
/// celle-ci est la même pour toutes les enseignes, pour qu'un client s'y
/// retrouve d'un coup d'œil. Le site web, lui, porte les couleurs du vendeur.
class MaVitrinePage extends StatelessWidget {
  const MaVitrinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VitrineBloc>()..add(ChargerVitrine()),
      child: const _VueVitrine(),
    );
  }
}

class _VueVitrine extends StatelessWidget {
  const _VueVitrine();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        surfaceTintColor: _C.white,
        elevation: 0,
        title: const Text(
          'Mon site web',
          style: TextStyle(color: _C.text, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        iconTheme: const IconThemeData(color: _C.text),
      ),
      body: BlocConsumer<VitrineBloc, VitrineState>(
        listener: (context, state) {
          if (state is VitrineErreur) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          // Retour de l'assistant : on recharge pour repartir d'un état sûr,
          // plutôt que de recomposer l'écran à partir de ce qu'il a renvoyé.
          if (state is VitrineCreee || state is VitrineEnregistree) {
            context.read<VitrineBloc>().add(ChargerVitrine());
          }
        },
        builder: (context, state) {
          if (state is VitrineChargement || state is VitrineInitial) {
            return const Center(child: CircularProgressIndicator(color: _C.navy));
          }

          if (state is VitrineSansBoutique) {
            return _MessageCentre(
              icone: Icons.storefront_outlined,
              titre: 'Créez d\'abord votre boutique',
              texte: state.message,
            );
          }

          if (state is VitrineErreur) {
            return _MessageCentre(
              icone: Icons.wifi_off_rounded,
              titre: 'Chargement impossible',
              texte: state.message,
              action: FilledButton(
                onPressed: () => context.read<VitrineBloc>().add(ChargerVitrine()),
                child: const Text('Réessayer'),
              ),
            );
          }

          if (state is VitrineChargee) {
            return state.vitrine.configuree
                ? _SiteEnLigne(vitrine: state.vitrine, secteurs: state.secteurs)
                : _SiteAcreer(secteurs: state.secteurs);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  LE SITE N'EXISTE PAS ENCORE
// ═══════════════════════════════════════════════════════════════════════

class _SiteAcreer extends StatelessWidget {
  final List<SecteurVitrine> secteurs;
  const _SiteAcreer({required this.secteurs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_C.navy, Color(0xFF060F26)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'GRATUIT',
                    style: TextStyle(
                      color: _C.gold, fontSize: 11,
                      fontWeight: FontWeight.w800, letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Votre boutique a droit à son site web',
                  style: TextStyle(
                    color: Colors.white, fontSize: 21,
                    fontWeight: FontWeight.w800, height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Une adresse à vous, à envoyer sur WhatsApp ou à coller sur '
                  'votre devanture. Vos clients y voient votre catalogue et '
                  'commandent directement, sans installer quoi que ce soit.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13.5, height: 1.55,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Comment ça se passe',
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _C.text),
          ),
          const SizedBox(height: 12),

          const _Etape(
            numero: '1',
            titre: 'Vous déposez votre logo',
            texte: 'Nous y relevons vos couleurs et sa forme, pour habiller le site avec.',
          ),
          const _Etape(
            numero: '2',
            titre: 'Vous dites ce que vous vendez',
            texte: 'La mise en page et les textes s\'adaptent à votre activité.',
          ),
          const _Etape(
            numero: '3',
            titre: 'Votre site est composé',
            texte: 'Vous le relisez, vous corrigez ce que vous voulez, et vous le publiez.',
            dernier: true,
          ),

          const SizedBox(height: 24),

          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _C.navy,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _ouvrirAssistant(context, secteurs),
            child: const Text(
              'Créer mon site',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            'Environ deux minutes. Vous pourrez tout modifier ensuite.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.muted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _Etape extends StatelessWidget {
  final String numero;
  final String titre;
  final String texte;
  final bool dernier;

  const _Etape({
    required this.numero,
    required this.titre,
    required this.texte,
    this.dernier = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: dernier ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: _C.navyLight, shape: BoxShape.circle),
            child: Text(
              numero,
              style: const TextStyle(
                color: _C.navy, fontWeight: FontWeight.w800, fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: const TextStyle(
                        fontSize: 14.2, fontWeight: FontWeight.w700, color: _C.text)),
                const SizedBox(height: 2),
                Text(texte,
                    style: const TextStyle(fontSize: 13, color: _C.muted, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  LE SITE EST EN LIGNE
// ═══════════════════════════════════════════════════════════════════════

class _SiteEnLigne extends StatelessWidget {
  final Vitrine vitrine;
  final List<SecteurVitrine> secteurs;

  const _SiteEnLigne({required this.vitrine, required this.secteurs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: vitrine.active ? _C.successBg : const Color(0xFFF1F3F7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        vitrine.active ? 'En ligne' : 'Hors ligne',
                        style: TextStyle(
                          color: vitrine.active ? _C.success : _C.muted,
                          fontSize: 11.5, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (vitrine.vues > 0)
                      Text('${vitrine.vues} visites',
                          style: const TextStyle(color: _C.muted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('L\'adresse de votre site',
                    style: TextStyle(color: _C.muted, fontSize: 12.5)),
                const SizedBox(height: 5),
                SelectableText(
                  vitrine.url,
                  style: const TextStyle(
                    color: _C.navy, fontSize: 15.5, fontWeight: FontWeight.w700,
                  ),
                ),

                if (!vitrine.active) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Votre site est fermé : cette adresse affiche une page '
                    '« boutique introuvable » à vos clients.',
                    style: TextStyle(color: Color(0xFFB0850B), fontSize: 12.5, height: 1.45),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _C.navy,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _partagerWhatsapp(context, vitrine.url),
                        icon: const Icon(Icons.share_rounded, size: 17),
                        label: const Text('Partager',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 9),
                    _BoutonIcone(
                      icone: Icons.copy_rounded,
                      infobulle: 'Copier l\'adresse',
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: vitrine.url));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Adresse copiée.')),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 9),
                    _BoutonIcone(
                      icone: Icons.open_in_new_rounded,
                      infobulle: 'Voir mon site',
                      onTap: () => _ouvrirLien(vitrine.url),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _Carte(
            icone: Icons.tune_rounded,
            titre: 'Modifier mon site',
            sous: 'Mise en page, couleur, textes, sections affichées',
            onTap: () => _ouvrirAssistant(context, secteurs, vitrine: vitrine),
          ),
          _Carte(
            icone: vitrine.active ? Icons.visibility_off_outlined : Icons.public_rounded,
            titre: vitrine.active ? 'Fermer mon site' : 'Remettre mon site en ligne',
            sous: vitrine.active
                ? 'Votre boutique reste visible dans l\'application'
                : 'Vos clients pourront de nouveau y commander',
            onTap: () => context
                .read<VitrineBloc>()
                .add(ModifierVitrineDemande({'active': !vitrine.active})),
          ),

          const SizedBox(height: 20),

          // Le rappel de la gratuité n'est pas décoratif : un vendeur qui a un
          // site suppose qu'on va le lui facturer, et se retient de le
          // partager tant qu'il n'est pas fixé.
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _C.navyLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.favorite_rounded, color: _C.navy, size: 18),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Votre site ne vous coûte rien : aucun abonnement, aucune '
                    'commission sur vos ventes. Partagez-le sans crainte.',
                    style: TextStyle(color: _C.navy, fontSize: 12.8, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoutonIcone extends StatelessWidget {
  final IconData icone;
  final String infobulle;
  final VoidCallback onTap;

  const _BoutonIcone({
    required this.icone,
    required this.infobulle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: infobulle,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            border: Border.all(color: _C.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, size: 19, color: _C.navy),
        ),
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String sous;
  final VoidCallback onTap;

  const _Carte({
    required this.icone,
    required this.titre,
    required this.sous,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _C.white,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _C.navyLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icone, size: 19, color: _C.navy),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titre,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w700, color: _C.text)),
                      const SizedBox(height: 2),
                      Text(sous,
                          style: const TextStyle(fontSize: 12.5, color: _C.muted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _C.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageCentre extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String texte;
  final Widget? action;

  const _MessageCentre({
    required this.icone,
    required this.titre,
    required this.texte,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 42, color: _C.muted),
            const SizedBox(height: 14),
            Text(titre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: _C.text)),
            const SizedBox(height: 8),
            Text(texte,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: _C.muted, height: 1.5)),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  ACTIONS
// ═══════════════════════════════════════════════════════════════════════

/// L'assistant est ouvert avec le bloc de cet écran : le résultat revient donc
/// dans le `BlocConsumer` ci-dessus, qui recharge l'état à la fermeture.
void _ouvrirAssistant(
  BuildContext context,
  List<SecteurVitrine> secteurs, {
  Vitrine? vitrine,
}) {
  final bloc = context.read<VitrineBloc>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AssistantVitrinePage(secteurs: secteurs, vitrine: vitrine),
      ),
    ),
  );
}

Future<void> _ouvrirLien(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _partagerWhatsapp(BuildContext context, String url) async {
  final texte = Uri.encodeComponent('Découvrez ma boutique en ligne : $url');
  final uri = Uri.parse('https://wa.me/?text=$texte');
  final ouvert = await launchUrl(uri, mode: LaunchMode.externalApplication);

  // WhatsApp absent de l'appareil : on ne laisse pas le vendeur sans solution,
  // l'adresse part dans le presse-papier.
  if (!ouvert && context.mounted) {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse copiée : collez-la où vous voulez.')),
      );
    }
  }
}
