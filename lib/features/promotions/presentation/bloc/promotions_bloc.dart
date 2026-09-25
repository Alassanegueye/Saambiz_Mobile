import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/promotions_repository.dart';
import 'promotions_event.dart';
import 'promotions_state.dart';

class PromotionsBloc extends Bloc<PromotionsEvent, PromotionsState> {
  final PromotionsRepository repository;

  PromotionsBloc(this.repository) : super(PromotionsInitial()) {
    on<LoadPromotionsActives>(_onLoadActives);
    on<LoadMesPromotions>(_onLoadMes);
    on<CreerPromotion>(_onCreer);
    on<ModifierPromotion>(_onModifier);
    on<SupprimerPromotion>(_onSupprimer);
  }

  Future<void> _onLoadActives(
      LoadPromotionsActives event, Emitter<PromotionsState> emit) async {
    emit(PromotionsLoading());
    final result = await repository.promotionsActives();
    result.fold(
      (f) => emit(PromotionsError(f.errorMessage)),
      (list) => emit(PromotionsLoaded(list)),
    );
  }

  Future<void> _onLoadMes(
      LoadMesPromotions event, Emitter<PromotionsState> emit) async {
    emit(PromotionsLoading());
    final result = await repository.mesPromotions();
    result.fold(
      (f) => emit(PromotionsError(f.errorMessage)),
      (list) => emit(PromotionsLoaded(list)),
    );
  }

  Future<void> _onCreer(CreerPromotion event, Emitter<PromotionsState> emit) async {
    emit(PromotionsLoading());
    final result = await repository.creerPromotion(
      titre: event.titre,
      description: event.description,
      prixPromo: event.prixPromo,
      dateDebut: event.dateDebut,
      dateFin: event.dateFin,
      produitId: event.produitId,
    );
    result.fold(
      (f) => emit(PromotionsError(f.errorMessage)),
      (_) => add(LoadMesPromotions()),
    );
  }

  Future<void> _onModifier(
      ModifierPromotion event, Emitter<PromotionsState> emit) async {
    emit(PromotionsLoading());
    final result = await repository.modifierPromotion(
      event.id,
      titre: event.titre,
      description: event.description,
      prixPromo: event.prixPromo,
      dateDebut: event.dateDebut,
      dateFin: event.dateFin,
    );
    result.fold(
      (f) => emit(PromotionsError(f.errorMessage)),
      (_) => add(LoadMesPromotions()),
    );
  }

  Future<void> _onSupprimer(
      SupprimerPromotion event, Emitter<PromotionsState> emit) async {
    final result = await repository.supprimerPromotion(event.id);
    result.fold(
      (f) => emit(PromotionsError(f.errorMessage)),
      (_) => add(LoadMesPromotions()),
    );
  }
}
