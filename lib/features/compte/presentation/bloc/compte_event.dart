import 'package:equatable/equatable.dart';

abstract class CompteEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCompte extends CompteEvent {}

class ModifierProfilRequested extends CompteEvent {
  final String? nom;
  final String? prenom;
  final String? adresse;
  final String? telephone;
  final String? photoProfilPath;

  ModifierProfilRequested({
    this.nom,
    this.prenom,
    this.adresse,
    this.telephone,
    this.photoProfilPath,
  });

  @override
  List<Object?> get props => [nom, prenom, adresse, telephone, photoProfilPath];
}

class ChangePasswordRequested extends CompteEvent {
  final String ancienMotDePasse;
  final String nouveauMotDePasse;

  ChangePasswordRequested({
    required this.ancienMotDePasse,
    required this.nouveauMotDePasse,
  });

  @override
  List<Object?> get props => [ancienMotDePasse, nouveauMotDePasse];
}

class ForgotPasswordRequested extends CompteEvent {
  final String email;
  ForgotPasswordRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class ResetPasswordRequested extends CompteEvent {
  final String email;
  final String code;
  final String nouveauMotDePasse;

  ResetPasswordRequested({
    required this.email,
    required this.code,
    required this.nouveauMotDePasse,
  });

  @override
  List<Object?> get props => [email, code, nouveauMotDePasse];
}

class DeleteAccountRequested extends CompteEvent {
  final String? motif;
  DeleteAccountRequested({this.motif});
  @override
  List<Object?> get props => [motif];
}
