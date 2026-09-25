class SignalementModel {
  final String id;
  final String type; // 'produit' | 'boutique'
  final String raison;
  final String description;
  final String cibleId;
  final String statut;
  final DateTime? createdAt;

  SignalementModel({
    required this.id,
    required this.type,
    required this.raison,
    required this.description,
    required this.cibleId,
    required this.statut,
    this.createdAt,
  });

  factory SignalementModel.fromJson(Map<String, dynamic> json) {
    return SignalementModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      raison: json['raison']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      cibleId: json['cibleId']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'en_attente',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
