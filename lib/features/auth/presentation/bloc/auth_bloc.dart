import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/services/token_service.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/login_user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;

  AuthBloc({
    required this.loginUser,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ResetAuthState>((event, emit) {
      emit(AuthInitial());
    });
  }

  Future<void> _onLoginRequested(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    final identifiant = event.email ?? event.telephone;

    if (identifiant == null) {
      emit(const AuthFailure(message: "Email ou téléphone requis"));
      return;
    }

    final result = await loginUser(
      identifiant,
      event.mot_de_passe,
    );

    result.fold(
          (failure) => emit(AuthFailure(message: failure.errorMessage)),
          (user) => emit(AuthSuccess(user: user)),
    );
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      final storage = sl<FlutterSecureStorage>();

      await sl<TokenService>().clearToken();
      await storage.delete(key: 'user_id');

      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(message: 'Erreur lors de la déconnexion : $e'));
    }
  }


}