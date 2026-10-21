// Modèles de données pour les commandes (miroir du backend /saambiz/commandes)

class LigneCommandeModel {
  final String id;
  final String? produitId;
  final String nomProduit;
  final String? imageProduit;
  final double prixUnitaire;
  final int quantite;
  final double sousTotal;

  /// Options choisies par le client (taille, parfum…).
  final Map<String, String> options;

  LigneCommandeModel({
    required this.id,
    required this.produitId,
    required this.nomProduit,
    required this.imageProduit,
    required this.prixUnitaire,
    required this.quantite,
    required this.sousTotal,
    this.options = const {},
  });

  String get libelleOptions =>
      options.entries.map((e) => '${e.key} : ${e.value}').join(' · ');

  factory LigneCommandeModel.fromJson(Map<String, dynamic> json) {
    return LigneCommandeModel(
      id: json['id']?.toString() ?? '',
      produitId: json['produitId']?.toString(),
      nomProduit: json['nomProduit'] ?? '',
      imageProduit: json['imageProduit'],
      prixUnitaire: _toDouble(json['prixUnitaire']),
      quantite: (json['quantite'] ?? 0) is int
          ? json['quantite']
          : int.tryParse('${json['quantite']}') ?? 0,
      sousTotal: _toDouble(json['sousTotal']),
      options: json['options'] is Map
          ? (json['options'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
    );
  }
}

class CommandeModel {
  final String id;
  final String referenceCommande;
  final String acheteurId;
  final String vendeurId;
  final double montantProduits;
  final double fraisLivraison;
  final double montantTotal;
  final String statut;
  final String statutPaiement;
  final String modeLivraison;
  final String modePaiement;
  final String? adresseLivraison;
  final String? numeroTelephone;
  final String? note;
  final DateTime? createdAt;
  final List<LigneCommandeModel> lignes;

  // Infos de l'autre partie (selon le point de vue)
  final String? acheteurNom;
  final String? acheteurTelephone;
  final String? vendeurNom;
  final String? vendeurTelephone;

  CommandeModel({
    required this.id,
    required this.referenceCommande,
    required this.acheteurId,
    required this.vendeurId,
    required this.montantProduits,
    required this.fraisLivraison,
    required this.montantTotal,
    required this.statut,
    required this.statutPaiement,
    required this.modeLivraison,
    required this.modePaiement,
    required this.adresseLivraison,
    required this.numeroTelephone,
    required this.note,
    required this.createdAt,
    required this.lignes,
    this.acheteurNom,
    this.acheteurTelephone,
    this.vendeurNom,
    this.vendeurTelephone,
  });

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    final lignesRaw = json['lignes'];
    final lignes = (lignesRaw is List)
        ? lignesRaw
            .map((e) => LigneCommandeModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <LigneCommandeModel>[];

    String? joinNom(Map<String, dynamic>? p) {
      if (p == null) return null;
      return '${p['prenom'] ?? ''} ${p['nom'] ?? ''}'.trim();
    }

    final acheteur = json['acheteur'] as Map<String, dynamic>?;
    final vendeur = json['vendeur'] as Map<String, dynamic>?;

    return CommandeModel(
      id: json['id']?.toString() ?? '',
      referenceCommande: json['referenceCommande'] ?? '',
      acheteurId: json['acheteurId']?.toString() ?? '',
      vendeurId: json['vendeurId']?.toString() ?? '',
      montantProduits: _toDouble(json['montantProduits']),
      fraisLivraison: _toDouble(json['fraisLivraison']),
      montantTotal: _toDouble(json['montantTotal']),
      statut: json['statut'] ?? 'en_attente',
      statutPaiement: json['statutPaiement'] ?? 'non_paye',
      modeLivraison: json['modeLivraison'] ?? 'livraison',
      modePaiement: json['modePaiement'] ?? 'en_ligne',
      adresseLivraison: json['adresseLivraison'],
      numeroTelephone: json['numeroTelephone'],
      note: json['note'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      lignes: lignes,
      acheteurNom: joinNom(acheteur),
      acheteurTelephone: acheteur?['telephone'],
      vendeurNom: joinNom(vendeur),
      vendeurTelephone: vendeur?['telephone'],
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

// Libellés FR + ordre des statuts pour l'affichage du suivi
const Map<String, String> kStatutCommandeLabels = {
  'en_attente': 'En attente',
  'confirmee': 'Confirmée',
  'en_preparation': 'En préparation',
  'prete': 'Prête',
  'en_livraison': 'En livraison',
  'livree': 'Livrée',
  'annulee': 'Annulée',
};
