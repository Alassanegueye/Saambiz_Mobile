import 'package:equatable/equatable.dart';

abstract class SignalementsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CreerSignalement extends SignalementsEvent {
  final String type;
  final String raison;
  final String description;
  final String cibleId;

  CreerSignalement({
    required this.type,
    required this.raison,
    required this.description,
    required this.cibleId,
  });

  @override
  List<Object?> get props => [type, raison, description, cibleId];
}

class LoadMesSignalements extends SignalementsEvent {}
