import 'dart:convert';

/// Données fictives des aperçus : boutiques, produits, commandes, comptes.
///
/// Tout est inventé (noms, prix, adresses). Les images `apercu:<nom>` sont
/// lues dans `test_apercu/images/<nom>.jpg|png`.
class Donnees {
  Donnees._();

  /// Compte simulé : 'client' ou 'vendeur' (change /account/me).
  static String profil = 'client';

  static final DateTime maintenant = DateTime.now();

  static String _il(Duration d) => maintenant.subtract(d).toIso8601String();
  static String _dans(Duration d) => maintenant.add(d).toIso8601String();

  // ─── Catégories ──────────────────────────────────────────────────────────
  static const categories = <Map<String, dynamic>>[
    {'id': 'c1', 'slug': 'mode-femme', 'nom': 'Mode femme', 'icone': 'checkroom', 'nombreProduits': 148},
    {'id': 'c2', 'slug': 'mode-homme', 'nom': 'Mode homme', 'icone': 'man', 'nombreProduits': 96},
    {'id': 'c3', 'slug': 'chaussures-sacs', 'nom': 'Chaussures & sacs', 'icone': 'shopping_bag', 'nombreProduits': 83},
    {'id': 'c4', 'slug': 'beaute-cosmetiques', 'nom': 'Beauté & cosmétiques', 'icone': 'spa', 'nombreProduits': 121},
    {'id': 'c5', 'slug': 'telephones-electronique', 'nom': 'Téléphones & électronique', 'icone': 'smartphone', 'nombreProduits': 64},
    {'id': 'c6', 'slug': 'alimentation-epicerie', 'nom': 'Alimentation & épicerie', 'icone': 'shopping_basket', 'nombreProduits': 112},
    {'id': 'c7', 'slug': 'maison-deco', 'nom': 'Maison & déco', 'icone': 'chair', 'nombreProduits': 57},
    {'id': 'c8', 'slug': 'bijoux-accessoires', 'nom': 'Bijoux & accessoires', 'icone': 'diamond', 'nombreProduits': 71},
    {'id': 'c9', 'slug': 'jus-boissons', 'nom': 'Jus & boissons', 'icone': 'local_drink', 'nombreProduits': 38},
    {'id': 'c10', 'slug': 'patisserie-gateaux', 'nom': 'Pâtisserie & gâteaux', 'icone': 'cake', 'nombreProduits': 29},
    {'id': 'c11', 'slug': 'artisanat', 'nom': 'Artisanat & fait main', 'icone': 'palette', 'nombreProduits': 45},
    {'id': 'c12', 'slug': 'sport-loisirs', 'nom': 'Sport & loisirs', 'icone': 'sports_soccer', 'nombreProduits': 33},
  ];

  static Map<String, dynamic> _cat(String id) {
    final c = categories.firstWhere((c) => c['id'] == id);
    return {'id': c['id'], 'nom': c['nom'], 'slug': c['slug'], 'icone': c['icone']};
  }

  // ─── Boutiques ───────────────────────────────────────────────────────────
  static final boutiques = <Map<String, dynamic>>[
    _boutique('b1', 'Maison Ndiaye Couture', 'logo_maison_ndiaye', 'Mode femme', 'Dakar, Plateau',
        slogan: 'Le wax sur mesure, cousu à Dakar', note: 4.8, distance: 1.2, banniere: 'banniere_maison_ndiaye'),
    _boutique('b2', 'Kër Beauté', 'logo_ker_beaute', 'Beauté & cosmétiques', 'Dakar, Mermoz',
        slogan: 'Soins naturels au karité', note: 4.6, distance: 2.8, banniere: 'banniere_ker_beaute'),
    _boutique('b3', 'Sandaga Tech', 'logo_sandaga_tech', 'Téléphones & électronique', 'Dakar, Sandaga',
        slogan: 'High-tech garanti 12 mois', note: 4.4, distance: 3.5, banniere: 'banniere_sandaga_tech'),
    _boutique('b4', 'Thiossane Épicerie', 'logo_thiossane', 'Alimentation & épicerie', 'Saint-Louis',
        slogan: 'Produits du terroir sénégalais', note: 4.9, verifiee: false),
    _boutique('b5', 'Ndar Sneakers', 'logo_ndar_sneakers', 'Chaussures & sacs', 'Thiès', note: 4.3, distance: 6.1),
    _boutique('b6', 'Atelier Wax & Co', 'logo_wax_co', 'Artisanat & fait main', 'Dakar, Ouakam', note: 4.7),
    _boutique('b7', 'Bissap House', 'logo_bissap_house', 'Jus & boissons', 'Dakar, Yoff', note: 4.5, distance: 4.0, verifiee: false),
    _boutique('b8', 'Teranga Déco', 'logo_teranga_deco', 'Maison & déco', 'Rufisque', note: 4.2),
  ];

