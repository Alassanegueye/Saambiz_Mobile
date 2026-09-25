import 'package:equatable/equatable.dart';

abstract class MessagerieEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadConversations extends MessagerieEvent {}

class LoadHistorique extends MessagerieEvent {
  final String userId;
  LoadHistorique(this.userId);
  @override
  List<Object?> get props => [userId];
}

class EnvoyerMessage extends MessagerieEvent {
  final String destinataireId;
  final String contenu;
  EnvoyerMessage({required this.destinataireId, required this.contenu});
  @override
  List<Object?> get props => [destinataireId, contenu];
}

class MarquerMessageLu extends MessagerieEvent {
  final String messageId;
  MarquerMessageLu(this.messageId);
  @override
  List<Object?> get props => [messageId];
}

class LoadNombreNonLus extends MessagerieEvent {}

/// Message reçu en temps réel via le socket (événement `message:new`).
class MessageRecuTempsReel extends MessagerieEvent {
  final Map<String, dynamic> data;
  MessageRecuTempsReel(this.data);
  @override
  List<Object?> get props => [data];
}
