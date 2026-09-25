import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user.dart';

abstract class CompteState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CompteInitial extends CompteState {}

class CompteLoading extends CompteState {}

class CompteLoaded extends CompteState {
  final User user;
  CompteLoaded(this.user);
  @override
  List<Object?> get props => [user];
}

class CompteActionEnCours extends CompteState {
  final User user;
  CompteActionEnCours(this.user);
  @override
  List<Object?> get props => [user];
}

class CompteActionSucces extends CompteState {
  final User user;
  final String message;
  CompteActionSucces(this.user, this.message);
  @override
  List<Object?> get props => [user, message];
}

/// Succès d'une action ne renvoyant pas de profil (mdp oublié / réinitialisé)
class CompteMessageSucces extends CompteState {
  final String message;
  CompteMessageSucces(this.message);
  @override
  List<Object?> get props => [message];
}

class CompteError extends CompteState {
  final String message;
  CompteError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Compte supprimé avec succès : l'UI doit forcer la déconnexion et
/// rediriger vers l'écran de connexion.
class CompteAccountDeleted extends CompteState {}
