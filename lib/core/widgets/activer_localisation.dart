import 'package:saambiz/core/widgets/messages.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/localisation_service.dart';

/// La position du client est-elle connue sur ce téléphone ?
bool localisationActivee() =>
    const LocalisationService().positionMemorisee() != null;

/// Demande l'autorisation de localisation et relève la position, depuis un
/// bouton « Activer la géolocalisation » (accueil, profil).
///
/// Renvoie `true` si la position est obtenue. Sinon, un bandeau explique
/// pourquoi et propose d'ouvrir les réglages : après un refus définitif, le
/// système ne repose plus la question, seuls les réglages le permettent.
Future<bool> activerLocalisation(BuildContext context) async {
  final position = await const LocalisationService().demanderPosition();
  if (!context.mounted) return position != null;
  final messager = ScaffoldMessenger.of(context)..clearSnackBars();
  if (position != null) {
    afficherSucces(
      context,
      'Géolocalisation activée : voici les boutiques proches.',
    );
    return true;
  }
  final serviceCoupe = !await Geolocator.isLocationServiceEnabled();
  messager.showSnackBar(
    SnackBar(
      content: Text(
        serviceCoupe
            ? 'La localisation de votre téléphone est désactivée.'
            : 'SaamBiz n\'a pas l\'autorisation d\'utiliser votre position.',
      ),
      action: SnackBarAction(
        label: 'Réglages',
        onPressed: () => serviceCoupe
            ? Geolocator.openLocationSettings()
            : Geolocator.openAppSettings(),
      ),
    ),
  );
  return false;
}
