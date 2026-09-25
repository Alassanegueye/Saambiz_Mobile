import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/commande_repository.dart';
import 'commande_event.dart';
import 'commande_state.dart';

class CommandeBloc extends Bloc<CommandeEvent, CommandeState> {
  final CommandeRepository repository;

  CommandeBloc(this.repository) : super(CommandeInitial()) {
    on<LoadMesCommandes>(_onLoadMesCommandes);
    on<LoadCommandesVendeur>(_onLoadCommandesVendeur);
    on<CreerCommande>(_onCreerCommande);
    on<PayerCommande>(_onPayerCommande);
    on<AnnulerCommande>(_onAnnulerCommande);
    on<ChangerStatutCommande>(_onChangerStatut);
    on<DemanderRetourCommande>(_onDemanderRetour);
  }

  // Extrait un message d'erreur lisible (priorité au message du backend)
  String _msg(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Erreur réseau';
    }
    return e.toString();
  }

  Future<void> _onLoadMesCommandes(
      LoadMesCommandes event, Emitter<CommandeState> emit) async {
    emit(CommandeLoading());
    try {
      final list = await repository.mesCommandes(statut: event.statut);
      emit(CommandesLoaded(list));
    } catch (e) {
      emit(CommandeError(_msg(e)));
    }
  }

  Future<void> _onLoadCommandesVendeur(
      LoadCommandesVendeur event, Emitter<CommandeState> emit) async {
    emit(CommandeLoading());
    try {
      final list = await repository.commandesVendeur(statut: event.statut);
      emit(CommandesLoaded(list));
    } catch (e) {
      emit(CommandeError(_msg(e)));
    }
  }

  Future<void> _onCreerCommande(
      CreerCommande event, Emitter<CommandeState> emit) async {
    emit(CommandeLoading());
    try {
      final commande = await repository.creerCommande(
        items: event.items,
        modeLivraison: event.modeLivraison,
        modePaiement: event.modePaiement,
        adresseLivraison: event.adresseLivraison,
        numeroTelephone: event.numeroTelephone,
        note: event.note,
      );
      emit(CommandeCreee(commande));
    } catch (e) {
      emit(CommandeError(_msg(e)));
    }
  }

  Future<void> _onPayerCommande(
      PayerCommande event, Emitter<CommandeState> emit) async {
    emit(CommandeLoading());
    try {
      final url = await repository.payer(
        event.commandeId,
        methode: event.methode,
        numeroTelephone: event.numeroTelephone,
      );
      emit(PaiementInitie(event.commandeId, url));
    } catch (e) {
      emit(CommandeError(_msg(e)));
    }
  }

  Future<void> _onAnnulerCommande(
      AnnulerCommande event, Emitter<CommandeState> emit) async {
    emit(CommandeLoading());
    try {
      final commande = await repository.annuler(event.commandeId);
      emit(CommandeMiseAJour(commande));
    } catch (e) {
      emit(CommandeError(_msg(e)));
    }
  }

  Future<void> _onChangerStatut(
      ChangerStatutCommande event, Emitter<CommandeState> emit) async {
    emit(CommandeLoading());
    try {
      final commande = await repository.changerStatut(event.commandeId, event.statut);
      emit(CommandeMiseAJour(commande));
    } catch (e) {
      emit(CommandeError(_msg(e)));
    }
  }

  Future<void> _onDemanderRetour(
      DemanderRetourCommande event, Emitter<CommandeState> emit) async {
    emit(CommandeLoading());
    try {
      await repository.demandeRetour(event.commandeId, raison: event.raison);
      emit(RetourDemande(event.commandeId));
    } catch (e) {
      emit(CommandeError(_msg(e)));
    }
  }
}
