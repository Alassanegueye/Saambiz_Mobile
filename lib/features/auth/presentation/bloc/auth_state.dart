import 'package:equatable/equatable.dart';
import '../../../../core/services/comptes_memorises.dart';
import '../../data/datasources/connexion_sociale_source.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

/// Connexion Google / Apple en cours (fenêtre du fournisseur, puis serveur).
class AuthSocialEnCours extends AuthLoading {
  final FournisseurSocial fournisseur;

  AuthSocialEnCours(this.fournisseur);

  @override
  List<Object?> get props => [fournisseur];
}

class AuthSuccess extends AuthState {
  final User user;

  const AuthSuccess({required this.user});

  @override
  List<Object?> get props => [user]; // ← token ajouté
}

/// Retour sur un compte mémorisé en cours.
class AuthRepriseEnCours extends AuthLoading {
  final String idCompte;

  AuthRepriseEnCours(this.idCompte);

  @override
  List<Object?> get props => [idCompte];
}

/// La session de ce compte n'est plus ouverte : il faut son mot de passe (ou
/// Google / Apple). Le formulaire s'ouvre, pré-rempli.
class AuthCompteAReconnecter extends AuthState {
  final CompteMemorise compte;
  final String? message;

  const AuthCompteAReconnecter(this.compte, {this.message});

  @override
  List<Object?> get props => [compte.id, message];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Connexion pas encore proposée (Google non configuré) : message
/// d'information, pas d'erreur.
class AuthConnexionIndisponible extends AuthFailure {
  const AuthConnexionIndisponible({required super.message});
}
