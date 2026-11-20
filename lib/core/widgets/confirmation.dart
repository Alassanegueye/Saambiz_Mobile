import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/police.dart';

/// Demande confirmation avant une action importante, et rend `true` si
/// l'utilisateur confirme.
///
/// UNE SEULE FEUILLE POUR TOUTE L'APPLICATION. Elle vivait au milieu de
/// `profil_kit.dart`, où personne n'allait la chercher : la moitié des
/// écrans redessinaient leur propre `AlertDialog`, et certains gestes
/// irréversibles partaient au premier appui, sans rien demander.
///
/// Deux niveaux, pour que l'œil fasse la différence sans lire :
///   * [destructive] (défaut) — rouge. Ce qui efface, annule, retire.
///   * sinon — marine. Ce qui engage sans rien détruire : envoyer un
///     signalement, confirmer un encaissement.
///
/// Ce qu'elle ne fait pas : saisir du texte. Une confirmation qui réclame un
/// motif reste un `AlertDialog` avec son champ — mélanger les deux donnerait
/// une feuille qui saute au-dessus du clavier.
Future<bool> confirmerAction(
  BuildContext context, {
  required IconData icone,
  required String titre,
  required String message,
  required String action,
  String annuler = 'Annuler',
  bool destructive = true,
}) async {
  final teinte = destructive ? AppColor.kErreur : AppColor.kPrimary;
  final fond = destructive ? AppColor.kErreurLight : AppColor.kPrimaryLight;

  final ok = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColor.kWhite,
    // On sort par « Annuler » ou par le geste, jamais par inadvertance sur
    // un appui à côté : l'action reste explicite dans les deux sens.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // PAS DE POIGNÉE DESSINÉE ICI. Le thème en pose déjà une sur
            // toutes les feuilles de l'application (app_theme.dart,
            // `showDragHandle: true`) : en ajouter une seconde en affichait
            // deux, l'une au-dessus de l'autre, sur la déconnexion, la
            // suppression de compte et celle d'un produit.
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: fond, shape: BoxShape.circle),
              child: Icon(icone, color: teinte, size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kPolice,
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
                  backgroundColor: teinte,
                  foregroundColor: AppColor.kWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: kPolice,
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
                annuler,
                style: const TextStyle(
                  fontFamily: kPolice,
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
  // Feuille refermée d'un glissé : c'est un refus, pas un accord.
  return ok == true;
}

/// Explique quelque chose, sans rien demander en retour.
///
/// Même feuille que [confirmerAction] — mêmes coins, même pastille, même
/// poignée posée par le thème — mais UN SEUL BOUTON. Il n'y a pas de choix à
/// faire : l'utilisateur a appuyé sur un bouton qui ne peut pas aboutir, et
/// on lui dit pourquoi et quoi faire à la place.
///
/// Un `AlertDialog` aurait fait l'affaire ; cette feuille-ci garde l'écran
/// cohérent avec le reste de l'application, où tout ce qui s'ouvre par le
/// bas s'ouvre ainsi.
Future<void> informerAction(
  BuildContext context, {
  required IconData icone,
  required String titre,
  required String message,
  String bouton = 'J’ai compris',
  Color? teinte,
}) async {
  final couleur = teinte ?? AppColor.kPrimary;
  final fond = couleur == AppColor.kErreur
      ? AppColor.kErreurLight
      : AppColor.kPrimaryLight;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColor.kWhite,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: fond, shape: BoxShape.circle),
              child: Icon(icone, color: couleur, size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kPolice,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kPolice,
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
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: couleur,
                  foregroundColor: AppColor.kWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: kPolice,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(bouton),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