  static Map<String, dynamic> _boutique(
    String id,
    String nom,
    String logo,
    String categorie,
    String localisation, {
    String? slogan,
    double? note,
    double? distance,
    bool verifiee = true,
    String? banniere,
  }) => {
    'id': id,
    'nom': nom,
    'slug': nom.toLowerCase().replaceAll(' ', '-'),
    'logo': 'apercu:$logo',
    if (banniere != null) 'banniere': 'apercu:$banniere',
    'categorie': categorie,
    'localisation': localisation,
    if (slogan != null) 'slogan': slogan,
    'verifiee': verifiee,
    if (note != null) 'note': note,
    if (distance != null) 'distanceKm': distance,
    'telephone': '+221 77 123 45 67',
  };

  static Map<String, dynamic> _resumeBoutique(String id) {
    final b = boutiques.firstWhere((b) => b['id'] == id);
    return {
      'id': b['id'],
      'nom': b['nom'],
      'slug': b['slug'],
      'logo': b['logo'],
      'localisation': b['localisation'],
      'telephone': b['telephone'],
      'verifiee': b['verifiee'],
    };
  }

  // ─── Produits ────────────────────────────────────────────────────────────
  static final produits = <Map<String, dynamic>>[
    _produit('p1', 'Robe wax évasée Ndeye', 'robe', 18500, promo: 14900, fin: const Duration(hours: 9, minutes: 24), boutique: 'b1', cat: 'c1', ventes: 64,
        options: [
          {'cle': 'taille', 'libelle': 'Taille', 'valeurs': ['S', 'M', 'L', 'XL']},
          {'cle': 'couleur', 'libelle': 'Motif', 'valeurs': ['Bleu indigo', 'Ocre', 'Vert']},
        ],
        caracteristiques: [
          {'libelle': 'Matière', 'valeur': 'Coton wax 100 %'},
          {'libelle': 'Entretien', 'valeur': 'Lavage à 30 °C'},
          {'libelle': 'Confection', 'valeur': 'Cousu main à Dakar'},
        ],
        description:
            'Robe évasée taillée dans un wax hollandais aux couleurs vives. Coupe ajustée à la taille, longueur sous le genou, poches latérales. Retouches offertes en boutique.'),
    _produit('p2', 'Baskets running légères', 'baskets', 32000, promo: 25600, fin: const Duration(days: 1, hours: 5), boutique: 'b5', cat: 'c3', ventes: 41),
    _produit('p3', 'Sac cabas en cuir tressé', 'sac', 27500, boutique: 'b6', cat: 'c3', nouveau: true, ventes: 12),
    _produit('p4', 'Montre connectée Sport', 'montre', 39900, promo: 29900, fin: const Duration(hours: 3, minutes: 12), boutique: 'b3', cat: 'c5', ventes: 88),
    _produit('p5', 'Casque sans fil Bluetooth', 'casque', 24500, boutique: 'b3', cat: 'c5', ventes: 57),
    _produit('p6', 'Lait corporel au karité 400 ml', 'lait', 6500, promo: 4900, fin: const Duration(days: 2), boutique: 'b2', cat: 'c4', ventes: 132),
    _produit('p7', 'Miel de Casamance 500 g', 'miel', 5500, boutique: 'b4', cat: 'c6', nouveau: true, ventes: 76),
    _produit('p8', 'Café Touba moulu 250 g', 'cafe', 2500, boutique: 'b4', cat: 'c6', ventes: 210),
    _produit('p9', 'Mangues Kent (le kilo)', 'mangue', 1500, boutique: 'b4', cat: 'c6', nouveau: true),
    _produit('p10', 'Lunettes de soleil polarisées', 'lunettes', 12000, promo: 8900, fin: const Duration(hours: 20), boutique: 'b6', cat: 'c8'),
    _produit('p11', 'Smartphone 128 Go double SIM', 'smartphone', 119000, boutique: 'b3', cat: 'c5', nouveau: true, ventes: 19),
    _produit('p12', 'Escarpins vernis rouges', 'escarpins', 21000, boutique: 'b5', cat: 'c3'),
    _produit('p13', 'Plante d’intérieur en pot', 'plante', 9500, boutique: 'b8', cat: 'c7', nouveau: true),
    _produit('p14', 'Panier tressé artisanal', 'panier', 7500, boutique: 'b6', cat: 'c11', ventes: 33),
    _produit('p15', 'Rouge à lèvres mat longue tenue', 'rouge', 4500, boutique: 'b2', cat: 'c4', ventes: 95),
    _produit('p16', 'Jus de bissap 1 L', 'jus', 1500, boutique: 'b7', cat: 'c9', nouveau: true, ventes: 300),
    _produit('p17', 'Chemise en lin col mao', 'chemise', 16500, boutique: 'b1', cat: 'c2', ventes: 22),
    _produit('p18', 'Foulard en soie imprimé', 'foulard', 8000, promo: 6400, fin: const Duration(days: 3), boutique: 'b1', cat: 'c8'),
    _produit('p19', 'Bougie parfumée vanille', 'bougie', 5000, boutique: 'b8', cat: 'c7'),
    _produit('p20', 'Savon noir artisanal', 'savon', 1800, boutique: 'b2', cat: 'c4', stock: 0),
    _produit('p21', 'Sandales en cuir', 'sandales', 11000, boutique: 'b5', cat: 'c3', nouveau: true),
    _produit('p22', 'Gâteau au chocolat (8 parts)', 'gateau', 12500, boutique: 'b7', cat: 'c10'),
  ];

