import 'package:flutter/material.dart';

import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/core/theme/police.dart';

import '../constants/infos_app.dart';
import '../theme/app_color.dart';
import 'animations.dart';

// `confirmerAction` a demenage dans son propre fichier — elle sert a toute
// l'application, pas seulement au profil. Reexportee ici pour ne pas casser
// les ecrans qui l'importaient d'ici.
export 'confirmation.dart' show confirmerAction;

/// Briques des onglets « Compte » (acheteur et vendeur) : pastille de type
/// de compte, groupes d'entrées en liste, boutons de pied d'onglet.
///
/// L'en-tête marine, lui, vit dans `entete_compte.dart` : il est partagé
/// par l'acheteur et le vendeur.

// `CarteEnteteProfil` a ete retiree d'ici : elle n'avait plus aucun
// appelant depuis que les deux onglets passent par `EnteteCompte`, et en
// garder deux presque identiques laissait retoucher la mauvaise.

/// Type de compte en pastille dorée : Acheteur, Vendeur…
class BadgeTypeProfil extends StatelessWidget {
  final String role;
  const BadgeTypeProfil({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final (libelle, icone) = switch (role.trim().toUpperCase()) {
      'VENDEUR' => ('Compte vendeur', Icons.storefront_rounded),
      'ADMIN' => ('Administrateur', Icons.shield_outlined),
      _ => ('Compte acheteur', Icons.shopping_bag_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.kSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: AppColor.kPrimary),
          const SizedBox(width: 4),
          Text(
            libelle,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColor.kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Groupe d'entrées : petit titre au-dessus d'une carte blanche.
class SectionProfil extends StatelessWidget {
  final String titre;
  final List<Widget> entrees;

  const SectionProfil({super.key, required this.titre, required this.entrees});

  @override
  Widget build(BuildContext context) {
    return Apparition(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              titre.toUpperCase(),
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColor.kGrayscale40,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColor.kLine),
              boxShadow: [
                BoxShadow(
                  color: AppColor.kPrimary.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: AppColor.kWhite,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < entrees.length; i++) ...[
                    entrees[i],
                    if (i < entrees.length - 1)
                      const Divider(
                        height: 1,
                        indent: 70,
                        endIndent: 16,
                        color: AppColor.kLine,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Entrée d'un groupe : icône dans un carré coloré, libellé, sous-titre et
/// chevron.
class LigneProfil extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String sousTitre;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? fin;

  const LigneProfil({
    super.key,
    required this.icone,
    required this.libelle,
    required this.sousTitre,
    this.onTap,
    this.danger = false,
    this.fin,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = danger ? AppColor.kErreur : AppColor.kPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: danger ? AppColor.kErreurLight : AppColor.kPrimaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, size: 21, color: couleur),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    libelle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kPolice,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: danger
                          ? AppColor.kErreur
                          : AppColor.kGrayscaleDark100,
                    ),
                  ),
                  if (sousTitre.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sousTitre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 12.5,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            fin ??
                (onTap == null
                    ? const SizedBox.shrink()
                    : const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColor.kGrayscale30,
                      )),
          ],
        ),
      ),
    );
  }
}

/// Bouton « Se déconnecter » en bas de l'onglet.
class BoutonDeconnexion extends StatelessWidget {
  final VoidCallback onPressed;
  const BoutonDeconnexion({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColor.kErreur,
        side: BorderSide(color: AppColor.kErreur.withValues(alpha: 0.4)),
        backgroundColor: AppColor.kWhite,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: kPolice,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      icon: const Icon(Icons.logout_rounded, size: 20),
      label: const Text('Se déconnecter'),
    );
  }
}

/// Bouton « Changer de compte », au-dessus de « Se déconnecter » : on quitte
/// ce compte sans fermer sa session, pour y revenir d'un toucher.
class BoutonChangerCompte extends StatelessWidget {
  final VoidCallback onPressed;
  const BoutonChangerCompte({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColor.kPrimary,
        side: const BorderSide(color: AppColor.kPrimaryBorder),
        backgroundColor: AppColor.kWhite,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: kPolice,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      icon: const Icon(Icons.swap_horiz_rounded, size: 20),
      label: const Text('Changer de compte'),
    );
  }
}

/// Nom et version de l'application, en pied d'onglet.
class VersionApp extends StatelessWidget {
  const VersionApp({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      '${InfosApp.nom} v${InfosApp.version}',
      style: TextStyle(
        fontFamily: kPolice,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColor.kGrayscale40,
      ),
    ),
  );
}
