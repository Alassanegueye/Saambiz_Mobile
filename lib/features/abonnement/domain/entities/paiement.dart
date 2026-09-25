import 'package:equatable/equatable.dart';

class Paiement extends Equatable {
  final String id;
  final double montant;
  final String? methode;
  final String statut;
  final DateTime? date;
  final String? transactionId;

  const Paiement({
    required this.id,
    required this.montant,
    this.methode,
    required this.statut,
    this.date,
    this.transactionId,
  });

  @override
  List<Object?> get props => [id, montant, methode, statut, date, transactionId];
}
