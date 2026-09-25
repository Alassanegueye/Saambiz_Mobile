import '../../../home/data/models/produit_model.dart';

/// Entité "produit" côté vendeur.
///
/// On réutilise [ProduitModel] (déjà défini dans la feature `home`) plutôt
/// que de dupliquer sa définition : ce modèle est déjà partagé entre
/// plusieurs features (home, panier, commandes, vendeur) et représente
/// fidèlement la ressource `produit` renvoyée par le backend. Ce typedef
/// donne simplement un point d'import stable côté domaine `vendeur`.
typedef ProduitVendeur = ProduitModel;
