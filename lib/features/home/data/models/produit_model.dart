/// Image supplémentaire d'un produit (galerie multi-images vendeur).
class ProduitImage {
  final String id;
  final String url;
  final int ordre;

  ProduitImage({required this.id, required this.url, this.ordre = 0});

  factory ProduitImage.fromJson(Map<String, dynamic> json) => ProduitImage(
        id: json['id']?.toString() ?? '',
        url: (json['url'] ?? json['image'] ?? '').toString(),
        ordre: (json['ordre'] is int)
            ? json['ordre'] as int
            : int.tryParse(json['ordre']?.toString() ?? '') ?? 0,
      );
}

class ProduitModel {
  final String id;
  final String nom;
  final String description;
  final String prix;
  final int quantite;
  final String image;
  final String ville;       // extrait de vendeur.boutiques[0].localisation
  final String categorie;   // extrait de categorie.nom
  final String vendeurNom;  // extrait de vendeur.nom + prenom
  final String vendeurNumero;  // extrait de vendeur.nom + prenom
  final String vendeurId;   // id du vendeur (pour le panier / commande)
  final String boutiqueId;  // id de la boutique (favoris / avis / signalements)
  final List<ProduitImage>? images; // galerie d'images supplémentaires (vendeur)

  ProduitModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.quantite,
    required this.image,
    required this.ville,
    required this.categorie,
    required this.vendeurNom,
    required this.vendeurNumero,
    required this.vendeurId,
    this.boutiqueId = '',
    this.images,
  });

  factory ProduitModel.fromJson(Map<String, dynamic> json) {
    // ── Vendeur ──────────────────────────────────────────────────────
    final vendeur   = json['vendeur'] as Map<String, dynamic>?;
    final vPrenom   = vendeur?['prenom'] ?? '';
    final vNom      = vendeur?['nom'] ?? '';
    final vendeurNom = '$vPrenom $vNom'.trim();
    final vendeurNumero = vendeur?['telephone'] ?? '';
    final vendeurId = (json['vendeurId'] ?? vendeur?['id'] ?? '').toString();

    // ── Localisation + id (première boutique du vendeur) ─────────────
    String ville = '';
    String boutiqueId = '';
    if (vendeur != null) {
      final boutiques = vendeur['boutiques'];
      if (boutiques is List && boutiques.isNotEmpty) {
        ville = boutiques[0]['localisation'] ?? '';
        boutiqueId = boutiques[0]['id']?.toString() ?? '';
      }
    }
    // Fallback : à défaut d'id de boutique explicite, on retombe sur le
    // vendeur (cohérent avec le reste du modèle qui suppose 1 boutique/vendeur).
    if (boutiqueId.isEmpty) boutiqueId = vendeurId;

    // ── Catégorie ────────────────────────────────────────────────────
    final categorieMap = json['categorie'] as Map<String, dynamic>?;
    final categorie = categorieMap?['nom'] ?? '';

    // ── Images supplémentaires (galerie vendeur) ──────────────────────
    List<ProduitImage>? images;
    final rawImages = json['images'];
    if (rawImages is List) {
      images = rawImages
          .whereType<Map>()
          .map((e) => ProduitImage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return ProduitModel(
      id:          json['id']?.toString() ?? '',
      nom:         json['nom'] ?? '',
      description: json['description'] ?? '',
      prix:        json['prix']?.toString() ?? '0',
      quantite:    (json['quantite'] ?? 0) as int,
      image:       json['image'] ?? '',
      ville:       ville,
      categorie:   categorie,
      vendeurNom:  vendeurNom,
      vendeurNumero:  vendeurNumero,
      vendeurId:   vendeurId,
      boutiqueId:  boutiqueId,
      images:      images,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'nom':         nom,
    'description': description,
    'prix':        prix,
    'quantite':    quantite,
    'image':       image,
    'ville':       ville,
    'categorie':   categorie,
    'vendeurNom':  vendeurNom,
  };
}