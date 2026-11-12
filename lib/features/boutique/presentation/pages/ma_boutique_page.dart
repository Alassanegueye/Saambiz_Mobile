import 'package:saambiz/core/widgets/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/theme/app_color.dart';
import 'package:saambiz/core/theme/police.dart';
import 'package:saambiz/core/utils/texte.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/core/widgets/page_vendeur.dart';
import 'package:saambiz/core/widgets/profil_kit.dart';
import 'package:saambiz/core/widgets/ui_kit.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/boutique.dart';
import '../bloc/boutique_bloc.dart';
import '../bloc/boutique_event.dart';
import '../bloc/boutique_state.dart';
import 'boutique_form_page.dart';

/// Écran de gestion de la boutique du vendeur connecté.
class MaBoutiquePage extends StatelessWidget {
  const MaBoutiquePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BoutiqueBloc>()..add(LoadMaBoutique()),
      child: const _MaBoutiqueView(),
    );
  }
}

class _MaBoutiqueView extends StatelessWidget {
  const _MaBoutiqueView();

  Future<void> _ouvrirFormulaire(BuildContext context, [Boutique? b]) async {
    final res = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BoutiqueFormPage(boutique: b)));
    // Création : on ne recharge que si le formulaire a abouti.
    if (context.mounted && (b != null || res != null)) {
      context.read<BoutiqueBloc>().add(LoadMaBoutique());
    }
  }

  Future<void> _basculerPause(BuildContext context, Boutique b) async {
    final bloc = context.read<BoutiqueBloc>();
    if (b.enPause) {
      bloc.add(ReactiverBoutiqueRequested());
      return;
    }
    final ok = await confirmerAction(
      context,
      icone: Icons.pause_circle_outline_rounded,
      titre: 'Mettre la boutique en pause ?',
      message:
          'Vos produits ne seront plus visibles par les clients jusqu\'à ce '
          'que vous rouvriez la boutique.',
      action: 'Mettre en pause',
    );
    if (ok) bloc.add(PauseBoutiqueRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BoutiqueBloc, BoutiqueState>(
      listener: (context, state) {
        if (state is BoutiqueError) {
          afficherErreur(context, state.message);
        } else if (state is BoutiqueLoaded && state.succes != null) {
          afficherSucces(context, state.succes!);
        }
      },
      builder: (context, state) {
        final b = state is BoutiqueLoaded ? state.boutique : null;
        return PageVendeur(
          titre: 'Ma boutique',
          sousTitre: b == null
              ? null
              : b.enPause
              ? 'En pause · invisible pour les clients'
              : 'Ouverte · visible par les clients',
          actions: [
            if (b != null)
              BoutonEnteteVendeur(
                icone: Icons.edit_rounded,
                infobulle: 'Modifier la boutique',
                principal: true,
                onTap: () => _ouvrirFormulaire(context, b),
              ),
          ],
          corps: switch (state) {
            BoutiqueLoaded() => _Contenu(
              boutique: state.boutique,
              onModifier: () => _ouvrirFormulaire(context, state.boutique),
              onBasculerPause: () => _basculerPause(context, state.boutique),
            ),
            BoutiqueInexistante() => EtatVide(
              icone: Icons.storefront_outlined,
              titre: 'Pas encore de boutique',
              message:
                  'Créez votre boutique pour commencer à vendre sur Saambiz.',
              action: 'Créer ma boutique',
              onAction: () => _ouvrirFormulaire(context),
            ),
            BoutiqueLoading() || BoutiqueInitial() => const Center(
              child: CircularProgressIndicator(),
            ),
            _ => EtatVide(
              icone: Icons.cloud_off_rounded,
              titre: 'Boutique indisponible',
              message: 'Vérifiez votre connexion puis réessayez.',
              action: 'Réessayer',
              onAction: () =>
                  context.read<BoutiqueBloc>().add(LoadMaBoutique()),
            ),
          },
        );
      },
    );
  }
}

class _Contenu extends StatelessWidget {
  final Boutique boutique;
  final VoidCallback onModifier;
  final VoidCallback onBasculerPause;

  const _Contenu({
    required this.boutique,
    required this.onModifier,
    required this.onBasculerPause,
  });

