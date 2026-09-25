import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/signalements_repository.dart';
import 'signalements_event.dart';
import 'signalements_state.dart';

class SignalementsBloc extends Bloc<SignalementsEvent, SignalementsState> {
  final SignalementsRepository repository;

  SignalementsBloc(this.repository) : super(SignalementsInitial()) {
    on<CreerSignalement>(_onCreer);
    on<LoadMesSignalements>(_onLoad);
  }

  Future<void> _onCreer(
      CreerSignalement event, Emitter<SignalementsState> emit) async {
    emit(SignalementsLoading());
    final result = await repository.creerSignalement(
      type: event.type,
      raison: event.raison,
      description: event.description,
      cibleId: event.cibleId,
    );
    result.fold(
      (f) => emit(SignalementsError(f.errorMessage)),
      (_) => emit(SignalementEnvoye()),
    );
  }

  Future<void> _onLoad(
      LoadMesSignalements event, Emitter<SignalementsState> emit) async {
    emit(SignalementsLoading());
    final result = await repository.mesSignalements();
    result.fold(
      (f) => emit(SignalementsError(f.errorMessage)),
      (list) => emit(SignalementsLoaded(list)),
    );
  }
}
