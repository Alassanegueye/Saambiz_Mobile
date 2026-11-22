/// Choix et recadrage des photos de produit.
///
/// Les vendeurs envoient ce qu'ils ont sous la main : captures d'écran
/// verticales, photos prises de travers, visuels panoramiques. L'application
/// les affichait tels quels et se débrouillait au moment du rendu, chaque
/// écran à sa façon. Le cadrage se décide maintenant AVANT l'envoi : le
/// vendeur voit ce qu'il publie, et la photo enregistrée est déjà au rapport
/// attendu par [ImageProduit] ([kRatioImageProduit]).
library;

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_color.dart';
import '../widgets/image_produit.dart';

/// Demande d'où vient la photo. `null` si le vendeur referme la feuille.
Future<ImageSource?> demanderSourcePhoto(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColor.kWhite,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Prendre une photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choisir dans la galerie'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Ouvre le recadrage sur [chemin] et renvoie le chemin de la photo recadrée.
///
/// Le rapport est verrouillé : le vendeur choisit QUELLE partie de sa photo
/// est gardée, pas sa forme. Renvoie `null` s'il annule — l'appelant garde
/// alors la photo précédente plutôt que d'enregistrer un cadrage subi.
Future<String?> rognerPhotoProduit(String chemin) async {
  final rognee = await ImageCropper().cropImage(
    sourcePath: chemin,
    aspectRatio: const CropAspectRatio(ratioX: kRatioImageProduit, ratioY: 1),
    compressQuality: 85,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Cadrer la photo',
        toolbarColor: AppColor.kPrimary,
        toolbarWidgetColor: AppColor.kWhite,
        activeControlsWidgetColor: AppColor.kPrimary,
        backgroundColor: AppColor.kGrayscaleDark100,
        // Le rapport est imposé : ni sélecteur de format, ni poignées libres.
        lockAspectRatio: true,
        hideBottomControls: true,
      ),
      IOSUiSettings(
        title: 'Cadrer la photo',
        doneButtonTitle: 'Valider',
        cancelButtonTitle: 'Annuler',
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
    ],
  );
  return rognee?.path;
}

/// Parcours complet d'une photo de produit : d'où elle vient, puis cadrage.
///
/// Renvoie `null` à la moindre annulation, pour que l'appelant n'ait qu'un
/// seul cas à traiter.
Future<String?> choisirPhotoProduit(BuildContext context) async {
  final source = await demanderSourcePhoto(context);
  if (source == null) return null;

  final prise = await ImagePicker().pickImage(
    source: source,
    imageQuality: 90,
    maxWidth: 1600,
  );
  if (prise == null) return null;

  return rognerPhotoProduit(prise.path);
}
