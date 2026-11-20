import 'package:flutter/material.dart';

/// Charge la page suivante tant que la liste ne remplit pas l'écran.
///
/// Les grilles du catalogue — produits, boutiques, catégories — chargent la
/// suite quand on approche du bas. Ce déclencheur est un geste : il n'arrive
/// jamais si le contenu tient dans l'écran. Le serveur en rend dix à la
/// fois, et sur un grand écran dix fiches ne débordent pas toujours : la
/// grille s'arrêterait alors à dix articles, sans moyen d'atteindre les
/// suivants.
///
/// À appeler après chaque chargement réussi. [chargerSuite] doit se garder
/// elle-même — ne rien faire quand la dernière page est atteinte, ou qu'un
/// chargement est déjà en vol — car c'est ce qui arrête la récursion.
void remplirEcran(ScrollController defilement, VoidCallback chargerSuite) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Après la frame : avant elle, la hauteur du contenu n'est pas connue.
    if (!defilement.hasClients) return;
    if (defilement.position.maxScrollExtent > 0) return; // déjà défilable
    chargerSuite();
  });
}