  static Map<String, dynamic> _produit(
    String id,
    String nom,
    String image,
    num prix, {
    num? promo,
    Duration? fin,
    required String boutique,
    required String cat,
    bool nouveau = false,
    int ventes = 0,
    int stock = 14,
    String? description,
    List<Map<String, dynamic>> options = const [],
    List<Map<String, dynamic>> caracteristiques = const [],
  }) => {
    'id': id,
    'nom': nom,
    'description':
        description ??
        'Produit sélectionné par la boutique. Livraison à Dakar sous 24 h, retrait possible en boutique.',
    'prix': prix,
    'prixPromo': promo,
    'remise': promo == null ? 0 : ((1 - promo / prix) * 100).round(),
    'finPromotion': fin == null ? null : _dans(fin),
    'image': 'apercu:$image',
    'images': ['apercu:$image'],
    'marque': null,
    'disponible': true,
    'stock': stock,
    'enRupture': stock <= 0,
    'options': options,
    'caracteristiques': caracteristiques,
    'categorie': _cat(cat),
    'vendeurId': 'v-$boutique',
    'boutique': _resumeBoutique(boutique),
    'nombreVentes': ventes,
    'nouveau': nouveau,
  };

  static Map<String, dynamic> produit(String id) =>
      produits.firstWhere((p) => p['id'] == id);

  static List<Map<String, dynamic>> _ids(List<String> ids) =>
      [for (final i in ids) produit(i)];

  static List<Map<String, dynamic>> _boutiquesIds(List<String> ids) =>
      [for (final i in ids) boutiques.firstWhere((b) => b['id'] == i)];

