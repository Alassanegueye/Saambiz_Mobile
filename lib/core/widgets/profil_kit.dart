import 'package:flutter/material.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/core/theme/police.dart';

import '../constants/infos_app.dart';
import '../theme/app_color.dart';
import 'animations.dart';

/// Briques des onglets « Compte » (acheteur et vendeur) : en-tête
/// d'identité, groupes d'entrées en liste, feuille de confirmation.

/// En-tête de l'onglet : une carte marine avec photo ou initiales, nom,
/// e-mail, type de compte et « Modifier », puis les compteurs en tuiles.
class CarteEnteteProfil extends StatelessWidget {
  final String nom;
  final String initiales;
  final String email;
  final String role;
  final String? photo;
  final VoidCallback onTap;

  /// Compteurs facultatifs affichés sous l'identité (libellé, valeur).
  final List<(String, String)> compteurs;

  const CarteEnteteProfil({
    super.key,
    required this.nom,
    required this.initiales,
    required this.email,
    required this.role,
    required this.onTap,
    this.photo,
    this.compteurs = const [],
  });

  @override
  Widget build(BuildContext context) {
    final aUnePhoto = photo != null && photo!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF01154B), Color(0xFF1C3A8A)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Motif discret dans le coin : la carte ne fait pas « vide ».
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.kSecondary,
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColor.kWhite,
                        child: aUnePhoto
                            ? ClipOval(
                                child: ImageReseau(
                                  photo!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  repli: _initiales(),
                                ),
                              )
                            : _initiales(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: kPolice,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColor.kWhite,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: kPolice,
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          BadgeTypeProfil(role: role),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('Modifier mon profil'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      foregroundColor: AppColor.kWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: kPolice,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (compteurs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < compteurs.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _Compteur(
                            valeur: compteurs[i].$2,
                            libelle: compteurs[i].$1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initiales() => Text(
    initiales,
    style: const TextStyle(
      fontFamily: kPolice,
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: AppColor.kPrimary,
    ),
  );
}

class _Compteur extends StatelessWidget {
  final String valeur;
  final String libelle;
  const _Compteur({required this.valeur, required this.libelle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            valeur,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColor.kPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            libelle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: kPolice,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColor.kGrayscale40,
            ),
          ),
        ],
      ),
    );
  }
}

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

/// Feuille de confirmation en bas d'écran (déconnexion, suppression…).
/// Renvoie `true` si l'action est confirmée.
Future<bool> confirmerAction(
  BuildContext context, {
  required IconData icone,
  required String titre,
  required String message,
  required String action,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColor.kWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColor.kErreurLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: AppColor.kErreur, size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 14,
                height: 1.55,
                color: AppColor.kGrayscale40,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.kErreur,
                  foregroundColor: AppColor.kWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(action),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  fontFamily: kPolice,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return ok == true;
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
