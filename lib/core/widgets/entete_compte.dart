import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/police.dart';
import 'image_reseau.dart';
import 'profil_kit.dart' show BadgeTypeProfil;

/// Le profil dans l'en-tête bleu de l'onglet Compte, acheteur comme
/// vendeur : photo (ou initiales), nom, adresse e-mail et type de compte.
/// Se place dans `PageVendeur.titreWidget`.
class EnteteCompte extends StatelessWidget {
  final String nom;
  final String initiales;
  final String email;
  final String role;
  final String? photo;

  /// Visiteur sans compte : le pictogramme SaamBiz à la place de la photo,
  /// « Visiteur » à la place du type de compte.
  final bool visiteur;

  const EnteteCompte({
    super.key,
    required this.nom,
    required this.initiales,
    required this.email,
    required this.role,
    this.photo,
  }) : visiteur = false;

  const EnteteCompte.visiteur({super.key})
    : nom = 'Bienvenue !',
      initiales = '',
      email = 'Vous visitez SaamBiz sans compte',
      role = '',
      photo = null,
      visiteur = true;

  @override
  Widget build(BuildContext context) {
    final lettres = Center(
      child: Text(
        initiales,
        style: const TextStyle(
          fontFamily: kPolice,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColor.kPrimary,
        ),
      ),
    );
    final aUnePhoto = (photo ?? '').trim().isNotEmpty;
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColor.kWhite,
            shape: BoxShape.circle,
            border: Border.all(color: AppColor.kSecondary, width: 2.5),
          ),
          child: visiteur
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset('assets/images/picto_navy.png'),
                )
              : aUnePhoto
              ? ImageReseau(
                  photo!,
                  largeurServeur: 180,
                  fit: BoxFit.cover,
                  repli: lettres,
                )
              : lettres,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nom,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: kPolice,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColor.kWhite,
                ),
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kPolice,
                    fontSize: 13,
                    color: AppColor.kWhite.withValues(alpha: 0.75),
                  ),
                ),
              const SizedBox(height: 7),
              visiteur ? const _BadgeVisiteur() : BadgeTypeProfil(role: role),
            ],
          ),
        ),
      ],
    );
  }
}

/// La pastille or de BadgeTypeProfil, pour un visiteur sans compte.
class _BadgeVisiteur extends StatelessWidget {
  const _BadgeVisiteur();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.kSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 13,
            color: AppColor.kPrimary,
          ),
          SizedBox(width: 4),
          Text(
            'Visiteur',
            style: TextStyle(
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
