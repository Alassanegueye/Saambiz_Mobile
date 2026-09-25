import '../../domain/entities/paiement.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class PaiementModel extends Paiement {
  const PaiementModel({
    required super.id,
    required super.montant,
    super.methode,
    required super.statut,
    super.date,
    super.transactionId,
  });

  factory PaiementModel.fromJson(Map<String, dynamic> json) {
    return PaiementModel(
      id: json['id']?.toString() ?? '',
      montant: _toDouble(json['montant']),
      methode: json['methode']?.toString(),
      statut: json['statut']?.toString() ?? '',
      date: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null),
      transactionId: json['transactionId']?.toString(),
    );
  }
}