  // ─── Accueil ─────────────────────────────────────────────────────────────
  static Map<String, dynamic> section(String cle) => switch (cle) {
    'promotions' => {
      'cle': 'promotions',
      'titre': 'Promotions du moment',
      'sousTitre': 'Vos catégories d’abord',
      'type': 'produits',
      'elements': _ids(['p4', 'p1', 'p2', 'p6', 'p10', 'p18']),
    },
    'produitsPourVous' => {
      'cle': 'produitsPourVous',
      'titre': 'Pour vous',
      'sousTitre': 'Mode femme · Beauté & cosmétiques',
      'type': 'produits',
      'elements': _ids(['p17', 'p15', 'p3', 'p12', 'p6', 'p18']),
    },
    'nouveautes' => {
      'cle': 'nouveautes',
      'titre': 'Nouveautés',
      'type': 'produits',
      'elements': _ids(['p11', 'p7', 'p16', 'p13', 'p21', 'p9', 'p3']),
    },
    'abonnements' => {
      'cle': 'abonnements',
      'titre': 'Chez les boutiques que vous suivez',
      'type': 'produits',
      'elements': _ids(['p1', 'p17', 'p18', 'p5']),
    },
    'suivies' => {
      'cle': 'suivies',
      'titre': 'Vos boutiques',
      'type': 'boutiques',
      'elements': _boutiquesIds(['b1', 'b3']),
    },
    'pourVous' => {
      'cle': 'pourVous',
      'titre': 'Sélectionné pour vous',
      'sousTitre': 'Mode femme · Beauté & cosmétiques',
      'type': 'boutiques',
      'elements': _boutiquesIds(['b2', 'b6', 'b1', 'b5']),
    },
    'proches' => {
      'cle': 'proches',
      'titre': 'Près de chez vous',
      'type': 'boutiques',
      'elements': _boutiquesIds(['b1', 'b2', 'b3', 'b7']),
    },
    'meilleures' => {
      'cle': 'meilleures',
      'titre': 'Les mieux notées',
      'type': 'boutiques',
      'elements': _boutiquesIds(['b4', 'b1', 'b6', 'b2']),
    },
    'nouvelles' => {
      'cle': 'nouvelles',
      'titre': 'Nouvelles boutiques',
      'type': 'boutiques',
      'elements': _boutiquesIds(['b8', 'b7', 'b5']),
    },
    _ => {'cle': cle, 'titre': cle, 'type': 'produits', 'elements': []},
  };

  static Map<String, dynamic> accueil({bool invite = false}) => {
    'invite': invite,
    'categories': categories,
    'interets': ['Mode femme', 'Beauté & cosmétiques'],
    'positionConnue': true,
    'sections': [
      for (final cle in [
        'promotions',
        'produitsPourVous',
        if (!invite) 'abonnements',
        'nouveautes',
        if (!invite) 'suivies',
        'pourVous',
        'proches',
        'meilleures',
        'nouvelles',
      ])
        section(cle),
    ],
  };

  // ─── Comptes ─────────────────────────────────────────────────────────────
  static Map<String, dynamic> get utilisateur => profil == 'vendeur'
      ? {
          'id': 'u-vendeur',
          'prenom': 'Awa',
          'nom': 'Ndiaye',
          'email': 'awa.ndiaye@exemple.sn',
          'telephone': '+221771234567',
          'adresse': 'Dakar, Plateau',
          'role': 'Vendeur',
          'photoProfil': null,
          'soldeDisponible': 186500,
        }
      : {
          'id': 'u-client',
          'prenom': 'Moussa',
          'nom': 'Diop',
          'email': 'moussa.diop@exemple.sn',
          'telephone': '+221781112233',
          'adresse': 'Dakar, Sacré-Cœur 3',
          'role': 'Acheteur',
          'photoProfil': null,
        };

  // ─── Commandes ───────────────────────────────────────────────────────────
  static Map<String, dynamic> _commande(
    String id,
    String ref,
    String statut,
    Duration il,
    List<(String, int)> lignes, {
    String paiement = 'non_paye',
    String livraison = 'livraison',
    String client = 'Fatou Sow',
    String boutique = 'b1',
  }) {
    final l = [
      for (final (pid, q) in lignes)
        () {
          final p = produit(pid);
          final pu = (p['prixPromo'] ?? p['prix']) as num;
          return {
            'id': 'l-$id-$pid',
            'produitId': pid,
            'nomProduit': p['nom'],
            'imageProduit': p['image'],
            'prixUnitaire': pu,
            'quantite': q,
            'sousTotal': pu * q,
            if (pid == 'p1') 'options': {'Taille': 'M', 'Motif': 'Bleu indigo'},
          };
        }(),
    ];
    final montant = l.fold<num>(0, (t, e) => t + (e['sousTotal'] as num));
    final frais = livraison == 'livraison' ? 1500 : 0;
    final noms = client.split(' ');
    final b = boutiques.firstWhere((x) => x['id'] == boutique);
    return {
      'id': id,
      'referenceCommande': ref,
      'acheteurId': 'u-client',
      'vendeurId': 'v-$boutique',
      'montantProduits': montant,
      'fraisLivraison': frais,
      'montantTotal': montant + frais,
      'statut': statut,
      'statutPaiement': paiement,
      'modeLivraison': livraison,
      'modePaiement': 'en_ligne',
      'adresseLivraison': 'Sacré-Cœur 3, villa 214, Dakar',
      'numeroTelephone': '+221781112233',
      'note': null,
      'createdAt': _il(il),
      'lignes': l,
      'acheteur': {'prenom': noms.first, 'nom': noms.last, 'telephone': '+221781112233'},
      'vendeur': {'prenom': b['nom'], 'nom': '', 'telephone': '+221771234567'},
    };
  }

