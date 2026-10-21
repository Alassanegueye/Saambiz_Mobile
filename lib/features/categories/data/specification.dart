/// Une spécification produit d'une catégorie : ce que le vendeur renseigne
/// en ajoutant un produit (tailles, pointures, contenance…).
///
/// Définie dans le dashboard admin ; le backend vérifie les mêmes règles
/// (Backend/src/services/categories/specifications.js).
class SpecificationProduit {
  final String cle;
  final String libelle;

  /// variantes | liste | choix | texte | nombre | oui_non
  final String type;
  final List<String> options;

  /// Variantes : le vendeur peut ajouter ses propres valeurs.
  final bool libre;
  final bool obligatoire;
  final String? unite;
  final String? aide;

  const SpecificationProduit({
    required this.cle,
    required this.libelle,
    required this.type,
    this.options = const [],
    this.libre = false,
    this.obligatoire = false,
    this.unite,
    this.aide,
  });

  factory SpecificationProduit.fromJson(Map<String, dynamic> json) => SpecificationProduit(
        cle: json['cle']?.toString() ?? '',
        libelle: json['libelle']?.toString() ?? '',
        type: json['type']?.toString() ?? 'texte',
        options: (json['options'] as List? ?? []).map((e) => e.toString()).toList(),
        libre: json['libre'] == true,
        obligatoire: json['obligatoire'] == true,
        unite: json['unite']?.toString(),
        aide: json['aide']?.toString(),
      );

  static List<SpecificationProduit> liste(dynamic brut) => (brut is List ? brut : const [])
      .whereType<Map>()
      .map((e) => SpecificationProduit.fromJson(Map<String, dynamic>.from(e)))
      .where((s) => s.cle.isNotEmpty && s.libelle.isNotEmpty)
      .toList();

  bool get multiple => type == 'variantes' || type == 'liste';

  /// Valeur vide au sens du formulaire (rien coché, rien saisi).
  static bool estVide(dynamic v) =>
      v == null || (v is String && v.trim().isEmpty) || (v is List && v.isEmpty);

  /// Messages des champs obligatoires non remplis, par clé.
  static Map<String, String> verifier(
      List<SpecificationProduit> specs, Map<String, dynamic> valeurs) {
    final erreurs = <String, String>{};
    for (final s in specs) {
      if (s.obligatoire && s.type != 'oui_non' && estVide(valeurs[s.cle])) {
        erreurs[s.cle] = 'À renseigner';
      }
    }
    return erreurs;
  }
}
