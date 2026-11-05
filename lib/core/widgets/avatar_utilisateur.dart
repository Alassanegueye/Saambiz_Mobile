import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/domain/entities/user.dart';
import '../theme/app_color.dart';
import '../utils/image_url.dart';
import '../utils/texte.dart';

/// Rond de l'en-tête : la photo de l'utilisateur, ou ses initiales.
class AvatarUtilisateur extends StatelessWidget {
  final User? utilisateur;
  final VoidCallback onTap;

  const AvatarUtilisateur({
    super.key,
    required this.utilisateur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photo = utilisateur?.photoProfil;
    final initiales = Center(
      child: Text(
        initialesDe('${utilisateur?.prenom ?? ''} ${utilisateur?.nom ?? ''}'),
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColor.kPrimary,
        ),
      ),
    );
    return Semantics(
      button: true,
      label: 'Mon compte',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: AppColor.kSecondary,
            shape: BoxShape.circle,
          ),
          child: photo != null && photo.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageOptimisee(photo, largeur: 128),
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => initiales,
                )
              : initiales,
        ),
      ),
    );
  }
}
