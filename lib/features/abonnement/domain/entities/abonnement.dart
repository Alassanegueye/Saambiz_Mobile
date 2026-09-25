import 'package:equatable/equatable.dart';

class Abonnement extends Equatable {
  final String id;
  final String type;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String statut;
  final double montant;

  const Abonnement({
    required this.id,
    required this.type,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
    required this.montant,
  });

  @override
  List<Object?> get props => [id, type, dateDebut, dateFin, statut, montant];
}
