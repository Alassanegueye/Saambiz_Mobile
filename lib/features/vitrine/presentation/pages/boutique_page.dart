import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/page_vendeur.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../injection_container.dart';
import '../../../boutique/presentation/pages/ma_boutique_page.dart';
import '../../domain/entities/vitrine.dart';
import '../bloc/vitrine_bloc.dart';
import '../bloc/vitrine_event.dart';
import '../bloc/vitrine_state.dart';
import 'assistant_vitrine_page.dart';
import 'sections_boutique_page.dart';

/// Palette locale, même convention que les autres écrans vendeur.
class _C {
  static const navy = Color(0xFF01154B);
  static const navyLight = Color(0xFFE8EDF7);
  static const bg = Color(0xFFF7F9FC);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E7F0);
  static const muted = Color(0xFF5B6C8A);
  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFE9F8EE);
  static const alerte = Color(0xFFB0850B);
}

/// L'onglet « Boutique » : tout ce qui configure la boutique en ligne.
///
/// C'est le point unique où le vendeur met son site en ligne, le ferme,
/// compose ses rayons et y range ses produits. Les produits eux-mêmes se
/// créent dans l'onglet « Produits » : ici on ne fait que les disposer, et
/// l'écran renvoie vers « Produits » quand il n'y en a aucun.
class BoutiquePage extends StatelessWidget {
  /// Ouvre l'onglet « Produits ». Seul [MainVendeurPage] sait atteindre les
  /// onglets voisins, il passe donc le geste plutôt que la page.
  final VoidCallback? ouvrirProduits;

  const BoutiquePage({super.key, this.ouvrirProduits});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VitrineBloc>()..add(ChargerVitrine()),
      child: _VueBoutique(ouvrirProduits: ouvrirProduits),
    );
  }
}

class _VueBoutique extends StatelessWidget {
  final VoidCallback? ouvrirProduits;
  const _VueBoutique({this.ouvrirProduits});

