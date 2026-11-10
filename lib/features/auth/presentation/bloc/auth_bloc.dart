import 'package:jwt_decode/jwt_decode.dart';
import 'package:saambiz/core/services/comptes_memorises.dart';
import 'package:saambiz/core/services/session_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/connexion_sociale_source.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_user.dart';
import '../signup/interets_page.dart' show effacerInteretsLocaux;
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;
  final AuthRepository repository;
  final ConnexionSocialeSource connexionSociale;

  AuthBloc({
    required this.loginUser,
    required this.repository,
    required this.connexionSociale,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<ConnexionSocialeDemandee>(_onConnexionSociale);
    on<RepriseCompteDemandee>(_onRepriseCompte);
    on<ChangementDeCompteDemande>(_onChangementDeCompte);
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

    final result = await loginUser(identifiant, event.mot_de_passe);

    result.fold(
      (failure) => emit(AuthFailure(message: failure.errorMessage)),
      (user) => emit(AuthSuccess(user: user)),
    );
  }

  Future<void> _onConnexionSociale(
    ConnexionSocialeDemandee event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthSocialEnCours(event.fournisseur));

    final IdentiteSociale identite;
    try {
      identite = await connexionSociale.obtenir(event.fournisseur);
    } on ConnexionSocialeAnnulee {
      emit(AuthInitial()); // fenêtre fermée : pas de message d'erreur
      return;
    } on ConnexionSocialeIndisponible {
      emit(
        const AuthConnexionIndisponible(
          message:
              'La connexion avec Google arrive bientôt. En attendant, '
              'connectez-vous avec votre e-mail et votre mot de passe.',
        ),
      );
      return;
    } catch (_) {
      final nom = event.fournisseur == FournisseurSocial.google
          ? 'Google'
          : 'Apple';
      emit(AuthFailure(message: 'La connexion avec $nom n\'a pas abouti.'));
      return;
    }

    final result = await repository.connexionSociale(identite);
    result.fold(
      (failure) => emit(AuthFailure(message: failure.errorMessage)),
      (user) => emit(AuthSuccess(user: user)),
    );
  }

  Future<void> _onRepriseCompte(
    RepriseCompteDemandee event,
    Emitter<AuthState> emit,
  ) async {
    final compte = event.compte;
    if (!compte.sessionOuverte) {
      emit(AuthCompteAReconnecter(compte));
      return;
    }
    emit(AuthRepriseEnCours(compte.id));

    final resultat = await sl<SessionService>().reprendre(compte);
    switch (resultat) {
      case ResultatRenouvellement.renouvele:
        final token = await sl<TokenService>().getToken();
        try {
          final duJeton = UserModel.fromJson(Jwt.parseJwt(token ?? ''));
          // Le jeton porte l'identité ; téléphone et photo viennent du compte
          // mémorisé, que le jeton ne contient pas.
          final user = UserModel(
            id: duJeton.id,
            nom: duJeton.nom,
            prenom: duJeton.prenom,
            email: duJeton.email,
            mot_de_passe: '',
            adresse: duJeton.adresse,
            telephone: compte.telephone,
            role: duJeton.role,
            photoProfil: compte.photoProfil,
          );
          await sl<ComptesMemorises>().enregistrer(
            user,
            await sl<TokenService>().getRefreshToken(),
          );
          emit(AuthSuccess(user: user));
        } catch (_) {
          emit(AuthCompteAReconnecter(compte));
        }
      case ResultatRenouvellement.refuse:
      case ResultatRenouvellement.aucune:
        emit(
          AuthCompteAReconnecter(
            compte,
            message: 'Votre session a expiré. Saisissez votre mot de passe.',
          ),
        );
      case ResultatRenouvellement.injoignable:
        emit(
          const AuthFailure(
            message: 'Connexion impossible. Vérifiez votre accès à internet.',
          ),
        );
    }
  }

  /// Ce qui appartient au compte courant quitte le téléphone (jetons,
  /// identité, goûts locaux). Commun à la déconnexion et au changement de
  /// compte.
  Future<void> _oublierCompteCourant() async {
    await sl<TokenService>().clearToken();
    await sl<FlutterSecureStorage>().delete(key: 'user_id');
    // Les goûts du compte restent au compte (sur le serveur) : l'invité
    // qui prend la suite sur ce téléphone repart d'un accueil neutre.
    await effacerInteretsLocaux();
  }

  /// Quitte le compte courant en gardant sa session sur le téléphone, pour y
  /// revenir d'un toucher depuis l'écran de connexion.
  Future<void> _quitterCompte(User? quitte) async {
    final jetons = sl<TokenService>();
    final refresh = await jetons.getRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      var compte = quitte;
      if (compte == null) {
        // Session ouverte avant l'arrivée du choix de compte : l'identité est
        // relue dans le jeton.
        try {
          compte = UserModel.fromJson(
            Jwt.parseJwt(await jetons.getToken() ?? ''),
          );
        } catch (_) {}
      }
      if (compte != null) {
        await sl<ComptesMemorises>().enregistrer(compte, refresh);
      }
    }
    await _oublierCompteCourant();
  }

  Future<void> _onChangementDeCompte(
    ChangementDeCompteDemande event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _quitterCompte(event.compteQuitte);
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(message: 'Erreur lors du changement de compte : $e'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Avant de quitter la session : ce téléphone ne reçoit plus les
      // notifications push du compte qui part.
      await FcmService.desinscrire();
      if (event.compteSupprime) {
        final id = await sl<FlutterSecureStorage>().read(key: 'user_id');
        if (id != null) await sl<ComptesMemorises>().oublier(id);
        await _oublierCompteCourant();
      } else {
        // Pas de révocation ici : la session reste mémorisée. Elle n'est
        // fermée sur le serveur que par « Retirer ce compte » (écran de
        // connexion).
        await _quitterCompte(event.compteQuitte);
      }
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(message: 'Erreur lors de la déconnexion : $e'));
    }
  }
}
