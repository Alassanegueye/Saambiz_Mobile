import 'package:equatable/equatable.dart';

import '../../../../core/services/comptes_memorises.dart';
import '../../data/datasources/connexion_sociale_source.dart';
import '../../domain/entities/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String? email;
  final String? telephone;
  final String mot_de_passe;

  const LoginRequested({
    this.email,
    this.telephone,
    required this.mot_de_passe,
  });

  @override
  List<Object?> get props => [email, telephone, mot_de_passe];
}

/// « Continuer avec Google / Apple ».
class ConnexionSocialeDemandee extends AuthEvent {
  final FournisseurSocial fournisseur;

  const ConnexionSocialeDemandee(this.fournisseur);

  @override
  List<Object?> get props => [fournisseur];
}

/// Toucher un compte mémorisé sur l'écran de connexion.
class RepriseCompteDemandee extends AuthEvent {
  final CompteMemorise compte;

  const RepriseCompteDemandee(this.compte);

  @override
  List<Object?> get props => [compte.id];
}

/// « Changer de compte » : on quitte ce compte SANS fermer sa session, pour
/// pouvoir y revenir d'un toucher depuis l'écran de connexion.
class ChangementDeCompteDemande extends AuthEvent {
  /// Compte quitté : mémorisé (avec sa session) s'il ne l'était pas encore,
  /// par exemple connecté avant l'arrivée du choix de compte.
  final User? compteQuitte;

  const ChangementDeCompteDemande({this.compteQuitte});

  @override
  List<Object?> get props => [compteQuitte?.id];
}

/// « Se déconnecter » : on quitte le compte, mais sa session reste mémorisée
/// sur le téléphone. Le toucher sur l'écran de connexion le rouvre sans mot
/// de passe ; seul « Retirer ce compte » la ferme vraiment.
class LogoutRequested extends AuthEvent {
  final User? compteQuitte;

  /// Compte supprimé : il n'est plus proposé sur l'écran de connexion.
  final bool compteSupprime;

  const LogoutRequested({this.compteQuitte, this.compteSupprime = false});

  @override
  List<Object?> get props => [compteQuitte?.id, compteSupprime];
}

class ResetAuthState extends AuthEvent {}