  static List<Map<String, dynamic>> get commandesClient => [
    _commande('cmd1', 'SB-24117', 'en_livraison', const Duration(hours: 5), [('p1', 1), ('p18', 1)], paiement: 'paye'),
    _commande('cmd2', 'SB-24093', 'en_attente', const Duration(days: 1, hours: 2), [('p4', 1)], boutique: 'b3'),
    _commande('cmd3', 'SB-23988', 'livree', const Duration(days: 6), [('p7', 2), ('p8', 3)], paiement: 'paye', boutique: 'b4'),
    _commande('cmd4', 'SB-23851', 'annulee', const Duration(days: 12), [('p2', 1)], boutique: 'b5'),
  ];

  static List<Map<String, dynamic>> get commandesVendeur => [
    _commande('v1', 'SB-24121', 'en_attente', const Duration(minutes: 18), [('p1', 2)], client: 'Fatou Sow'),
    _commande('v2', 'SB-24119', 'en_attente', const Duration(hours: 1, minutes: 5), [('p18', 1), ('p17', 1)], client: 'Ibrahima Fall'),
    _commande('v3', 'SB-24102', 'en_preparation', const Duration(hours: 6), [('p17', 1)], client: 'Mariama Ba', paiement: 'paye'),
    _commande('v4', 'SB-24087', 'en_livraison', const Duration(days: 1), [('p1', 1)], client: 'Cheikh Ndiaye', paiement: 'paye'),
    _commande('v5', 'SB-24050', 'livree', const Duration(days: 3), [('p18', 2)], client: 'Aïssatou Diallo', paiement: 'paye', livraison: 'retrait'),
    _commande('v6', 'SB-24011', 'annulee', const Duration(days: 5), [('p1', 1)], client: 'Ousmane Sy'),
  ];

  // ─── Espace vendeur ──────────────────────────────────────────────────────
  static Map<String, dynamic> get maBoutique => {
    'id': 'b1',
    'nom': 'Maison Ndiaye Couture',
    'description': 'Couture sur mesure et prêt-à-porter en wax, cousus à Dakar.',
    'localisation': 'Dakar, Plateau',
    'telephone': '+221771234567',
    'whatsapp': '+221771234567',
    'logo': 'apercu:logo_maison_ndiaye',
    'banniere': 'apercu:banniere_maison_ndiaye',
    'categorie': 'Mode femme',
    'slogan': 'Le wax sur mesure, cousu à Dakar',
    'statut': 'actif',
    'note': 4.8,
    'nombreAvis': 37,
    'vendeur': {'id': 'u-vendeur', 'prenom': 'Awa', 'nom': 'Ndiaye', 'telephone': '+221771234567'},
  };

  static List<Map<String, dynamic>> get produitsVendeur => [
    for (final id in ['p1', 'p17', 'p18', 'p3', 'p14', 'p10'])
      () {
        final p = produit(id);
        return {
          'id': p['id'],
          'nom': p['nom'],
          'description': p['description'],
          'prix': '${p['prix']}',
          'quantite': id == 'p10' ? 0 : (id == 'p3' ? 3 : 14),
          'image': p['image'],
          'disponible': id != 'p14',
          'statut': id == 'p3' ? 'en_attente' : 'approuve',
          'categorie': p['categorie'],
          'categorieId': (p['categorie'] as Map)['id'],
          'images': [
            {'id': 'i$id', 'url': p['image'], 'ordre': 0},
          ],
          'vendeurId': 'u-vendeur',
          'vues': 120 + id.length * 37,
          'nombre_ventes': p['nombreVentes'],
        };
      }(),
  ];

