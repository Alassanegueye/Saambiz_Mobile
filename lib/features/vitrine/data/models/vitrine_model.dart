import '../../domain/entities/vitrine.dart';

/// Lecture des réponses de l'API.
///
/// Les routes récentes répondent toutes `{ success, message, data }` ; les
/// plus anciennes renvoient l'objet nu. Les fabriques descendent donc dans
/// `data` quand il est là, et prennent la racine sinon — c'est ce qui permet
/// d'écrire les écrans sans se demander de quelle génération vient la route.
Map<String, dynamic> deballer(dynamic json) {
  if (json is Map<String, dynamic>) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }
  return <String, dynamic>{};
}

double _versDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

Map<String, String> _versTexte(dynamic v) {
  if (v is! Map) return const {};
  final out = <String, String>{};
  v.forEach((cle, valeur) {
    if (valeur != null && '$valeur'.isNotEmpty) out['$cle'] = '$valeur';
  });
  return out;
}

Map<String, bool> _versBooleens(dynamic v) {
  if (v is! Map) return const {};
  final out = <String, bool>{};
  v.forEach((cle, valeur) => out['$cle'] = valeur != false);
  return out;
}

class VitrineModel extends Vitrine {
  const VitrineModel({
    required super.slug,
    required super.url,
    required super.active,
    required super.configuree,
    required super.modele,
    required super.accent,
    super.apropos,
    super.annonce,
    super.horaires,
    super.secteur,
    super.activite,
    super.logoForme,
    super.reseaux,
    super.sections,
    super.commande,
    super.paiementLivraison,
    super.vues,
    super.logoEnregistre,
  });

  /// Attend la charge utile de `/vendeur/ma-vitrine`, qui enveloppe les
  /// réglages dans une clé `vitrine`.
  factory VitrineModel.fromJson(dynamic json) {
    final racine = deballer(json);
    final v = racine['vitrine'] is Map<String, dynamic>
        ? racine['vitrine'] as Map<String, dynamic>
        : racine;

    return VitrineModel(
      slug: '${v['slug'] ?? ''}',
      url: '${v['url'] ?? ''}',
      active: v['active'] != false,
      configuree: v['configuree'] == true,
      modele: '${v['modele'] ?? 'classique'}',
      accent: '${v['accent'] ?? '#0D1B3D'}',
      apropos: v['apropos']?.toString(),
      annonce: v['annonce']?.toString(),
      horaires: v['horaires']?.toString(),
      secteur: v['secteur']?.toString(),
      activite: v['activite']?.toString(),
      logoForme: '${v['logoForme'] ?? 'libre'}',
      reseaux: _versTexte(v['reseaux']),
      sections: _versBooleens(v['sections']),
      commande: v['commande'] != false,
      paiementLivraison: v['paiementLivraison'] != false,
      vues: (v['vues'] as num?)?.toInt() ?? 0,
      // Posé à la racine par la création, absent partout ailleurs : `null`
      // signifie donc « la question ne se pose pas », et non « échec ».
      logoEnregistre: racine.containsKey('logoEnregistre')
          ? racine['logoEnregistre'] == true
          : null,
    );
  }
}

class AnalyseLogoModel extends AnalyseLogo {
  const AnalyseLogoModel({
    super.largeur,
    super.hauteur,
    required super.forme,
    super.conseilForme,
    super.couleurs,
    required super.accentPropose,
    super.palette,
    super.niveauQualite,
    super.messageQualite,
  });

  factory AnalyseLogoModel.fromMap(Map<String, dynamic> a) {
    final dimensions = a['dimensions'];
    final qualite = a['qualite'];

    return AnalyseLogoModel(
      largeur: dimensions is Map ? (dimensions['largeur'] as num?)?.toInt() : null,
      hauteur: dimensions is Map ? (dimensions['hauteur'] as num?)?.toInt() : null,
      forme: '${a['forme'] ?? 'libre'}',
      conseilForme: a['conseilForme']?.toString(),
      couleurs: (a['couleurs'] as List? ?? [])
          .whereType<Map>()
          .map((c) => CouleurLogo(hex: '${c['hex']}', part: _versDouble(c['part'])))
          .toList(),
      accentPropose: '${a['accentPropose'] ?? '#0D1B3D'}',
      palette: (a['palette'] as List? ?? [])
          .whereType<Map>()
          .map((c) => CouleurProposee(hex: '${c['hex']}', nom: '${c['nom'] ?? ''}'))
          .toList(),
      niveauQualite: qualite is Map ? '${qualite['niveau'] ?? 'inconnue'}' : 'inconnue',
      messageQualite: qualite is Map ? qualite['message']?.toString() : null,
    );
  }
}

class PropositionVitrineModel extends PropositionVitrine {
  const PropositionVitrineModel({
    required super.modele,
    required super.accent,
    required super.slogan,
    required super.apropos,
    required super.horaires,
    super.palette,
    super.pourquoiModele,
    super.pourquoiCouleur,
    super.pourquoiLogo,
  });

  factory PropositionVitrineModel.fromMap(Map<String, dynamic> p) {
    final pourquoi = p['pourquoi'];
    return PropositionVitrineModel(
      modele: '${p['modele'] ?? 'classique'}',
      accent: '${p['accent'] ?? '#0D1B3D'}',
      slogan: '${p['slogan'] ?? ''}',
      apropos: '${p['apropos'] ?? ''}',
      horaires: '${p['horaires'] ?? ''}',
      palette: (p['palette'] as List? ?? [])
          .whereType<Map>()
          .map((c) => CouleurProposee(hex: '${c['hex']}', nom: '${c['nom'] ?? ''}'))
          .toList(),
      pourquoiModele: pourquoi is Map ? pourquoi['modele']?.toString() : null,
      pourquoiCouleur: pourquoi is Map ? pourquoi['couleur']?.toString() : null,
      pourquoiLogo: pourquoi is Map ? pourquoi['logo']?.toString() : null,
    );
  }
}

/// Ce que renvoie l'analyse du logo : ce qui a été trouvé, et le site proposé.
class ResultatAnalyse {
  final AnalyseLogo analyse;
  final PropositionVitrine proposition;

  const ResultatAnalyse({required this.analyse, required this.proposition});

  factory ResultatAnalyse.fromJson(dynamic json) {
    final d = deballer(json);
    return ResultatAnalyse(
      analyse: AnalyseLogoModel.fromMap(
        (d['analyse'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      proposition: PropositionVitrineModel.fromMap(
        (d['proposition'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
    );
  }
}

class SecteurVitrineModel extends SecteurVitrine {
  const SecteurVitrineModel({
    required super.cle,
    required super.libelle,
    required super.exemples,
    required super.modeleRecommande,
  });

  factory SecteurVitrineModel.fromMap(Map<String, dynamic> s) => SecteurVitrineModel(
        cle: '${s['cle']}',
        libelle: '${s['libelle']}',
        exemples: '${s['exemples'] ?? ''}',
        modeleRecommande: '${s['modeleRecommande'] ?? 'classique'}',
      );
}
