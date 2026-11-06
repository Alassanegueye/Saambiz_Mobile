/// Données de démonstration pour les captures de l'App Store.
///
/// Une boutique qui vient d'être créée est vide : 0 FCFA, aucun produit,
/// aucune commande. Ce sont les pires captures possibles sur une fiche
/// App Store, et remplir la base de production pour les prendre y laisserait
/// de faux produits visibles par de vrais clients.
///
/// Ce module court-circuite donc TROIS appels réseau, et uniquement eux, quand
/// l'application est compilée avec `--dart-define=DEMO=true` :
///   • la liste des produits du vendeur
///   • les statistiques du tableau de bord
///   • les commandes reçues
///
/// Les écrans capturés restent les vrais écrans de l'application, au pixel
/// près : seules les données changent. Sans ce drapeau — donc dans toutes les
/// versions construites pour le magasin — rien de ceci n'est actif, et
/// l'arbre de code est même éliminé à la compilation.
library;

import 'package:flutter/widgets.dart';

import '../widgets/image_reseau.dart';

/// Vrai uniquement avec `--dart-define=DEMO=true`.
const bool modeDemo = bool.fromEnvironment('DEMO');

/// Fait pointer les photos des produits de démonstration sur des images
/// embarquées plutôt que sur le réseau.
///
/// [ImageReseau] expose déjà ce point d'entrée pour le banc d'aperçu ; on le
/// réutilise ici. Rien n'est téléchargé, les captures sont donc identiques à
/// chaque fois et ne dépendent pas de l'état du serveur d'images.
void installerImagesDemo() {
  // ignore: invalid_use_of_visible_for_testing_member
  ImageReseau.substitut = (url) => AssetImage('assets/images/$url');
}

const Map<String, dynamic> _vendeurDemo = {
  'id': 'demo-vendeur',
  'prenom': 'Alioune',
  'nom': 'Ndiaye',
  'telephone': '77 123 45 67',
  'boutiques': [
    {'id': 'demo-boutique', 'localisation': 'Dakar'},
  ],
};

Map<String, dynamic> _produit(
  String id,
  String nom,
  String description,
  int prix,
  int quantite,
  String categorie,
  String photo,
) => {
  'id': id,
  'nom': nom,
  'description': description,
  'prix': prix,
  'quantite': quantite,
  // Résolu en AssetImage par installerImagesDemo().
  'image': photo,
  'vendeur': _vendeurDemo,
  'categorie': {'id': 'cat-$id', 'nom': categorie},
};

List<Map<String, dynamic>> produitsDemo() => [
  _produit(
    '1',
    'Chemise en wax cousue main',
    'Wax authentique, coupe droite, finitions à la main.',
    22000,
    14,
    'Mode',
    'demo-chemise.jpg',
  ),
  _produit(
    '2',
    'Baskets cuir blanches',
    'Cuir véritable, semelle souple, du 39 au 45.',
    32000,
    12,
    'Chaussures',
    'demo-baskets.jpg',
  ),
  _produit(
    '3',
    'Sac à main cousu main',
    'Cuir tanné à Dakar, doublure coton, bandoulière amovible.',
    28500,
    5,
    'Accessoires',
    'demo-sac.jpg',
  ),
  _produit(
    '4',
    'Casque audio sans fil',
    'Bluetooth 5.3, réduction de bruit, 30 h d\'autonomie.',
    18000,
    20,
    'Électronique',
    'demo-casque.jpg',
  ),
  _produit(
    '5',
    'Montre homme acier',
    'Boîtier acier 42 mm, bracelet maille milanaise.',
    25000,
    7,
    'Accessoires',
    'demo-montre.jpg',
  ),
  _produit(
    '6',
    'Savon artisanal au karité',
    'Karité brut et huile de coco, fabriqué à Thiès.',
    3500,
    42,
    'Beauté',
    'demo-savon.jpg',
  ),
];

Map<String, dynamic> dashboardDemo() => {
  'stats': {
    'chiffreAffaires': 487500,
    'nombreCommandes': 23,
    'totalVues': 1842,
    'nombreAbonnes': 156,
  },
  'notificationsNonLues': 3,
};

Map<String, dynamic> _commande(
  String id,
  String reference,
  String prenom,
  String nom,
  String produit,
  String photo,
  int prix,
  int quantite,
  String statut,
  Duration anciennete,
) {
  final sousTotal = prix * quantite;
  return {
    'id': id,
    'referenceCommande': reference,
    'acheteurId': 'demo-acheteur-$id',
    'vendeurId': 'demo-vendeur',
    'montantProduits': sousTotal,
    'fraisLivraison': 2000,
    'montantTotal': sousTotal + 2000,
    'statut': statut,
    'statutPaiement': 'non_paye',
    'modeLivraison': 'livraison',
    'modePaiement': 'a_la_livraison',
    'adresseLivraison': 'Sacré-Cœur 3, Dakar',
    'numeroTelephone': '77 987 65 43',
    'createdAt': DateTime.now().subtract(anciennete).toIso8601String(),
    'acheteur': {'prenom': prenom, 'nom': nom, 'telephone': '77 987 65 43'},
    'lignes': [
      {
        'id': 'ligne-$id',
        'produitId': id,
        'nomProduit': produit,
        'imageProduit': photo,
        'prixUnitaire': prix,
        'quantite': quantite,
        'sousTotal': sousTotal,
      },
    ],
  };
}

List<Map<String, dynamic>> commandesDemo() => [
  _commande(
    '101',
    'SB-2026-0231',
    'Awa',
    'Diop',
    'Chemise en wax cousue main',
    'demo-chemise.jpg',
    22000,
    1,
    'confirmee',
    const Duration(minutes: 18),
  ),
  _commande(
    '102',
    'SB-2026-0230',
    'Mamadou',
    'Sow',
    'Baskets cuir blanches',
    'demo-baskets.jpg',
    32000,
    2,
    'en_preparation',
    const Duration(hours: 3),
  ),
  _commande(
    '103',
    'SB-2026-0229',
    'Fatou',
    'Ba',
    'Sac à main cousu main',
    'demo-sac.jpg',
    28500,
    1,
    'en_livraison',
    const Duration(hours: 9),
  ),
  _commande(
    '104',
    'SB-2026-0228',
    'Ibrahima',
    'Fall',
    'Casque audio sans fil',
    'demo-casque.jpg',
    18000,
    1,
    'livree',
    const Duration(days: 1),
  ),
];
