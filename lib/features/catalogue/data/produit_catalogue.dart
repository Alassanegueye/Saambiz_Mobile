/// Produit tel que le catalogue public le décrit (`/catalogue/...`).
///
/// Une seule forme pour tout l'espace client : accueil, catégories,
/// recherche, fiche, promotions. Le prix payé, le prix barré, la remise et
/// la fin de promotion (compte à rebours) arrivent déjà calculés.
class ProduitCatalogue {
  final String id;
  final String nom;
  final String description;
  final double prix;
  final double? prixPromo;
  final int remise;
  final DateTime? finPromotion;
  final String image;
  final List<String> images;
  final String? marque;
  final bool disponible;
  final int stock;
  final bool enRupture;

  /// Ce que le client choisit avant d'ajouter au panier (tailles, parfums…).
  final List<OptionProduit> options;

  /// Informations du vendeur (matière, état…).
  final List<Caracteristique> caracteristiques;
  final CategorieResume? categorie;
  final String vendeurId;
  final BoutiqueResume? boutique;
  final int nombreVentes;
  final bool nouveau;

  const ProduitCatalogue({
    required this.id,
    required this.nom,
    this.description = '',
    required this.prix,
    this.prixPromo,
    this.remise = 0,
    this.finPromotion,
    this.image = '',
    this.images = const [],
    this.marque,
    this.disponible = true,
    this.stock = 0,
    this.enRupture = false,
    this.options = const [],
    this.caracteristiques = const [],
    this.categorie,
    this.vendeurId = '',
    this.boutique,
    this.nombreVentes = 0,
    this.nouveau = false,
  });

  /// Prix réellement payé.
  double get prixPaye => (prixPromo != null && prixPromo! < prix) ? prixPromo! : prix;

  /// Prix d'origine à barrer, s'il y a une remise.
  double? get prixBarre => (prixPromo != null && prixPromo! < prix) ? prix : null;

  /// Visuels : la galerie, à défaut l'image principale.
  List<String> get visuels {
    final liste = [if (image.isNotEmpty) image, ...images.where((i) => i.isNotEmpty && i != image)];
    return liste;
  }

  bool get aDesOptions => options.any((o) => o.valeurs.isNotEmpty);

  static double _double(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

  factory ProduitCatalogue.fromJson(Map<String, dynamic> j) {
    final promo = j['prixPromo'];
    return ProduitCatalogue(
      id: j['id']?.toString() ?? '',
      nom: j['nom']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      prix: _double(j['prix']),
      prixPromo: promo == null ? null : _double(promo),
      remise: (j['remise'] is num) ? (j['remise'] as num).toInt() : 0,
      finPromotion: j['finPromotion'] == null ? null : DateTime.tryParse(j['finPromotion'].toString())?.toLocal(),
      image: j['image']?.toString() ?? '',
      images: (j['images'] as List? ?? []).map((e) => e.toString()).toList(),
      marque: j['marque']?.toString(),
      disponible: j['disponible'] != false,
      stock: (j['stock'] is num) ? (j['stock'] as num).toInt() : 0,
      enRupture: j['enRupture'] == true,
      options: (j['options'] as List? ?? [])
          .whereType<Map>()
          .map((e) => OptionProduit.fromJson(Map<String, dynamic>.from(e)))
          .where((o) => o.valeurs.isNotEmpty)
          .toList(),
      caracteristiques: (j['caracteristiques'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Caracteristique.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      categorie: j['categorie'] is Map
          ? CategorieResume.fromJson(Map<String, dynamic>.from(j['categorie'] as Map))
          : null,
      vendeurId: j['vendeurId']?.toString() ?? '',
      boutique: j['boutique'] is Map
          ? BoutiqueResume.fromJson(Map<String, dynamic>.from(j['boutique'] as Map))
          : null,
      nombreVentes: (j['nombreVentes'] is num) ? (j['nombreVentes'] as num).toInt() : 0,
      nouveau: j['nouveau'] == true,
    );
  }
}

class OptionProduit {
  final String cle;
  final String libelle;
  final List<String> valeurs;
  const OptionProduit({required this.cle, required this.libelle, required this.valeurs});

  factory OptionProduit.fromJson(Map<String, dynamic> j) => OptionProduit(
        cle: j['cle']?.toString() ?? '',
        libelle: j['libelle']?.toString() ?? j['cle']?.toString() ?? '',
        valeurs: (j['valeurs'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList(),
      );
}

class Caracteristique {
  final String libelle;
  final String valeur;
  const Caracteristique({required this.libelle, required this.valeur});

  factory Caracteristique.fromJson(Map<String, dynamic> j) => Caracteristique(
        libelle: j['libelle']?.toString() ?? '',
        valeur: j['valeur']?.toString() ?? '',
      );
}

class CategorieResume {
  final String id;
  final String nom;
  final String slug;
  final String? icone;
  const CategorieResume({required this.id, required this.nom, required this.slug, this.icone});

  factory CategorieResume.fromJson(Map<String, dynamic> j) => CategorieResume(
        id: j['id']?.toString() ?? '',
        nom: j['nom']?.toString() ?? '',
        slug: j['slug']?.toString() ?? j['id']?.toString() ?? '',
        icone: j['icone']?.toString(),
      );
}

class BoutiqueResume {
  final String id;
  final String nom;
  final String? slug;
  final String? logo;
  final String localisation;
  final String telephone;
  final bool verifiee;

  const BoutiqueResume({
    required this.id,
    required this.nom,
    this.slug,
    this.logo,
    this.localisation = '',
    this.telephone = '',
    this.verifiee = false,
  });

  factory BoutiqueResume.fromJson(Map<String, dynamic> j) => BoutiqueResume(
        id: j['id']?.toString() ?? '',
        nom: j['nom']?.toString() ?? '',
        slug: j['slug']?.toString(),
        logo: j['logo']?.toString(),
        localisation: (j['localisation'] ?? j['ville'] ?? '').toString(),
        telephone: (j['telephone'] ?? j['whatsapp'] ?? '').toString(),
        verifiee: j['verifiee'] == true,
      );
}

/// Une page de résultats.
class PageProduits {
  final List<ProduitCatalogue> produits;
  final int total;
  final int pages;
  final CategorieResume? categorie;
  const PageProduits({required this.produits, this.total = 0, this.pages = 1, this.categorie});
}
