import 'package:dio/dio.dart';

import '../../../core/utils/app_logger.dart';

/// Catégorie de la marketplace — un seul niveau, pas de sous-rayons.
///
/// La liste, son ordre, les noms et les icônes se gèrent depuis le dashboard
/// admin : l'application ne fait que les afficher. Le `slug` est
/// l'identifiant stable (il ne change pas quand l'admin renomme).
class Categorie {
  final String id;
  final String nom;
  final String slug;
  final String? description;
  final String? icone;
  final String? image;
  final int nombreBoutiques;

  const Categorie({
    required this.id,
    required this.nom,
    required this.slug,
    this.description,
    this.icone,
    this.image,
    this.nombreBoutiques = 0,
  });

  factory Categorie.fromJson(Map<String, dynamic> json) => Categorie(
        id: json['id']?.toString() ?? '',
        nom: json['nom']?.toString() ?? '',
        slug: json['slug']?.toString() ?? json['id']?.toString() ?? '',
        description: json['description']?.toString(),
        icone: json['icone']?.toString(),
        image: json['image']?.toString(),
        nombreBoutiques: (json['nombreBoutiques'] is num)
            ? (json['nombreBoutiques'] as num).toInt()
            : int.tryParse('${json['nombreBoutiques'] ?? 0}') ?? 0,
      );

  /// Vrai si [valeur] désigne cette catégorie (slug, id ou nom).
  bool correspond(String valeur) {
    final v = valeur.trim().toLowerCase();
    return v == slug.toLowerCase() || v == id.toLowerCase() || v == nom.toLowerCase();
  }
}

/// Liste de secours, identique au référentiel du backend : affichée tant que
/// le réseau ne répond pas, pour que l'inscription ne reste jamais bloquée
/// sur une grille vide. Le serveur accepte ces slugs tels quels.
const List<Categorie> kCategoriesSecours = [
  Categorie(id: 'mode-femme', slug: 'mode-femme', nom: 'Mode femme', icone: 'checkroom'),
  Categorie(id: 'mode-homme', slug: 'mode-homme', nom: 'Mode homme', icone: 'man'),
  Categorie(id: 'chaussures-sacs', slug: 'chaussures-sacs', nom: 'Chaussures & sacs', icone: 'shopping_bag'),
  Categorie(id: 'beaute-cosmetiques', slug: 'beaute-cosmetiques', nom: 'Beauté & cosmétiques', icone: 'spa'),
  Categorie(id: 'bijoux-accessoires', slug: 'bijoux-accessoires', nom: 'Bijoux & accessoires', icone: 'diamond'),
  Categorie(id: 'telephones-electronique', slug: 'telephones-electronique', nom: 'Téléphones & électronique', icone: 'smartphone'),
  Categorie(id: 'maison-deco', slug: 'maison-deco', nom: 'Maison & déco', icone: 'chair'),
  Categorie(id: 'alimentation-epicerie', slug: 'alimentation-epicerie', nom: 'Alimentation & épicerie', icone: 'shopping_basket'),
  Categorie(id: 'plats-traiteur', slug: 'plats-traiteur', nom: 'Plats & traiteur', icone: 'restaurant'),
  Categorie(id: 'jus-boissons', slug: 'jus-boissons', nom: 'Jus & boissons', icone: 'local_drink'),
  Categorie(id: 'patisserie-gateaux', slug: 'patisserie-gateaux', nom: 'Pâtisserie & gâteaux', icone: 'cake'),
  Categorie(id: 'enfants-bebes', slug: 'enfants-bebes', nom: 'Enfants & bébés', icone: 'child_care'),
  Categorie(id: 'sante-bien-etre', slug: 'sante-bien-etre', nom: 'Santé & bien-être', icone: 'favorite'),
  Categorie(id: 'sport-loisirs', slug: 'sport-loisirs', nom: 'Sport & loisirs', icone: 'sports_soccer'),
  Categorie(id: 'artisanat', slug: 'artisanat', nom: 'Artisanat & fait main', icone: 'palette'),
  Categorie(id: 'services', slug: 'services', nom: 'Services', icone: 'handyman'),
  Categorie(id: 'autre', slug: 'autre', nom: 'Autre', icone: 'more_horiz'),
];

/// Une page de boutiques d'une catégorie.
class PageCategorie {
  final Categorie categorie;
  final List<Map<String, dynamic>> boutiques;
  final int total;

  const PageCategorie({
    required this.categorie,
    required this.boutiques,
    required this.total,
  });
}

/// Accès aux catégories (routes publiques, ouvertes aux invités).
class CategoriesRemoteDataSource {
  final Dio dio;
  const CategoriesRemoteDataSource(this.dio);

  // La liste change rarement (c'est l'admin qui la modifie) : on la garde
  // en mémoire le temps de la session pour ne pas la recharger à chaque écran.
  static List<Categorie>? _cache;
  static DateTime? _chargeeLe;
  static const _dureeCache = Duration(minutes: 30);

  /// Catégories actives, dans l'ordre fixé par l'admin. En cas d'échec
  /// réseau, renvoie la liste de secours plutôt qu'une erreur.
  Future<List<Categorie>> lister({bool forcer = false}) async {
    final cache = _cache;
    final chargeeLe = _chargeeLe;
    if (!forcer &&
        cache != null &&
        chargeeLe != null &&
        DateTime.now().difference(chargeeLe) < _dureeCache) {
      return cache;
    }
    try {
      final res = await dio.get('/categories');
      final brut = (res.data is Map ? (res.data as Map)['categories'] : res.data) as List? ?? [];
      final liste = brut
          .whereType<Map>()
          .map((e) => Categorie.fromJson(Map<String, dynamic>.from(e)))
          .where((c) => c.nom.isNotEmpty)
          .toList();
      if (liste.isEmpty) return cache ?? kCategoriesSecours;
      _cache = liste;
      _chargeeLe = DateTime.now();
      return liste;
    } on DioException catch (e) {
      logDebug('⚠️ catégories: ${e.response?.statusCode}');
      return cache ?? kCategoriesSecours;
    } catch (_) {
      return cache ?? kCategoriesSecours;
    }
  }

  /// Boutiques d'une catégorie (par slug ou id), les plus proches d'abord
  /// si la position est connue.
  Future<PageCategorie> boutiques(
    String slugOuId, {
    int page = 1,
    double? latitude,
    double? longitude,
  }) async {
    final res = await dio.get(
      '/categories/${Uri.encodeComponent(slugOuId)}/boutiques',
      queryParameters: {
        'page': page,
        'limit': 20,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    final data = Map<String, dynamic>.from(res.data as Map);
    final pagination = data['pagination'] is Map ? data['pagination'] as Map : const {};
    return PageCategorie(
      categorie: Categorie.fromJson(Map<String, dynamic>.from(data['categorie'] as Map)),
      boutiques: (data['boutiques'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      total: (pagination['total'] is num) ? (pagination['total'] as num).toInt() : 0,
    );
  }
}
