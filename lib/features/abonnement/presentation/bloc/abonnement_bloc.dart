import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_historique_paiements.dart';
import '../../domain/usecases/get_mon_abonnement.dart';
import '../../domain/usecases/initier_renouvellement.dart';
import '../../domain/usecases/payer.dart';
import 'abonnement_event.dart';
import 'abonnement_state.dart';

class AbonnementBloc extends Bloc<AbonnementEvent, AbonnementState> {
  final GetMonAbonnement getMonAbonnement;
  final InitierRenouvellement initierRenouvellement;
  final GetHistoriquePaiements getHistoriquePaiements;
  final Payer payer;

  AbonnementBloc({
    required this.getMonAbonnement,
    required this.initierRenouvellement,
    required this.getHistoriquePaiements,
    required this.payer,
  }) : super(AbonnementInitial()) {
    on<LoadAbonnement>(_onLoad);
    on<LoadHistoriquePaiements>(_onLoadHistorique);
    on<RenouvelerAbonnement>(_onRenouveler);
    on<PayerAbonnement>(_onPayer);
  }

  Future<void> _onLoad(LoadAbonnement event, Emitter<AbonnementState> emit) async {
    emit(AbonnementLoading());
    final result = await getMonAbonnement();
    result.fold(
      (f) => emit(AbonnementError(f.errorMessage)),
      (a) => emit(AbonnementLoaded(a)),
    );
  }

  Future<void> _onLoadHistorique(
      LoadHistoriquePaiements event, Emitter<AbonnementState> emit) async {
    emit(AbonnementLoading());
    final result = await getHistoriquePaiements();
    result.fold(
      (f) => emit(AbonnementError(f.errorMessage)),
      (p) => emit(HistoriquePaiementsLoaded(p)),
    );
  }

  Future<void> _onRenouveler(
      RenouvelerAbonnement event, Emitter<AbonnementState> emit) async {
    emit(AbonnementLoading());
    final result = await initierRenouvellement(montant: event.montant);
    result.fold(
      (f) => emit(AbonnementError(f.errorMessage)),
      (id) => emit(RenouvellementInitie(id)),
    );
  }

  Future<void> _onPayer(
      PayerAbonnement event, Emitter<AbonnementState> emit) async {
    emit(AbonnementLoading());
    final result = await payer(
      montant: event.montant,
      numeroTelephone: event.numeroTelephone,
      methode: event.methode,
    );
    result.fold(
      (f) => emit(AbonnementError(f.errorMessage)),
      (r) => emit(PaiementInitieAbonnement(
          paymentUrl: r.paymentUrl, transactionId: r.transactionId)),
    );
  }
}
