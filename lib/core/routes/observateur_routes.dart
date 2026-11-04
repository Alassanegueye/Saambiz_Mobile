import 'package:flutter/widgets.dart';

/// Observateur des routes de l'application.
///
/// Permet à un écran de savoir qu'on revient sur lui (`didPopNext`) : l'accueil
/// s'en sert pour se recalculer après une recherche ou une fiche produit,
/// puisque ces gestes ont fait évoluer les recommandations.
final RouteObserver<ModalRoute<void>> observateurRoutes =
    RouteObserver<ModalRoute<void>>();
