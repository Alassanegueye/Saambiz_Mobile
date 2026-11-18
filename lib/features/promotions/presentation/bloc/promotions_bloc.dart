import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/promotions_remote_datasource.dart';
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
    LoadPromotionsActives event,
    Emitter<PromotionsState> emit,
  ) async {
    emit(PromotionsLoading());
    final result = await repository.promotionsActives();
    result.fold(
      (f) => emit(PromotionsError(f.errorMessage)),
      (list) => emit(PromotionsLoaded(list)),
    );
  }

  /// Page affichée, conservée entre deux rechargements : supprimer une
  /// promotion ne doit pas renvoyer en page un.
  int _page = 1;

  Future<void> _onLoadMes(
    LoadMesPromotions event,
    Emitter<PromotionsState> emit,
  ) async {
    if (event.page != null) _page = event.page!;
    emit(PromotionsLoading());
    var result = await repository.mesPromotions(page: _page);

    // Supprimer le dernier élément d'une page la vide. Sans ce rattrapage,
    // l'écran afficherait « aucune promotion » sur la page trois alors qu'il
    // en reste vingt, sans aucun moyen de revenir en arrière.
    //
    // Uniquement sur une réponse reçue : en cas d'erreur réseau, la liste est
    // vide elle aussi, et relancer la requête masquerait le message.
    final page = result.fold<PagePromotions?>((_) => null, (p) => p);
    if (page != null && page.promotions.isEmpty && _page > 1) {
      _page = page.pagination.pages;
      result = await repository.mesPromotions(page: _page);
    }

    result.fold(
      (f) => emit(PromotionsError(f.errorMessage)),
      (recue) => emit(
        PromotionsLoaded(recue.promotions, pagination: recue.pagination),
      ),
    );
  }

  Future<void> _onCreer(
    CreerPromotion event,
    Emitter<PromotionsState> emit,
  ) async {
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
    ModifierPromotion event,
    Emitter<PromotionsState> emit,
  ) async {
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
    SupprimerPromotion event,
    Emitter<PromotionsState> emit,
  ) async {
    final result = await repository.supprimerPromotion(event.id);
    result.fold((f) => emit(PromotionsError(f.errorMessage)), (_) {
      emit(PromotionActionSucces('Promotion supprimée avec succès'));
      add(LoadMesPromotions());
    });
  }
}
