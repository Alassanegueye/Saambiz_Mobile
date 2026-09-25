import '../../domain/entities/abonnement.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class AbonnementModel extends Abonnement {
  const AbonnementModel({
    required super.id,
    required super.type,
    required super.dateDebut,
    required super.dateFin,
    required super.statut,
    required super.montant,
  });

  factory AbonnementModel.fromJson(Map<String, dynamic> json) {
    final data = (json['abonnement'] ?? json) as Map<String, dynamic>;
    return AbonnementModel(
      id: data['id']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      dateDebut: data['dateDebut'] != null
          ? DateTime.tryParse(data['dateDebut'].toString())
          : null,
      dateFin: data['dateFin'] != null
          ? DateTime.tryParse(data['dateFin'].toString())
          : null,
      statut: data['statut']?.toString() ?? '',
      montant: _toDouble(data['montant']),
    );
  }
}