  static Map<String, dynamic> get tableauDeBord => {
    'success': true,
    'data': {
      'stats': {
        'chiffreAffaires': 1245600,
        'nombreCommandes': 128,
        'totalVues': 3412,
        'nombreAbonnes': 214,
        'nombreProduits': 6,
      },
      'notificationsNonLues': 3,
    },
  };

  static List<Map<String, dynamic>> get promotions => [
    {
      'id': 'pr1',
      'titre': 'Soldes de la Tabaski',
      'description': '-20 % sur la robe Ndeye',
      'prixPromo': 14900,
      'dateDebut': _il(const Duration(days: 2)),
      'dateFin': _dans(const Duration(days: 5)),
      'produitId': 'p1',
      'produit': {'id': 'p1', 'nom': produit('p1')['nom'], 'prix': 18500, 'image': produit('p1')['image']},
      'actif': true,
      'statut': 'active',
    },
    {
      'id': 'pr2',
      'titre': 'Foulards de saison',
      'description': '-20 % sur les foulards',
      'prixPromo': 6400,
      'dateDebut': _il(const Duration(days: 1)),
      'dateFin': _dans(const Duration(days: 3)),
      'produitId': 'p18',
      'produit': {'id': 'p18', 'nom': produit('p18')['nom'], 'prix': 8000, 'image': produit('p18')['image']},
      'actif': true,
      'statut': 'active',
    },
    {
      'id': 'pr3',
      'titre': 'Fin de série chemises',
      'description': '',
      'prixPromo': 12900,
      'dateDebut': _il(const Duration(days: 20)),
      'dateFin': _il(const Duration(days: 6)),
      'produitId': 'p17',
      'produit': {'id': 'p17', 'nom': produit('p17')['nom'], 'prix': 16500, 'image': produit('p17')['image']},
      'actif': false,
      'statut': 'terminee',
    },
  ];

  static Map<String, dynamic> get vitrine => {
    'success': true,
    'data': {
      'vitrine': {
        'slug': 'maison-ndiaye-couture',
        'url': 'https://maison-ndiaye-couture.saambiz.com',
        'active': true,
        'configuree': true,
        'modele': 'classique',
        'accent': '#01154B',
        'apropos': 'Atelier de couture fondé en 2016 au Plateau.',
        'annonce': 'Livraison offerte dès 30 000 FCFA',
        'secteur': 'mode',
        'activite': 'Couture',
        'vues': 3412,
        'reseaux': {'instagram': '@maisonndiaye', 'whatsapp': '+221771234567'},
        'sections': {'apropos': true, 'avis': true},
        'sectionsPerso': [
          {'id': 's1', 'titre': 'Robes', 'produitIds': ['p1']},
          {'id': 's2', 'titre': 'Accessoires', 'produitIds': ['p18', 'p10']},
          {'id': 's3', 'titre': 'Homme', 'produitIds': ['p17']},
        ],
        'commande': true,
        'paiementLivraison': true,
      },
    },
  };

  static Map<String, dynamic> boutiquePublique(String id) {
    final b = boutiques.firstWhere((b) => b['id'] == id, orElse: () => boutiques.first);
    return {
      'boutique': {
        ...b,
        'description': 'Couture sur mesure et prêt-à-porter en wax, cousus à Dakar.',
        'whatsapp': '+221771234567',
        'nombreProduits': 24,
        'depuis': 2021,
        'nombreAvis': 37,
        'accent': '#01154B',
        'apropos':
            'Atelier fondé en 2016 au Plateau. Chaque pièce est coupée et cousue à la main par nos trois couturières.',
        'reseaux': {'instagram': 'maisonndiaye', 'facebook': 'maisonndiaye'},
        'avantages': [
          {'icone': 'local_shipping', 'titre': 'Livraison 24 h', 'texte': 'Partout à Dakar'},
          {'icone': 'straighten', 'titre': 'Retouches offertes', 'texte': 'En boutique'},
        ],
        'sections': [
          {'id': 's1', 'titre': 'Robes', 'produits': _ids(['p1', 'p18'])},
          {'id': 's3', 'titre': 'Homme', 'produits': _ids(['p17'])},
        ],
      },
    };
  }

  static const preferences = <String, Object>{
    'onboarding_vu': true,
  };

