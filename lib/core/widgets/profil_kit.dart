import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/infos_app.dart';
import '../theme/app_color.dart';

/// Briques des onglets « Compte » (acheteur et vendeur), reprises de
/// l'application Yobante Boutique : carte bleue d'en-tête, groupes d'entrées
/// dans des cartes blanches, feuille de confirmation en bas d'écran.

/// Carte bleue en tête de l'onglet : photo ou initiales, nom, e-mail, badge
/// du type de compte et lien « Modifier mon profil ».
class CarteEnteteProfil extends StatelessWidget {
  final String nom;
  final String initiales;
  final String email;
  final String role;
  final String? photo;
  final VoidCallback onTap;

  /// Compteurs facultatifs affichés sous l'identité (libellé → valeur).
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
    return Material(
      color: AppColor.kPrimary,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColor.kPrimaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColor.kWhite, width: 1.5),
                    ),
                    child: aUnePhoto
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: photo!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _initiales(),
                              errorWidget: (_, __, ___) => _initiales(),
                            ),
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColor.kWhite,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColor.kWhite.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        BadgeTypeProfil(role: role),
                        const SizedBox(height: 8),
                        Text(
                          'Modifier mon profil',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColor.kSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColor.kWhite),
                ],
              ),
              if (compteurs.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < compteurs.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: _Compteur(valeur: compteurs[i].$2, libelle: compteurs[i].$1)),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _initiales() => Center(
        child: Text(
          initiales,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.kPrimary,
          ),
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
        color: AppColor.kWhite.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            valeur,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColor.kSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            libelle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColor.kWhite.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge du type de compte sur la carte bleue : Acheteur, Vendeur…
class BadgeTypeProfil extends StatelessWidget {
  final String role;
  const BadgeTypeProfil({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final r = role.trim().toUpperCase();
    final (String libelle, IconData icone) = switch (r) {
      'VENDEUR' => ('Vendeur', Icons.storefront_rounded),
      'ADMIN' => ('Administrateur', Icons.admin_panel_settings_outlined),
      _ => ('Acheteur', Icons.shopping_bag_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.kWhite.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.kWhite.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: AppColor.kWhite),
          const SizedBox(width: 5),
          Text(
            libelle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColor.kWhite,
            ),
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            titre,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColor.kGrayscale40,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColor.kPrimary.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                    const Divider(height: 1, indent: 64, endIndent: 16, color: AppColor.kLine),
                ],
              ],
            ),
          ),
        ),
      ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: danger ? AppColor.kErreurLight : AppColor.kPrimaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icone, size: 19, color: danger ? AppColor.kErreur : AppColor.kPrimary),
      ),
      title: Text(
        libelle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: danger ? AppColor.kErreur : AppColor.kGrayscaleDark100,
        ),
      ),
      subtitle: sousTitre.isEmpty
          ? null
          : Text(
              sousTitre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColor.kGrayscale40),
            ),
      trailing: fin ??
          (onTap == null
              ? null
              : const Icon(Icons.chevron_right_rounded, color: AppColor.kGrayscale40)),
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icone, color: AppColor.kErreur, size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: Text(action),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Annuler',
                style: GoogleFonts.plusJakartaSans(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      icon: const Icon(Icons.logout_rounded, size: 20),
      label: const Text('Se déconnecter'),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscale40,
          ),
        ),
      );
}
