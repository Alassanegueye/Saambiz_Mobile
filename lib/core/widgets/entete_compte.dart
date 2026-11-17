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
  const EnteteCompte({
    super.key,
    required this.nom,
    required this.initiales,
    required this.email,
    required this.role,
    this.photo,
  });

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
          child: aUnePhoto
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
              BadgeTypeProfil(role: role),
            ],
          ),
        ),
      ],
    );
  }
}
