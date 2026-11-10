import 'package:flutter/material.dart';
import 'package:saambiz/core/widgets/image_reseau.dart';
import 'package:saambiz/core/theme/police.dart';

import '../../features/auth/domain/entities/user.dart';
import '../theme/app_color.dart';
import '../utils/texte.dart';

/// Rond de l'en-tête : la photo de l'utilisateur, ou ses initiales.
class AvatarUtilisateur extends StatelessWidget {
  final User? utilisateur;
  final VoidCallback onTap;

  /// Point rouge sur l'avatar : une action attend le vendeur dans son compte
  /// (par exemple, faire certifier sa boutique).
  final bool pastille;

  const AvatarUtilisateur({
    super.key,
    required this.utilisateur,
    required this.onTap,
    this.pastille = false,
  });

  @override
  Widget build(BuildContext context) {
    final photo = utilisateur?.photoProfil;
    final initiales = Center(
      child: Text(
        initialesDe('${utilisateur?.prenom ?? ''} ${utilisateur?.nom ?? ''}'),
        style: const TextStyle(
          fontFamily: kPolice,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColor.kPrimary,
        ),
      ),
    );
    return Semantics(
      button: true,
      label: pastille ? 'Mon compte, une action vous attend' : 'Mon compte',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColor.kSecondary,
                shape: BoxShape.circle,
              ),
              child: photo != null && photo.isNotEmpty
                  ? ImageReseau(
                      photo,
                      largeurServeur: 128,
                      fit: BoxFit.cover,
                      repli: initiales,
                    )
                  : initiales,
            ),
            if (pastille)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColor.kErreur,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColor.kWhite, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
