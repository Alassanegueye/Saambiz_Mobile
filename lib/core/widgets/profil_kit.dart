import 'package:flutter/material.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/core/theme/police.dart';

import '../constants/infos_app.dart';
import '../theme/app_color.dart';
import 'animations.dart';

/// Briques des onglets « Compte » (acheteur et vendeur) : en-tête
/// d'identité, groupes d'entrées en liste, feuille de confirmation.

/// En-tête de l'onglet : photo ou initiales, nom, e-mail, type de compte et
/// bouton « Modifier ». Les compteurs facultatifs suivent sur une ligne.
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.kLine),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColor.kPrimary,
                child: aUnePhoto
                    ? ClipOval(
                        child: ImageReseau(photo!, width: 56, height: 56, fit: BoxFit.cover, repli: _initiales()),
                      )
                    : _initiales(),
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
                      style: TextStyle(fontFamily: kPolice, 
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: kPolice, 
                          fontSize: 13,
                          color: AppColor.kGrayscale40,
                        ),
                      ),
                    const SizedBox(height: 4),
                    BadgeTypeProfil(role: role),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: const BorderSide(color: AppColor.kGrayscale20),
                  textStyle: TextStyle(fontFamily: kPolice, 
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Modifier'),
              ),
            ],
          ),
          if (compteurs.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                children: [
                  for (var i = 0; i < compteurs.length; i++) ...[
                    if (i > 0) const VerticalDivider(width: 1),
                    Expanded(
                      child: _Compteur(
                        valeur: compteurs[i].$2,
                        libelle: compteurs[i].$1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _initiales() => Text(
    initiales,
    style: TextStyle(fontFamily: kPolice, 
      fontSize: 19,
      fontWeight: FontWeight.w700,
      color: AppColor.kWhite,
    ),
  );
}

class _Compteur extends StatelessWidget {
  final String valeur;
  final String libelle;
  const _Compteur({required this.valeur, required this.libelle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valeur,
          style: TextStyle(fontFamily: kPolice, 
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
        Text(
          libelle,
          style: TextStyle(fontFamily: kPolice, fontSize: 12, color: AppColor.kGrayscale40),
        ),
      ],
    );
  }
}

/// Type de compte, en petit texte sous le nom : Acheteur, Vendeur…
class BadgeTypeProfil extends StatelessWidget {
  final String role;
  const BadgeTypeProfil({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final libelle = switch (role.trim().toUpperCase()) {
      'VENDEUR' => 'Compte vendeur',
      'ADMIN' => 'Administrateur',
      _ => 'Compte acheteur',
    };
    return Text(
      libelle,
      style: TextStyle(fontFamily: kPolice, 
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColor.kSecondaryDark,
      ),
    );
  }
}

/// Groupe d'entrées : titre gris au-dessus d'une carte blanche.
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
            padding: const EdgeInsets.only(left: 6, bottom: 10),
            child: Text(
              titre,
              style: TextStyle(fontFamily: kPolice, 
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColor.kGrayscale40,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.kLine),
            ),
            child: Material(
              color: AppColor.kWhite,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < entrees.length; i++) ...[
                    entrees[i],
                    if (i < entrees.length - 1)
                      const Divider(
                        height: 1,
                        indent: 52,
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

/// Entrée d'un groupe : pastille d'icône, libellé, sous-titre et chevron.
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        icone,
        size: 22,
        color: danger ? AppColor.kErreur : AppColor.kPrimary,
      ),
      minLeadingWidth: 24,
      title: Text(
        libelle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontFamily: kPolice, 
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: danger ? AppColor.kErreur : AppColor.kGrayscaleDark100,
        ),
      ),
      trailing:
          fin ??
          (onTap == null
              ? null
              : const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColor.kGrayscale30,
                )),
      onTap: onTap,
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
              decoration: BoxDecoration(
                color: AppColor.kErreurLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: AppColor.kErreur, size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: kPolice, 
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: kPolice, 
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
                  textStyle: TextStyle(fontFamily: kPolice, 
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
              child: Text(
                'Annuler',
                style: TextStyle(fontFamily: kPolice, 
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
        textStyle: TextStyle(fontFamily: kPolice, 
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
  Widget build(BuildContext context) => Center(
    child: Text(
      '${InfosApp.nom} v${InfosApp.version}',
      style: TextStyle(fontFamily: kPolice, 
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColor.kGrayscale40,
      ),
    ),
  );
}
