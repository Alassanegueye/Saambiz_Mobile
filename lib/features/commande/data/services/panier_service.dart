import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/panier_item.dart';

/// Service de gestion du panier local (persisté via SharedPreferences).
///
/// Le panier peut contenir les produits de plusieurs boutiques ; l'écran les
/// range par boutique. Règle métier alignée sur le backend : **une commande
/// = une boutique**. Le client coche les produits à commander, tous d'une
/// même boutique ([basculer] remplace la sélection quand il change de
/// boutique), et ne peut valider qu'avec au moins un produit coché.
///
/// [PanierVendeurDifferentException] n'est plus levée ; elle reste déclarée
/// pour les écrans qui l'attrapent encore.
class PanierVendeurDifferentException implements Exception {
  final String message;
  PanierVendeurDifferentException([
    this.message =
        'Votre panier contient déjà des produits d\'une autre boutique. Videz-le pour commander ailleurs.',
  ]);
  @override
  String toString() => message;
}

class PanierService extends ChangeNotifier {
  static const String _key = 'panier_items';
  final SharedPreferences prefs;

  List<PanierItem> _items = [];

  /// Lignes cochées pour la prochaine commande (clés `PanierItem.cle`),
  /// toutes du même vendeur.
  final Set<String> _selection = {};

  PanierService({required this.prefs}) {
    _charger();
  }

  List<PanierItem> get items => List.unmodifiable(_items);
  int get nombreArticles => _items.fold(0, (sum, it) => sum + it.quantite);
  double get total => _items.fold(0.0, (sum, it) => sum + it.sousTotal);
  bool get estVide => _items.isEmpty;
  String? get vendeurId => _items.isEmpty ? null : _items.first.vendeurId;

  /// Les lignes du panier rangées par boutique, dans l'ordre d'ajout.
  Map<String, List<PanierItem>> get parBoutique {
    final groupes = <String, List<PanierItem>>{};
    for (final it in _items) {
      groupes.putIfAbsent(it.vendeurId, () => []).add(it);
    }
    return groupes;
  }

  // ── Sélection pour la commande ─────────────────────────────────────
  bool estSelectionne(String cle) => _selection.contains(cle);
  List<PanierItem> get selection =>
      _items.where((e) => _selection.contains(e.cle)).toList();
  bool get selectionVide => selection.isEmpty;
  int get nombreSelectionnes => selection.fold(0, (s, it) => s + it.quantite);
  double get totalSelection => selection.fold(0.0, (s, it) => s + it.sousTotal);
  String? get vendeurSelection =>
      selection.isEmpty ? null : selection.first.vendeurId;

  /// Coche ou décoche une ligne. Cocher une ligne d'une autre boutique
  /// remplace la sélection : renvoie `true` dans ce cas, pour que l'écran
  /// l'explique (une commande ne regroupe qu'une boutique).
  bool basculer(String cle) {
    final item = _items.where((e) => e.cle == cle).firstOrNull;
    if (item == null) return false;
    var changement = false;
    if (_selection.contains(cle)) {
      _selection.remove(cle);
    } else {
      final autre = vendeurSelection;
      if (autre != null && autre != item.vendeurId) {
        _selection.clear();
        changement = true;
      }
      _selection.add(cle);
    }
    notifyListeners();
    return changement;
  }

  /// Coche (ou décoche, si elle l'est déjà entièrement) toute une boutique.
  /// Renvoie `true` si une autre boutique était sélectionnée.
  bool basculerBoutique(String vendeur) {
    final lignes = _items.where((e) => e.vendeurId == vendeur).map((e) => e.cle);
    final toutes = lignes.every(_selection.contains);
    var changement = false;
    if (toutes) {
      _selection.removeAll(lignes);
    } else {
      final autre = vendeurSelection;
      if (autre != null && autre != vendeur) {
        _selection.clear();
        changement = true;
      }
      _selection.addAll(lignes);
    }
    notifyListeners();
    return changement;
  }

  bool boutiqueEntierementSelectionnee(String vendeur) {
    final lignes = _items.where((e) => e.vendeurId == vendeur);
    return lignes.isNotEmpty && lignes.every((e) => _selection.contains(e.cle));
  }

  /// Après une commande : retire du panier les lignes commandées, garde le
  /// reste (les autres boutiques, les produits non cochés).
  Future<void> retirerSelection() async {
    _items.removeWhere((e) => _selection.contains(e.cle));
    _selection.clear();
    await _sauvegarder();
  }

  void _charger() {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      _items = list
          .map((e) => PanierItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _items = [];
    }
  }

  Future<void> _sauvegarder() async {
    final raw = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
    notifyListeners();
  }

  /// Ajoute un produit. Si déjà présent, incrémente la quantité.
  Future<void> ajouter(PanierItem item) async {
    final index = _items.indexWhere((e) => e.cle == item.cle);
    if (index >= 0) {
      _items[index].quantite += item.quantite;
    } else {
      _items.add(item);
    }
    await _sauvegarder();
  }

  /// [cle] : `PanierItem.cle` (produit + options choisies).
  Future<void> changerQuantite(String cle, int quantite) async {
    final index = _items.indexWhere((e) => e.cle == cle);
    if (index < 0) return;
    if (quantite <= 0) {
      _selection.remove(_items[index].cle);
      _items.removeAt(index);
    } else {
      _items[index].quantite = quantite;
    }
    await _sauvegarder();
  }

  Future<void> retirer(String cle) async {
    _selection.remove(cle);
    _items.removeWhere((e) => e.cle == cle);
    await _sauvegarder();
  }

  Future<void> vider() async {
    _items = [];
    _selection.clear();
    await prefs.remove(_key);
    notifyListeners();
  }

  /// Les lignes COCHÉES, en payload `items` pour l'API de création de
  /// commande : une seule boutique, au moins un produit.
  List<Map<String, dynamic>> toApiItems() {
    return selection
        .map(
          (e) => {
            'produitId': e.produitId,
            'quantite': e.quantite,
            if (e.options.isNotEmpty) 'options': e.options,
          },
        )
        .toList();
  }
}