  @override
  Widget build(BuildContext context) {
    return PageVendeur(
      titre: 'Ma boutique',
      sousTitre: 'Votre site en ligne',
      actions: [
        BoutonEnteteVendeur(
          icone: Icons.refresh_rounded,
          infobulle: 'Actualiser',
          onTap: () => context.read<VitrineBloc>().add(ChargerVitrine()),
        ),
      ],
      corps: BlocConsumer<VitrineBloc, VitrineState>(
        listener: (context, state) {
          if (state is VitrineErreur) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          // Retour de l'assistant ou d'un enregistrement : on recharge
          // pour repartir d'un état sûr, plutôt que de recomposer
          // l'écran à partir de ce qui vient d'être renvoyé.
          if (state is VitrineCreee || state is VitrineEnregistree) {
            context.read<VitrineBloc>().add(ChargerVitrine());
          }
        },
        builder: (context, state) {
          if (state is VitrineChargement || state is VitrineInitial) {
            return const Center(
              child: CircularProgressIndicator(color: _C.navy),
            );
          }

          if (state is VitrineSansBoutique) {
            return Center(
              child: EtatVide(
                icone: Icons.storefront_outlined,
                titre: 'Créez d\'abord votre boutique',
                message: state.message,
              ),
            );
          }

          if (state is VitrineErreur) {
            return Center(
              child: EtatVide(
                icone: Icons.wifi_off_rounded,
                titre: 'Chargement impossible',
                message: state.message,
                action: 'Réessayer',
                onAction: () =>
                    context.read<VitrineBloc>().add(ChargerVitrine()),
              ),
            );
          }

          if (state is VitrineChargee) {
            return state.vitrine.configuree
                ? _Configuration(
                    vitrine: state.vitrine,
                    secteurs: state.secteurs,
                    ouvrirProduits: ouvrirProduits,
                  )
                : _BoutiqueAcreer(secteurs: state.secteurs);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  LA BOUTIQUE EN LIGNE N'EXISTE PAS ENCORE
// ═══════════════════════════════════════════════════════════════════════

class _BoutiqueAcreer extends StatelessWidget {
  final List<SecteurVitrine> secteurs;
  const _BoutiqueAcreer({required this.secteurs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, espaceBasVendeur(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _C.navyLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.language_rounded, color: _C.navy, size: 30),
          ),
          const SizedBox(height: 18),
          const Text(
            'Mettez votre boutique en ligne',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _C.navy,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Votre boutique obtient sa propre adresse sur le web, que vous '
            'partagez à vos clients. Quelques questions suffisent : nous '
            'composons le site à partir de votre logo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.muted, fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _C.navy,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: secteurs.isEmpty
                ? null
                : () => _ouvrirAssistant(context, secteurs),
            icon: const Icon(Icons.auto_awesome_rounded, size: 19),
            label: const Text(
              'Créer ma boutique en ligne',
              style: TextStyle(
                fontFamily: kPolice,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (secteurs.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Les secteurs d\'activité n\'ont pas pu être chargés. '
              'Actualisez pour réessayer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _C.alerte, fontSize: 12.5, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  CONFIGURATION DE LA BOUTIQUE EN LIGNE
// ═══════════════════════════════════════════════════════════════════════

class _Configuration extends StatelessWidget {
  final Vitrine vitrine;
  final List<SecteurVitrine> secteurs;
  final VoidCallback? ouvrirProduits;

  const _Configuration({
    required this.vitrine,
    required this.secteurs,
    this.ouvrirProduits,
  });

  /// Compose les rayons, puis envoie la liste rendue par l'éditeur.
  ///
  /// L'éditeur travaille hors ligne et ne rend sa liste qu'à
  /// l'enregistrement : c'est ici, et seulement ici, que l'appel part.
  Future<void> _composerSections(BuildContext context) async {
    final bloc = context.read<VitrineBloc>();
    final sections = await Navigator.of(context).push<List<SectionBoutique>>(
      MaterialPageRoute(
        builder: (_) => SectionsBoutiquePage(
          sections: vitrine.sectionsPerso,
          ouvrirProduits: ouvrirProduits,
        ),
      ),
    );
    if (sections == null) return;
    bloc.add(
      ModifierVitrineDemande({
        'sectionsPerso': sections.map((s) => s.versJson()).toList(),
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = vitrine.sectionsPerso;
    final produitsRanges = sections.expand((s) => s.produitIds).toSet().length;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 18, 16, espaceBasVendeur(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CarteAdresse(vitrine: vitrine),

          const SizedBox(height: 16),

          // ── Identité de la boutique ───────────────────────
          _Bloc(
            titre: 'Identité',
            enfant: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storefront_outlined, color: _C.navy),
              title: const Text(
                'Nom, logo, catégories',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _C.navy,
                ),
              ),
              subtitle: const Text(
                'Ce que vos clients voient en premier, et la mise en pause',
                style: TextStyle(color: _C.muted, fontSize: 12.5),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: _C.muted,
              ),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MaBoutiquePage())),
            ),
          ),

          const SizedBox(height: 12),

          // ── Activation du site en ligne ──────────────────────────────
          _Bloc(
            titre: 'Site en ligne',
            enfant: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: vitrine.active,
              activeThumbColor: _C.white,
              activeTrackColor: _C.success,
              title: Text(
                vitrine.active ? 'Ouvert au public' : 'Fermé',
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _C.navy,
                ),
              ),
              subtitle: Text(
                vitrine.active
                    ? 'Vos clients peuvent visiter votre site et y commander.'
                    : 'Votre adresse affiche « boutique introuvable ». Votre '
                          'boutique reste visible dans l\'application.',
                style: const TextStyle(
                  color: _C.muted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              onChanged: (v) => context.read<VitrineBloc>().add(
                ModifierVitrineDemande({'active': v}),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Les rayons et leurs produits ─────────────────────────────
          _Bloc(
            titre: 'Sections',
            enfant: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sections.isEmpty
                      ? 'Aucune section : votre site affiche simplement tous '
                            'vos produits.'
                      : '${sections.length} section${sections.length > 1 ? 's' : ''}'
                            ' · $produitsRanges produit${produitsRanges > 1 ? 's' : ''} rangé${produitsRanges > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: _C.muted,
                    fontSize: 12.8,
                    height: 1.45,
                  ),
                ),
                if (sections.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in sections)
                        _Etiquette(texte: s.titre, nombre: s.produitIds.length),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _composerSections(context),
                  icon: const Icon(
                    Icons.dashboard_customize_outlined,
                    size: 18,
                  ),
                  label: Text(
                    sections.isEmpty
                        ? 'Créer mes sections'
                        : 'Composer mes sections',
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.navy,
                    side: const BorderSide(color: _C.border),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Rappel de l'ordre des choses ─────────────────────────────
          _Bloc(
            titre: 'Produits',
            enfant: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Un produit se crée dans « Produits ». Il peut ensuite être '
                  'rangé dans une ou plusieurs sections de votre site.',
                  style: TextStyle(
                    color: _C.muted,
                    fontSize: 12.8,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: ouvrirProduits,
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text(
                    'Gérer mes produits',
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.navy,
                    side: const BorderSide(color: _C.border),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _Bloc(
            titre: 'Apparence',
            enfant: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune_rounded, color: _C.navy),
              title: const Text(
                'Modifier mon site',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _C.navy,
                ),
              ),
              subtitle: const Text(
                'Mise en page, couleur, textes, blocs affichés',
                style: TextStyle(color: _C.muted, fontSize: 12.5),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: _C.muted,
              ),
              onTap: () =>
                  _ouvrirAssistant(context, secteurs, vitrine: vitrine),
            ),
          ),

          const SizedBox(height: 18),

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
                    style: TextStyle(
                      color: _C.navy,
                      fontSize: 12.8,
                      height: 1.5,
                    ),
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

/// L'adresse du site, son état, et de quoi la diffuser.
class _CarteAdresse extends StatelessWidget {
  final Vitrine vitrine;
  const _CarteAdresse({required this.vitrine});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  color: vitrine.active
                      ? _C.successBg
                      : const Color(0xFFF1F3F7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  vitrine.active ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    color: vitrine.active ? _C.success : _C.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (vitrine.vues > 0)
                Text(
                  '${vitrine.vues} visites',
                  style: const TextStyle(color: _C.muted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'L\'adresse de votre site',
            style: TextStyle(color: _C.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 5),
          SelectableText(
            vitrine.url,
            style: const TextStyle(
              color: _C.navy,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _C.navy,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _partagerWhatsapp(context, vitrine.url),
                  icon: const Icon(Icons.share_rounded, size: 17),
                  label: const Text(
                    'Partager',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
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
    );
  }
}

/// Un bloc de réglages : un titre, puis son contenu dans une carte blanche.
class _Bloc extends StatelessWidget {
  final String titre;
  final Widget enfant;
  const _Bloc({required this.titre, required this.enfant});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(
            titre.toUpperCase(),
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: _C.muted,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.border),
          ),
          child: enfant,
        ),
      ],
    );
  }
}

/// Le nom d'une section et son nombre de produits, en aperçu.
class _Etiquette extends StatelessWidget {
  final String texte;
  final int nombre;
  const _Etiquette({required this.texte, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final vide = nombre == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: vide ? const Color(0xFFFFF7E2) : _C.navyLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        vide ? '$texte · vide' : '$texte · $nombre',
        style: TextStyle(
          fontFamily: kPolice,
          fontSize: 11.8,
          fontWeight: FontWeight.w700,
          color: vide ? _C.alerte : _C.navy,
        ),
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
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _C.navyLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, color: _C.navy, size: 19),
        ),
      ),
    );
  }
}

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
        const SnackBar(
          content: Text('Adresse copiée : collez-la où vous voulez.'),
        ),
      );
    }
  }
}
