import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/message_model.dart';
import '../../data/repositories/messagerie_repository.dart';
import 'messagerie_event.dart';
import 'messagerie_state.dart';

class MessagerieBloc extends Bloc<MessagerieEvent, MessagerieState> {
  final MessagerieRepository repository;

  MessagerieBloc(this.repository) : super(MessagerieInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadHistorique>(_onLoadHistorique);
    on<EnvoyerMessage>(_onEnvoyer);
    on<MarquerMessageLu>(_onMarquerLu);
    on<LoadNombreNonLus>(_onLoadNonLus);
    on<MessageRecuTempsReel>(_onMessageRecu);
  }

  Future<void> _onLoadConversations(
      LoadConversations event, Emitter<MessagerieState> emit) async {
    emit(MessagerieLoading());
    final result = await repository.conversations();
    result.fold(
      (f) => emit(MessagerieError(f.errorMessage)),
      (list) => emit(ConversationsLoaded(list)),
    );
  }

  Future<void> _onLoadHistorique(
      LoadHistorique event, Emitter<MessagerieState> emit) async {
    emit(MessagerieLoading());
    final result = await repository.historique(event.userId);
    result.fold(
      (f) => emit(MessagerieError(f.errorMessage)),
      (list) => emit(HistoriqueLoaded(event.userId, list)),
    );
  }

  Future<void> _onEnvoyer(EnvoyerMessage event, Emitter<MessagerieState> emit) async {
    final result = await repository.envoyerMessage(
        destinataireId: event.destinataireId, contenu: event.contenu);
    result.fold(
      (f) => emit(MessagerieError(f.errorMessage)),
      (_) => add(LoadHistorique(event.destinataireId)),
    );
  }

  Future<void> _onMarquerLu(
      MarquerMessageLu event, Emitter<MessagerieState> emit) async {
    await repository.marquerLu(event.messageId);
  }

  Future<void> _onLoadNonLus(
      LoadNombreNonLus event, Emitter<MessagerieState> emit) async {
    final result = await repository.nombreNonLus();
    result.fold(
      (f) => emit(MessagerieError(f.errorMessage)),
      (n) => emit(NombreNonLusLoaded(n)),
    );
  }

  void _onMessageRecu(MessageRecuTempsReel event, Emitter<MessagerieState> emit) {
    final current = state;
    if (current is HistoriqueLoaded) {
      try {
        final message = MessageModel.fromJson(event.data);
        if (message.expediteurId == current.userId ||
            message.destinataireId == current.userId) {
          emit(HistoriqueLoaded(current.userId, [...current.messages, message]));
        }
      } catch (_) {
        // Ignore un message temps réel mal formé.
      }
    }
  }
}
