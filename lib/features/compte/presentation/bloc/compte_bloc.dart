import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user.dart';
import '../../domain/usecases/change_password.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/forgot_password.dart';
import '../../domain/usecases/get_me.dart';
import '../../domain/usecases/modifier_profil.dart';
import '../../domain/usecases/reset_password.dart';
import 'compte_event.dart';
import 'compte_state.dart';

class CompteBloc extends Bloc<CompteEvent, CompteState> {
  final GetMe getMe;
  final ModifierProfil modifierProfil;
  final ChangePassword changePassword;
  final ForgotPassword forgotPassword;
  final ResetPassword resetPassword;
  final DeleteAccount deleteAccount;

  User? _current;

  CompteBloc({
    required this.getMe,
    required this.modifierProfil,
    required this.changePassword,
    required this.forgotPassword,
    required this.resetPassword,
    required this.deleteAccount,
  }) : super(CompteInitial()) {
    on<LoadCompte>(_onLoad);
    on<ModifierProfilRequested>(_onModifierProfil);
    on<ChangePasswordRequested>(_onChangePassword);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<ResetPasswordRequested>(_onResetPassword);
    on<DeleteAccountRequested>(_onDeleteAccount);
  }

  Future<void> _onLoad(LoadCompte event, Emitter<CompteState> emit) async {
    emit(CompteLoading());
    final result = await getMe();
    result.fold(
      (failure) => emit(CompteError(failure.errorMessage)),
      (user) {
        _current = user;
        emit(CompteLoaded(user));
      },
    );
  }

  Future<void> _onModifierProfil(
      ModifierProfilRequested event, Emitter<CompteState> emit) async {
    if (_current != null) emit(CompteActionEnCours(_current!));
    final result = await modifierProfil(
      nom: event.nom,
      prenom: event.prenom,
      adresse: event.adresse,
      telephone: event.telephone,
      photoProfilPath: event.photoProfilPath,
    );
    result.fold(
      (failure) => emit(CompteError(failure.errorMessage)),
      (user) {
        _current = user;
        emit(CompteActionSucces(user, 'Profil mis à jour'));
      },
    );
  }

  Future<void> _onChangePassword(
      ChangePasswordRequested event, Emitter<CompteState> emit) async {
    if (_current != null) emit(CompteActionEnCours(_current!));
    final result = await changePassword(
      ancienMotDePasse: event.ancienMotDePasse,
      nouveauMotDePasse: event.nouveauMotDePasse,
    );
    result.fold(
      (failure) => emit(CompteError(failure.errorMessage)),
      (_) {
        if (_current != null) {
          emit(CompteActionSucces(_current!, 'Mot de passe modifié'));
        } else {
          emit(CompteMessageSucces('Mot de passe modifié'));
        }
      },
    );
  }

  Future<void> _onForgotPassword(
      ForgotPasswordRequested event, Emitter<CompteState> emit) async {
    emit(CompteLoading());
    final result = await forgotPassword(event.email);
    result.fold(
      (failure) => emit(CompteError(failure.errorMessage)),
      (_) => emit(CompteMessageSucces('Un code de réinitialisation a été envoyé')),
    );
  }

  Future<void> _onResetPassword(
      ResetPasswordRequested event, Emitter<CompteState> emit) async {
    emit(CompteLoading());
    final result = await resetPassword(
      email: event.email,
      code: event.code,
      nouveauMotDePasse: event.nouveauMotDePasse,
    );
    result.fold(
      (failure) => emit(CompteError(failure.errorMessage)),
      (_) => emit(CompteMessageSucces('Mot de passe réinitialisé avec succès')),
    );
  }

  Future<void> _onDeleteAccount(
      DeleteAccountRequested event, Emitter<CompteState> emit) async {
    if (_current != null) emit(CompteActionEnCours(_current!));
    final result = await deleteAccount(motif: event.motif);
    result.fold(
      (failure) => emit(CompteError(failure.errorMessage)),
      (_) => emit(CompteAccountDeleted()),
    );
  }
}