  /// Panier : deux articles de la même boutique.
  static String get panier => jsonEncode([
    {
      'produitId': 'p1',
      'nom': produit('p1')['nom'],
      'prix': 14900,
      'image': 'apercu:robe',
      'vendeurId': 'v-b1',
      'vendeurNom': 'Maison Ndiaye Couture',
      'options': {'Taille': 'M', 'Motif': 'Bleu indigo'},
      'quantite': 1,
    },
    {
      'produitId': 'p18',
      'nom': produit('p18')['nom'],
      'prix': 6400,
      'image': 'apercu:foulard',
      'vendeurId': 'v-b1',
      'vendeurNom': 'Maison Ndiaye Couture',
      'quantite': 2,
    },
  ]);

  static List<Map<String, dynamic>> get notifications => [
    {'id': 'n1', 'titre': 'Votre commande est en route', 'message': 'SB-24117 sera livrée aujourd’hui avant 18 h.', 'createdAt': _il(const Duration(minutes: 40)), 'lue': false},
    {'id': 'n2', 'titre': 'Nouvelle promotion', 'message': 'Maison Ndiaye Couture : -20 % sur la robe Ndeye.', 'createdAt': _il(const Duration(hours: 3)), 'lue': false},
    {'id': 'n3', 'titre': 'Commande livrée', 'message': 'SB-23988 a été livrée. Donnez votre avis sur Thiossane Épicerie.', 'createdAt': _il(const Duration(days: 6)), 'lue': true},
  ];

  /// Conversations telles que le serveur les renvoie : le dernier message,
  /// l'interlocuteur et sa boutique quand c'est un vendeur.
  static List<Map<String, dynamic>> get conversations => [
    {
      'id': 'm1', 'contenu': 'Bonjour, la robe Ndeye est disponible en taille M.',
      'createdAt': _il(const Duration(minutes: 6)),
      'interlocuteurId': 'v-b1', 'nombreNonLus': 2,
      'interlocuteur': {'id': 'v-b1', 'prenom': 'Awa', 'nom': 'Ndiaye', 'photoProfil': null,
        'boutique': {'id': 'b1', 'nom': boutiques[0]['nom'], 'logo': boutiques[0]['logo']}},
    },
    {
      'id': 'm2', 'contenu': 'Votre colis part demain matin.',
      'createdAt': _il(const Duration(hours: 2)),
      'interlocuteurId': 'v-b3', 'nombreNonLus': 0,
      'interlocuteur': {'id': 'v-b3', 'prenom': 'Ibou', 'nom': 'Fall', 'photoProfil': null,
        'boutique': {'id': 'b3', 'nom': boutiques[2]['nom'], 'logo': boutiques[2]['logo']}},
    },
  ];

