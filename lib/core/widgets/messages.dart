import 'package:flutter/material.dart';

import '../theme/app_color.dart';

/// Confirme à l'utilisateur qu'une action a bien abouti (enregistrement,
/// suppression, envoi…).
///
/// Le bandeau passe par le `ScaffoldMessenger` racine : il reste affiché
/// même si l'écran se ferme juste après (formulaire qui revient en
/// arrière), et il remplace un bandeau encore visible plutôt que de
/// s'empiler derrière.
void afficherSucces(BuildContext context, String message) {
  _afficher(
    context,
    message,
    icone: Icons.check_circle_rounded,
    couleurIcone: AppColor.kSucces,
    fond: AppColor.kPrimary,
  );
}

/// Pendant de [afficherSucces] pour un échec.
void afficherErreur(BuildContext context, String message) {
  _afficher(
    context,
    message,
    icone: Icons.error_outline_rounded,
    couleurIcone: AppColor.kWhite,
    fond: AppColor.kErreur,
  );
}

void _afficher(
  BuildContext context,
  String message, {
  required IconData icone,
  required Color couleurIcone,
  required Color fond,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: fond,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColor.kWhite.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 18, color: couleurIcone),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
