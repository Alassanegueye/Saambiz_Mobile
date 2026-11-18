import 'package:equatable/equatable.dart';

abstract class AbonnementEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAbonnement extends AbonnementEvent {}

class LoadHistoriquePaiements extends AbonnementEvent {
  /// Page demandee : le serveur en rend dix a la fois.
  final int page;
  LoadHistoriquePaiements({this.page = 1});
  @override
  List<Object?> get props => [page];
}

class RenouvelerAbonnement extends AbonnementEvent {
  final num? montant;
  RenouvelerAbonnement({this.montant});
  @override
  List<Object?> get props => [montant];
}

class PayerAbonnement extends AbonnementEvent {
  final num montant;
  final String numeroTelephone;
  final String methode;
  PayerAbonnement({
    required this.montant,
    required this.numeroTelephone,
    required this.methode,
  });
  @override
  List<Object?> get props => [montant, numeroTelephone, methode];
}
