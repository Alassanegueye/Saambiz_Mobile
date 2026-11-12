import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/usecases/creer_boutique.dart';
import '../../domain/usecases/get_ma_boutique.dart';
import '../../domain/usecases/modifier_boutique.dart';
import '../../domain/usecases/pause_boutique.dart';
import '../../domain/usecases/reactiver_boutique.dart';
import 'boutique_event.dart';
import 'boutique_state.dart';

class BoutiqueBloc extends Bloc<BoutiqueEvent, BoutiqueState> {
  final GetMaBoutique getMaBoutique;
  final CreerBoutique creerBoutique;
  final ModifierBoutique modifierBoutique;
  final PauseBoutique pauseBoutique;
  final ReactiverBoutique reactiverBoutique;

  BoutiqueBloc({
    required this.getMaBoutique,
    required this.creerBoutique,
    required this.modifierBoutique,
    required this.pauseBoutique,
    required this.reactiverBoutique,
  }) : super(BoutiqueInitial()) {
    on<LoadMaBoutique>(_onLoad);
    on<CreerBoutiqueRequested>(_onCreer);
    on<ModifierBoutiqueRequested>(_onModifier);
    on<PauseBoutiqueRequested>(_onPause);
    on<ReactiverBoutiqueRequested>(_onReactiver);
  }

  void _emitFailure(Failure failure, Emitter<BoutiqueState> emit) {
    if (failure is ServerFailure && failure.statusCode == 404) {
      emit(BoutiqueInexistante());
    } else {
      emit(BoutiqueError(failure.errorMessage));
    }
  }

  Future<void> _onLoad(
    LoadMaBoutique event,
    Emitter<BoutiqueState> emit,
  ) async {
    emit(BoutiqueLoading());
    final result = await getMaBoutique();
    result.fold((f) => _emitFailure(f, emit), (b) => emit(BoutiqueLoaded(b)));
  }

  Future<void> _onCreer(
    CreerBoutiqueRequested event,
    Emitter<BoutiqueState> emit,
  ) async {
    emit(BoutiqueLoading());
    final result = await creerBoutique(
      nom: event.nom,
      description: event.description,
      localisation: event.localisation,
      telephone: event.telephone,
      categories: event.categories,
      logoPath: event.logoPath,
    );
    result.fold((f) => _emitFailure(f, emit), (b) => emit(BoutiqueLoaded(b)));
  }

  Future<void> _onModifier(
    ModifierBoutiqueRequested event,
    Emitter<BoutiqueState> emit,
  ) async {
    emit(BoutiqueLoading());
    final result = await modifierBoutique(
      nom: event.nom,
      description: event.description,
      localisation: event.localisation,
      telephone: event.telephone,
      categories: event.categories,
      logoPath: event.logoPath,
    );
    result.fold((f) => _emitFailure(f, emit), (b) => emit(BoutiqueLoaded(b)));
  }

  Future<void> _onPause(
    PauseBoutiqueRequested event,
    Emitter<BoutiqueState> emit,
  ) async {
    final result = await pauseBoutique();
    await result.fold(
      (f) async => _emitFailure(f, emit),
      (_) => _recharger(emit, 'Boutique mise en pause'),
    );
  }

  Future<void> _onReactiver(
    ReactiverBoutiqueRequested event,
    Emitter<BoutiqueState> emit,
  ) async {
    final result = await reactiverBoutique();
    await result.fold(
      (f) async => _emitFailure(f, emit),
      (_) => _recharger(emit, 'Votre boutique est de nouveau ouverte'),
    );
  }

  /// Relit la boutique sans repasser par l'écran de chargement, et joint
  /// le message de confirmation.
  Future<void> _recharger(Emitter<BoutiqueState> emit, String succes) async {
    final result = await getMaBoutique();
    result.fold(
      (f) => _emitFailure(f, emit),
      (b) => emit(BoutiqueLoaded(b, succes: succes)),
    );
  }
}
