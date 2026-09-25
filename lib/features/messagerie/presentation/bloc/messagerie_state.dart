import 'package:equatable/equatable.dart';

import '../../data/models/message_model.dart';

abstract class MessagerieState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MessagerieInitial extends MessagerieState {}

class MessagerieLoading extends MessagerieState {}

class ConversationsLoaded extends MessagerieState {
  final List<ConversationModel> conversations;
  ConversationsLoaded(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class HistoriqueLoaded extends MessagerieState {
  final String userId;
  final List<MessageModel> messages;
  HistoriqueLoaded(this.userId, this.messages);
  @override
  List<Object?> get props => [userId, messages];
}

class NombreNonLusLoaded extends MessagerieState {
  final int nombre;
  NombreNonLusLoaded(this.nombre);
  @override
  List<Object?> get props => [nombre];
}

class MessagerieError extends MessagerieState {
  final String message;
  MessagerieError(this.message);
  @override
  List<Object?> get props => [message];
}