  @override
  Widget build(BuildContext context) {
    final b = boutique;
    final telephone = b.telephone?.trim() ?? '';
    final description = b.description.trim();
    return RefreshIndicator(
      color: AppColor.kPrimary,
      onRefresh: () async => context.read<BoutiqueBloc>().add(LoadMaBoutique()),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          22,
          20,
          24 + MediaQuery.of(context).viewPadding.bottom,
        ),
        children: [
          _CarteIdentite(boutique: b),
          const SizedBox(height: 14),
          _CarteStatut(enPause: b.enPause, onChanged: onBasculerPause),
          const SizedBox(height: 24),
          _Section(
            titre: 'À propos',
            enfants: [
              _LigneInfo(
                icone: Icons.notes_rounded,
                libelle: 'Description',
                valeur: description.isEmpty ? null : description,
                vide: 'Ajoutez une description',
                onTap: onModifier,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            titre: 'Coordonnées',
            enfants: [
              _LigneInfo(
                icone: Icons.location_on_outlined,
                libelle: 'Localisation',
                valeur: b.localisation.trim().isEmpty ? null : b.localisation,
                vide: 'Indiquez où vous trouver',
                onTap: onModifier,
              ),
              _LigneInfo(
                icone: Icons.phone_outlined,
                libelle: 'Téléphone',
                valeur: telephone.isEmpty ? null : telephone,
                vide: 'Ajoutez un numéro de contact',
                onTap: onModifier,
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: onModifier,
              icon: const Icon(Icons.edit_rounded, size: 19),
              label: const Text('Modifier la boutique'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.kPrimary,
                foregroundColor: AppColor.kWhite,
                textStyle: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo, nom et état de la boutique.
class _CarteIdentite extends StatelessWidget {
  final Boutique boutique;
  const _CarteIdentite({required this.boutique});

  @override
  Widget build(BuildContext context) {
    final b = boutique;
    final initiales = Center(
      child: Text(
        initialesDe(b.nom),
        style: const TextStyle(
          fontFamily: kPolice,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColor.kPrimary,
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.kLine),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 64,
              height: 64,
              color: AppColor.kPrimaryLight,
              child: (b.logo ?? '').isNotEmpty
                  ? ImageReseau(b.logo!, fit: BoxFit.cover, repli: initiales)
                  : initiales,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
                const SizedBox(height: 6),
                _PastilleEtat(enPause: b.enPause),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PastilleEtat extends StatelessWidget {
  final bool enPause;
  const _PastilleEtat({required this.enPause});

  @override
  Widget build(BuildContext context) {
    final couleur = enPause ? AppColor.kSecondaryDark : AppColor.kSucces;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: enPause ? AppColor.kSecondaryLight : AppColor.kSuccesLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            enPause ? 'En pause' : 'Ouverte',
            style: TextStyle(
              fontFamily: kPolice,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }
}

/// Interrupteur ouverte / en pause, à la place du simple lien texte.
class _CarteStatut extends StatelessWidget {
  final bool enPause;
  final VoidCallback onChanged;
  const _CarteStatut({required this.enPause, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enPause ? AppColor.kSecondaryLight : AppColor.kWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: enPause
              ? AppColor.kSecondary.withValues(alpha: 0.5)
              : AppColor.kLine,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onChanged,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              PastilleIcone(
                enPause ? Icons.pause_rounded : Icons.storefront_rounded,
                accent: enPause,
                taille: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enPause ? 'Boutique en pause' : 'Boutique ouverte',
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enPause
                          ? 'Rouvrez-la pour être de nouveau visible.'
                          : 'Les clients voient vos produits.',
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: !enPause,
                activeTrackColor: AppColor.kSucces,
                onChanged: (_) => onChanged(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Titre gris puis carte blanche aux lignes séparées.
class _Section extends StatelessWidget {
  final String titre;
  final List<Widget> enfants;
  const _Section({required this.titre, required this.enfants});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
          child: Text(
            titre,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColor.kGrayscale40,
            ),
          ),
        ),
        Material(
          color: AppColor.kWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColor.kLine),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < enfants.length; i++) ...[
                enfants[i],
                if (i < enfants.length - 1)
                  const Divider(
                    height: 1,
                    indent: 66,
                    endIndent: 16,
                    color: AppColor.kLine,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LigneInfo extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String? valeur;
  final String vide;
  final VoidCallback onTap;

  const _LigneInfo({
    required this.icone,
    required this.libelle,
    required this.valeur,
    required this.vide,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final manquant = valeur == null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PastilleIcone(icone),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    libelle,
                    style: const TextStyle(
                      fontFamily: kPolice,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColor.kGrayscale40,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    valeur ?? vide,
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 14.5,
                      height: 1.4,
                      fontWeight: manquant ? FontWeight.w500 : FontWeight.w600,
                      color: manquant
                          ? AppColor.kPrimaryMedium
                          : AppColor.kGrayscaleDark100,
                    ),
                  ),
                ],
              ),
            ),
            if (manquant)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: 20,
                  color: AppColor.kPrimaryMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
