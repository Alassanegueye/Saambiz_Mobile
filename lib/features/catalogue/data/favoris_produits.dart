import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../injection_container.dart';
import 'produit_catalogue.dart';

/// Produits aimés (cœur des cartes produits), gardés sur le téléphone.
///
/// On garde de quoi réafficher la carte sans appel réseau (nom, prix,
/// image, boutique) ; la fiche produit recharge le reste à l'ouverture.
class FavorisProduits {
  FavorisProduits._();

  static const _cle = 'saambiz.favoris.produits';
  static const _maximum = 200;

  /// La liste, du plus récent au plus ancien. Les écrans s'y abonnent.
  static final ValueNotifier<List<Map<String, dynamic>>> liste =
      ValueNotifier<List<Map<String, dynamic>>>(_lire());

  static List<Map<String, dynamic>> _lire() {
    try {
      final brut = sl<SharedPreferences>().getString(_cle);
      if (brut == null || brut.isEmpty) return const [];
      return (jsonDecode(brut) as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static bool contient(String produitId) => liste.value.any((p) => p['id'] == produitId);

  static List<ProduitCatalogue> get produits =>
      liste.value.map(ProduitCatalogue.fromJson).toList();

  /// Ajoute ou retire [p] ; rend vrai si le produit est désormais aimé.
  static Future<bool> basculer(ProduitCatalogue p) async {
    final actuelle = List<Map<String, dynamic>>.from(liste.value);
    final deja = actuelle.indexWhere((e) => e['id'] == p.id);
    if (deja >= 0) {
      actuelle.removeAt(deja);
    } else {
      actuelle.insert(0, {
        'id': p.id,
        'nom': p.nom,
        'prix': p.prix,
        if (p.prixPromo != null) 'prixPromo': p.prixPromo,
        'remise': p.remise,
        'image': p.image,
        'vendeurId': p.vendeurId,
        'disponible': p.disponible,
        'enRupture': p.enRupture,
        if (p.boutique != null)
          'boutique': {
            'id': p.boutique!.id,
            'nom': p.boutique!.nom,
            if (p.boutique!.logo != null) 'logo': p.boutique!.logo,
          },
      });
    }
    final nouvelle = actuelle.take(_maximum).toList();
    liste.value = nouvelle;
    try {
      await sl<SharedPreferences>().setString(_cle, jsonEncode(nouvelle));
    } catch (_) {/* le cœur reste juste pour cette session */}
    return deja < 0;
  }
}
