import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../connection/auth_interceptor.dart';
import '../theme/police.dart';

/// Confirme à l'utilisateur qu'une action a bien abouti (enregistrement,
/// suppression, envoi…) : un bandeau en haut de l'écran, avec un titre
/// (« Succès » par défaut) et l'explication en dessous.
///
/// Le bandeau s'affiche dans l'overlay du navigateur racine : il reste
/// visible même si l'écran se ferme juste après (formulaire qui revient en
/// arrière). Un nouveau bandeau remplace le précédent au lieu de s'empiler.
void afficherSucces(
  BuildContext context,
  String message, {
  String titre = 'Succès',
}) {
  _afficher(context, titre, message, ToastificationType.success);
}

/// Pendant de [afficherSucces] pour un échec (titre « Erreur » par défaut).
void afficherErreur(
  BuildContext context,
  String message, {
  String titre = 'Erreur',
}) {
  _afficher(context, titre, message, ToastificationType.error);
}

/// Information neutre (titre « Information » par défaut).
void afficherInfo(
  BuildContext context,
  String message, {
  String titre = 'Information',
}) {
  _afficher(context, titre, message, ToastificationType.info);
}

ToastificationItem? _dernier;

const _vert = Color(0xFF12805C);
const _rouge = Color(0xFFD93A2B);
const _bleu = Color(0xFF01154B);

void _afficher(
  BuildContext context,
  String titre,
  String message,
  ToastificationType type,
) {
  final overlay =
      AuthInterceptor.navigatorKey.currentState?.overlay ??
      Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final couleur = switch (type) {
    ToastificationType.success => _vert,
    ToastificationType.error => _rouge,
    _ => _bleu,
  };

  // Le bandeau précédent s'efface. Il n'entre dans la liste qu'à l'image
  // suivante : on le retire donc après ce passage, pas tout de suite.
  final precedent = _dernier;
  if (precedent != null) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => toastification.dismiss(precedent, showRemoveAnimation: false),
    );
  }
  _dernier = toastification.show(
    overlayState: overlay,
    type: type,
    alignment: Alignment.topCenter,
    title: Text(
      titre,
      style: const TextStyle(
        fontFamily: kPolice,
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
    ),
    description: Text(
      message,
      style: const TextStyle(fontFamily: kPolice, fontSize: 13.5, height: 1.3),
    ),
    // Fond de couleur, texte et icône en blanc (même rendu que l'ancien
    // bandeau d'erreur de connexion).
    primaryColor: Colors.white,
    backgroundColor: couleur,
    foregroundColor: Colors.white,
    autoCloseDuration: Duration(
      seconds: type == ToastificationType.error ? 5 : 3,
    ),
    showProgressBar: true,
    progressBarTheme: ProgressIndicatorThemeData(
      color: Colors.white.withValues(alpha: 0.85),
      linearTrackColor: Colors.white.withValues(alpha: 0.25),
    ),
    closeOnClick: true,
    dragToClose: true,
    borderRadius: BorderRadius.circular(16),
  );
}
