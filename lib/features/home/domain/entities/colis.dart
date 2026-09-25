import 'personne.dart';

class Colis {
  final String id;
  final String reference;
  final Personne? expediteur;
  final Personne? recepteur;
  final double poids;
  final double prix;
  final String destination;
  final String statut;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Colis({
    required this.id,
    required this.reference,
    this.expediteur,
    this.recepteur,
    required this.poids,
    required this.prix,
    required this.destination,
    required this.statut,
    required this.createdAt,
    this.updatedAt,
  });

  factory Colis.fromJson(Map<String, dynamic> json) {
    return Colis(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] ?? '',
      expediteur: json['expediteur'] != null
          ? Personne.fromJson(json['expediteur'])
          : null,
      recepteur: json['recepteur'] != null
          ? Personne.fromJson(json['recepteur'])
          : null,
      poids: (json['poids'] as num?)?.toDouble() ?? 0.0,
      prix: (json['prix'] as num?)?.toDouble() ?? 0.0,
      destination: json['destination'] ?? '',
      statut: json['statut'] ?? 'inconnu',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}