  // ─── Routeur ─────────────────────────────────────────────────────────────
  /// Réponse simulée d'une requête, ou `null` si elle n'est pas prévue.
  static Object? repondre(String methode, String chemin, Map<String, dynamic> params) {
    final c = chemin.split('?').first;
    if (methode != 'GET') return {'success': true};

    if (c == '/acheteurs/accueil-personnalise') return accueil(invite: profil == 'invite');
    if (c.startsWith('/acheteurs/accueil-section/')) {
      final s = section(c.split('/').last);
      return {'titre': s['titre'], 'type': s['type'], 'elements': s['elements']};
    }
    if (c == '/acheteurs/preferences') return {'interets': ['Mode femme', 'Beauté & cosmétiques']};
    if (c == '/notifications/non-lues') return {'nombre': 2};
    if (c == '/notifications') return {'notifications': notifications};
    if (c == '/messages/non-lus') return {'nombre': 1};
    if (c == '/messages/site') return {'messages': <Map<String, dynamic>>[]};
    if (c == '/messages/conversations') return {'conversations': conversations};
    if (c == '/account/me') return {'utilisateur': utilisateur};
    if (c == '/categories') return {'categories': categories};
    if (c == '/catalogue/promotions') return {'produits': [for (final p in produits) if (p['prixPromo'] != null) p]};
    if (c == '/catalogue/produits') {
      var liste = produits.toList();
      final cat = params['categorie']?.toString();
      if (cat != null) liste = liste.where((p) => (p['categorie'] as Map)['slug'] == cat || (p['categorie'] as Map)['id'] == cat).toList();
      final b = params['boutique']?.toString();
      if (b != null) liste = liste.where((p) => (p['boutique'] as Map)['id'] == b).toList();
      if (params['promo'] != null) liste = liste.where((p) => p['prixPromo'] != null).toList();
      // Peu de résultats : on complète, pour remplir la grille de l'aperçu.
      if (liste.length < 6) {
        liste = [...liste, ...produits.where((p) => !liste.contains(p)).take(8 - liste.length)];
      }
      return {
        'produits': liste,
        'pagination': {'total': liste.length, 'pages': 1},
        if (cat != null) 'categorie': _cat(categories.firstWhere((x) => x['slug'] == cat || x['id'] == cat, orElse: () => categories.first)['id'] as String),
      };
    }
    if (c.startsWith('/catalogue/produits/')) {
      final id = c.split('/').last;
      return {'produit': produit(id), 'similaires': _ids(['p18', 'p17', 'p3', 'p10'])};
    }
    if (c == '/catalogue/boutiques') return {'boutiques': boutiques.take(3).toList()};
    if (c.startsWith('/catalogue/boutiques/')) return boutiquePublique(c.split('/').last);
    if (c.startsWith('/categories/') && c.endsWith('/boutiques')) {
      return {'categorie': categories.first, 'boutiques': boutiques.take(5).toList(), 'pagination': {'total': 5}};
    }
    if (c == '/favoris') {
      return {
        'favoris': [
          for (final b in _boutiquesIds(['b1', 'b3', 'b4', 'b2'])) {'boutique': {...b, 'note': b['note'], 'nombreAvis': 21}, 'clocheActive': b['id'] != 'b4'},
        ],
      };
    }
    if (c.startsWith('/favoris/') && c.endsWith('/statut')) return {'suivi': true, 'clocheActive': true};
    if (c == '/commandes') return {'commandes': commandesClient};
    if (c == '/commandes/vendeur') {
      final statut = params['statut']?.toString();
      return {'commandes': [for (final x in commandesVendeur) if (statut == null || x['statut'] == statut) x]};
    }
    if (c.startsWith('/commandes/')) {
      final id = c.split('/').last;
      final toutes = [...commandesClient, ...commandesVendeur];
      return {'commande': toutes.firstWhere((x) => x['id'] == id, orElse: () => toutes.first)};
    }
    if (c.startsWith('/avis/boutique/')) {
      return {
        'moyenne': 4.8,
        'total': 37,
        'avis': [
          {'id': 'a1', 'note': 5, 'commentaire': 'Robe magnifique, finitions parfaites.', 'createdAt': _il(const Duration(days: 4)), 'auteur': {'prenom': 'Khady', 'nom': 'S.'}},
        ],
      };
    }
    if (c == '/vendeur/dashboard') return tableauDeBord;
    if (c == '/vendeur/ma-boutique') return {'boutique': maBoutique};
    if (c == '/vendeur/liste-produits') return {'produits': produitsVendeur};
    if (c == '/vendeur/ma-vitrine') return vitrine;
    if (c == '/promotions' || c == '/promotions/actives') return {'promotions': promotions};
    if (c == '/vendeur/abonnes') {
      return {
        'abonnes': [
          {'id': 'u1', 'prenom': 'Fatou', 'nom': 'Sow', 'depuis': _il(const Duration(days: 40)), 'nombreCommandes': 4},
          {'id': 'u2', 'prenom': 'Ibrahima', 'nom': 'Fall', 'depuis': _il(const Duration(days: 12)), 'nombreCommandes': 1},
        ],
        'total': 214,
      };
    }
    if (c == '/vendeur/mon-abonnement') {
      return {
        'abonnement': {
          'formule': 'pro',
          'statut': 'actif',
          'dateDebut': _il(const Duration(days: 12)),
          'dateFin': _dans(const Duration(days: 18)),
          'prix': 5000,
        },
      };
    }
    if (c == '/vendeur/vitrine/secteurs') {
      return {
        'secteurs': [
          {'cle': 'mode', 'libelle': 'Mode et couture', 'exemples': 'Couture, prêt-à-porter', 'modeleRecommande': 'classique'},
          {'cle': 'beaute', 'libelle': 'Beauté', 'exemples': 'Cosmétiques, soins', 'modeleRecommande': 'classique'},
        ],
      };
    }
    if (c == '/vendeur/statistiques' || c == '/vendeur/statistiques-vues') return {'data': {}};
    return null;
  }
}
