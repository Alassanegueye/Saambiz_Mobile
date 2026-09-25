import 'package:equatable/equatable.dart';

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

class LogoutRequested extends AuthEvent {}

class ResetAuthState extends AuthEvent {}
