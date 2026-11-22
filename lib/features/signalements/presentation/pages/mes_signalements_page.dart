import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/widgets/messages.dart';
import 'package:saambiz/core/widgets/page_vendeur.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/police.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/widgets/barre_pagination.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/widgets/image_produit.dart';
import '../../../../core/widgets/image_reseau.dart';
import '../../../../injection_container.dart';
import '../../data/models/signalement_model.dart';
import '../bloc/signalements_bloc.dart';
import '../bloc/signalements_event.dart';
import '../bloc/signalements_state.dart';

/// Signalements envoyés par l'utilisateur connecté.
///
/// Chaque ligne montre la boutique ou le produit visé, son image, et où en
/// est l'examen : la raison saisie seule ne dit pas de quoi on a parlé.
class MesSignalementsPage extends StatelessWidget {
  const MesSignalementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SignalementsBloc>()..add(LoadMesSignalements()),
      child: const _MesSignalementsView(),
    );
  }
}

class _MesSignalementsView extends StatelessWidget {
  const _MesSignalementsView();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMarine(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(title: const Text('Mes signalements')),
      body: BlocConsumer<SignalementsBloc, SignalementsState>(
        listener: (context, state) {
          if (state is SignalementsError) {
            afficherErreur(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is SignalementsLoading || state is SignalementsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! SignalementsLoaded) return const SizedBox.shrink();

          void allerA(int page) => context.read<SignalementsBloc>().add(
            LoadMesSignalements(page: page),
          );
          void recharger() => allerA(state.pagination.page);

          if (state.signalements.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => recharger(),
              child: ListView(
                children: const [
                  SizedBox(height: 80),
                  EtatVide(
                    icone: Icons.flag_outlined,
                    titre: 'Aucun signalement',
                    message:
                        'Si une boutique ou un produit vous semble contraire '
                        'aux règles, signalez-le depuis sa page. Votre '
                        'signalement sera examiné par l’équipe SaamBiz.',
                  ),
                ],
              ),
            );
          }

          final enAttente = state.signalements.where((s) => s.enAttente).length;

          return RefreshIndicator(
            onRefresh: () async => recharger(),
            // +2 : le bandeau en tête, et la barre « Précédent / Suivant »
            // en pied. Elle se replie d'elle-même s'il n'y a qu'une page.
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: state.signalements.length + 2,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == 0) return _Bandeau(enAttente: enAttente);
                if (i == state.signalements.length + 1) {
                  return BarrePagination(
                    pagination: state.pagination,
                    onPage: allerA,
                  );
                }
                return _CarteSignalement(
                  signalement: state.signalements[i - 1],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Ce que devient un signalement. Dit une fois, en haut, plutôt que répété
/// sur chaque carte.
class _Bandeau extends StatelessWidget {
  final int enAttente;
  const _Bandeau({required this.enAttente});

  @override
  Widget build(BuildContext context) {
    final pluriel = enAttente > 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.kPrimaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 19, color: AppColor.kPrimary),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              enAttente == 0
                  ? 'Tous vos signalements ont été examinés par l’équipe SaamBiz.'
                  : '$enAttente signalement${pluriel ? 's' : ''} en cours '
                        'd’examen par l’équipe SaamBiz. Vous serez prévenu'
                        '${pluriel ? 's' : ''} de la suite donnée.',
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 12.8,
                height: 1.5,
                color: AppColor.kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteSignalement extends StatelessWidget {
  final SignalementModel signalement;
  const _CarteSignalement({required this.signalement});

  /// Chaque statut a sa couleur : on lit l'état de la carte avant le texte.
  ({Color teinte, IconData icone}) get _allure => switch (signalement.statut) {
    'traite' => (teinte: AppColor.kSucces, icone: Icons.check_circle_rounded),
    'rejete' => (teinte: AppColor.kErreur, icone: Icons.cancel_rounded),
    _ => (teinte: const Color(0xFFFF8F00), icone: Icons.schedule_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final s = signalement;
    final allure = _allure;
    final cible = s.cible;
    final estBoutique = s.type == 'boutique';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // La vignette de ce qui a été signalé : on reconnaît la
              // boutique avant de lire son nom.
              _Vignette(image: cible?.image, estBoutique: estBoutique),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // Sans cible connue, on ne ment pas : on dit qu'elle
                      // n'existe plus, plutôt que d'afficher la raison à sa
                      // place comme avant.
                      cible?.nom ??
                          '${s.libelleType} supprimé${estBoutique ? 'e' : ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kPolice,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: cible == null
                            ? AppColor.kGrayscale40
                            : AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.libelleType,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 12,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Pastille(allure: allure, libelle: s.libelleStatut),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColor.kLine),
          const SizedBox(height: 12),
          _Ligne(libelle: 'Motif', valeur: s.raison),
          if (s.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _Ligne(libelle: 'Détail', valeur: s.description, lignes: 4),
          ],
          if (s.createdAt != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppColor.kGrayscale40,
                ),
                const SizedBox(width: 6),
                Text(
                  'Signalé le ${dateCourte.format(s.createdAt!)}',
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 11.5,
                    color: AppColor.kGrayscale40,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Image de la cible, ou son pictogramme quand il n'y en a pas.
class _Vignette extends StatelessWidget {
  final String? image;
  final bool estBoutique;
  const _Vignette({required this.image, required this.estBoutique});

  @override
  Widget build(BuildContext context) {
    final repli = Container(
      color: AppColor.kPrimaryLight,
      alignment: Alignment.center,
      child: Icon(
        estBoutique ? Icons.storefront_rounded : Icons.inventory_2_rounded,
        size: 22,
        color: AppColor.kPrimary,
      ),
    );
    // Un produit signalé se présente comme partout ailleurs ; une boutique
    // garde sa vignette et son pictogramme de devanture.
    if (!estBoutique) {
      return ImageProduit(image, cote: 48, largeurServeur: 160, repli: repli);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 48,
        height: 48,
        child: image == null
            ? repli
            : ImageReseau(
                image!,
                largeurServeur: 160,
                fit: BoxFit.cover,
                repli: repli,
              ),
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  final ({Color teinte, IconData icone}) allure;
  final String libelle;
  const _Pastille({required this.allure, required this.libelle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: allure.teinte.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(allure.icone, size: 13, color: allure.teinte),
          const SizedBox(width: 5),
          Text(
            libelle,
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: allure.teinte,
            ),
          ),
        ],
      ),
    );
  }
}

/// « Motif · … » : un libellé discret, sa valeur en dessous.
class _Ligne extends StatelessWidget {
  final String libelle;
  final String valeur;
  final int lignes;
  const _Ligne({required this.libelle, required this.valeur, this.lignes = 2});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          libelle.toUpperCase(),
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColor.kGrayscale40,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          valeur,
          maxLines: lignes,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: kPolice,
            fontSize: 13.5,
            height: 1.45,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
      ],
    );
  }
}
