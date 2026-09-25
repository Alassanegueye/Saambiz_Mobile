import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/panier_item.dart';

/// Service de gestion du panier local (persisté via SharedPreferences).
///
/// Règle métier alignée sur le backend : **un panier ne contient les produits
/// que d'UN SEUL vendeur**. Tenter d'ajouter un produit d'un autre vendeur
/// lève [PanierVendeurDifferentException].
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

  PanierService({required this.prefs}) {
    _charger();
  }

  List<PanierItem> get items => List.unmodifiable(_items);
  int get nombreArticles => _items.fold(0, (sum, it) => sum + it.quantite);
  double get total => _items.fold(0.0, (sum, it) => sum + it.sousTotal);
  bool get estVide => _items.isEmpty;
  String? get vendeurId => _items.isEmpty ? null : _items.first.vendeurId;

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
    if (_items.isNotEmpty && _items.first.vendeurId != item.vendeurId) {
      throw PanierVendeurDifferentException();
    }
    final index = _items.indexWhere((e) => e.produitId == item.produitId);
    if (index >= 0) {
      _items[index].quantite += item.quantite;
    } else {
      _items.add(item);
    }
    await _sauvegarder();
  }

  Future<void> changerQuantite(String produitId, int quantite) async {
    final index = _items.indexWhere((e) => e.produitId == produitId);
    if (index < 0) return;
    if (quantite <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantite = quantite;
    }
    await _sauvegarder();
  }

  Future<void> retirer(String produitId) async {
    _items.removeWhere((e) => e.produitId == produitId);
    await _sauvegarder();
  }

  Future<void> vider() async {
    _items = [];
    await prefs.remove(_key);
    notifyListeners();
  }

  /// Transforme le panier en payload `items` pour l'API de création de commande.
  List<Map<String, dynamic>> toApiItems() {
    return _items
        .map((e) => {'produitId': e.produitId, 'quantite': e.quantite})
        .toList();
  }
}
