import 'package:saambiz/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:saambiz/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:saambiz/features/auth/domain/repositories/auth_repository.dart';
import 'package:saambiz/features/auth/domain/usecases/login_user.dart';
import 'package:saambiz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:saambiz/features/home/data/datasources/produit_remote_datasource.dart';
import 'package:saambiz/features/home/data/repositories/produit_repository_impl.dart';
import 'package:saambiz/features/home/presentation/bloc/produit_bloc.dart';
import 'package:saambiz/features/commande/data/datasources/commande_remote_datasource.dart';
import 'package:saambiz/features/commande/data/repositories/commande_repository.dart';
import 'package:saambiz/features/commande/data/services/panier_service.dart';
import 'package:saambiz/features/commande/presentation/bloc/commande_bloc.dart';
import 'package:saambiz/features/vendeur/data/datasources/vendeur_produit_datasource.dart';
import 'package:saambiz/features/vendeur/data/repositories/vendeur_produit_repository_impl.dart';
import 'package:saambiz/features/vendeur/domain/repositories/vendeur_produit_repository.dart';
import 'package:saambiz/features/vendeur/domain/usecases/get_mes_produits.dart';
import 'package:saambiz/features/vendeur/domain/usecases/get_categories_vendeur.dart';
import 'package:saambiz/features/vendeur/domain/usecases/ajouter_produit.dart';
import 'package:saambiz/features/vendeur/domain/usecases/modifier_produit.dart';
import 'package:saambiz/features/vendeur/domain/usecases/supprimer_produit.dart';
import 'package:saambiz/features/vendeur/domain/usecases/toggle_disponibilite_produit.dart';
import 'package:saambiz/features/vendeur/domain/usecases/dupliquer_produit.dart';
import 'package:saambiz/features/vendeur/domain/usecases/ajouter_images_produit.dart';
import 'package:saambiz/features/vendeur/domain/usecases/supprimer_image_produit.dart';
import 'package:saambiz/features/vendeur/domain/usecases/get_vendeur_dashboard.dart';
import 'package:saambiz/features/vendeur/presentation/bloc/vendeur_produit_bloc.dart';
import 'package:saambiz/features/compte/data/datasources/compte_remote_datasource.dart';
import 'package:saambiz/features/compte/data/repositories/compte_repository_impl.dart';
import 'package:saambiz/features/compte/domain/repositories/compte_repository.dart';
import 'package:saambiz/features/compte/domain/usecases/get_me.dart';
import 'package:saambiz/features/compte/domain/usecases/modifier_profil.dart';
import 'package:saambiz/features/compte/domain/usecases/change_password.dart';
import 'package:saambiz/features/compte/domain/usecases/forgot_password.dart';
import 'package:saambiz/features/compte/domain/usecases/reset_password.dart';
import 'package:saambiz/features/compte/domain/usecases/delete_account.dart';
import 'package:saambiz/features/compte/presentation/bloc/compte_bloc.dart';
import 'package:saambiz/features/boutique/data/datasources/boutique_remote_datasource.dart';
import 'package:saambiz/features/boutique/data/repositories/boutique_repository_impl.dart';
import 'package:saambiz/features/boutique/domain/repositories/boutique_repository.dart';
import 'package:saambiz/features/boutique/domain/usecases/get_ma_boutique.dart';
import 'package:saambiz/features/boutique/domain/usecases/creer_boutique.dart';
import 'package:saambiz/features/boutique/domain/usecases/modifier_boutique.dart';
import 'package:saambiz/features/boutique/domain/usecases/pause_boutique.dart';
import 'package:saambiz/features/boutique/domain/usecases/reactiver_boutique.dart';
import 'package:saambiz/features/boutique/presentation/bloc/boutique_bloc.dart';
import 'package:saambiz/features/vitrine/data/datasources/vitrine_remote_datasource.dart';
import 'package:saambiz/features/vitrine/data/repositories/vitrine_repository_impl.dart';
import 'package:saambiz/features/vitrine/domain/repositories/vitrine_repository.dart';
import 'package:saambiz/features/vitrine/domain/usecases/analyser_logo.dart';
import 'package:saambiz/features/vitrine/domain/usecases/generer_vitrine.dart';
import 'package:saambiz/features/vitrine/domain/usecases/get_ma_vitrine.dart';
import 'package:saambiz/features/vitrine/domain/usecases/get_secteurs_vitrine.dart';
import 'package:saambiz/features/vitrine/domain/usecases/modifier_vitrine.dart';
import 'package:saambiz/features/vitrine/presentation/bloc/vitrine_bloc.dart';
import 'package:saambiz/features/abonnement/data/datasources/abonnement_remote_datasource.dart';
import 'package:saambiz/features/abonnement/data/repositories/abonnement_repository_impl.dart';
import 'package:saambiz/features/abonnement/domain/repositories/abonnement_repository.dart';
import 'package:saambiz/features/abonnement/domain/usecases/get_mon_abonnement.dart';
import 'package:saambiz/features/abonnement/domain/usecases/initier_renouvellement.dart';
import 'package:saambiz/features/abonnement/domain/usecases/get_historique_paiements.dart';
import 'package:saambiz/features/abonnement/domain/usecases/payer.dart';
import 'package:saambiz/features/abonnement/domain/usecases/get_paiement.dart';
import 'package:saambiz/features/abonnement/presentation/bloc/abonnement_bloc.dart';
import 'package:saambiz/features/favoris/data/datasources/favoris_remote_datasource.dart';
import 'package:saambiz/features/favoris/data/repositories/favoris_repository_impl.dart';
import 'package:saambiz/features/favoris/domain/repositories/favoris_repository.dart';
import 'package:saambiz/features/favoris/domain/usecases/basculer_cloche.dart';
import 'package:saambiz/features/favoris/domain/usecases/get_boutiques_suivies.dart';
import 'package:saambiz/features/favoris/domain/usecases/get_statut_suivi.dart';
import 'package:saambiz/features/favoris/domain/usecases/ne_plus_suivre_boutique.dart';
import 'package:saambiz/features/favoris/domain/usecases/suivre_boutique.dart';
import 'package:saambiz/features/favoris/presentation/bloc/favoris_bloc.dart';
import 'package:saambiz/features/messagerie/data/datasources/messagerie_remote_datasource.dart';
import 'package:saambiz/features/messagerie/data/repositories/messagerie_repository.dart';
import 'package:saambiz/features/messagerie/presentation/bloc/messagerie_bloc.dart';
import 'package:saambiz/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:saambiz/features/notifications/data/repositories/notifications_repository.dart';
import 'package:saambiz/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:saambiz/features/promotions/data/datasources/promotions_remote_datasource.dart';
import 'package:saambiz/features/promotions/data/repositories/promotions_repository.dart';
import 'package:saambiz/features/promotions/presentation/bloc/promotions_bloc.dart';
import 'package:saambiz/features/signalements/data/datasources/signalements_remote_datasource.dart';
import 'package:saambiz/features/signalements/data/repositories/signalements_repository.dart';
import 'package:saambiz/features/signalements/presentation/bloc/signalements_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:saambiz/core/config/env.dart';
import 'core/services/token_service.dart';
import 'core/services/socket_service.dart';

// Service Locator
final sl = GetIt.instance;

// Journalisation sécurisée : on n'imprime (token, corps de requête, données)
// QU'EN DÉBOGAGE. En release, rien n'est loggué → pas de fuite de données sensibles.
void _log(Object? message) {
  if (kDebugMode) {
    // ignore: avoid_print
    print(message);
  }
}

Future<void> init() async {
  //================================================
  // INITIALISATION DES SERVICES EXTERNES
  //================================================

  // Contrôle de cohérence de la configuration compilée. Mieux vaut un écran
  // d'erreur explicite au lancement qu'une application de production qui
  // parle à l'API de développement.
  Env.verifier();

  // Le .env reste chargé en repli pour les postes de développement qui ne
  // passent pas encore les --dart-define. Son absence n'est plus bloquante :
  // Env fournit des valeurs par défaut.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Fichier absent : la configuration vient des --dart-define.
  }

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // SecureStorage
  sl.registerLazySingleton(() => const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  ));

  //================================================
  // CORE SERVICES
  //================================================

  // Services
  sl.registerLazySingleton(() => TokenService(secureStorage: sl()));
  sl.registerLazySingleton(() => SocketService(tokenService: sl()));

  //================================================
  // EXTERNAL - DIO HTTP CLIENT
  //================================================

  sl.registerLazySingleton(() {
    // Priorité au --dart-define ; le .env n'intervient que s'il apporte une
    // valeur là où la compilation n'en a pas fourni. Env.verifier() a déjà
    // refusé les configurations incohérentes au démarrage.
    final depuisEnv = dotenv.maybeGet('API_BASE_URL')?.trim();
    final baseUrl = (depuisEnv != null && depuisEnv.isNotEmpty)
        ? depuisEnv
        : Env.apiBaseUrl;

    // Configuration améliorée de Dio
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Env.timeoutConnexion,
        receiveTimeout: Env.timeoutReception,
        sendTimeout: Env.timeoutEnvoi,
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Intercepteurs pour logging et gestion du token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Logging des requêtes
          _log('🌐 [REQUEST] ${options.method} ${options.path}');
          if (options.data != null) {
            if (options.data is FormData) {
              final formData = options.data as FormData;
              _log('📦 FormData fields:');
              formData.fields.forEach((field) {
                _log('  ${field.key}: ${field.value}');
              });
              formData.files.forEach((file) {
                _log('  ${file.key}: ${file.value.filename}');
              });
            } else {
              _log('📦 Body: ${options.data}');
            }
          }

          // Ajout du token JWT sauf sur les routes ouvertes.
          //
          // Les deux étapes de vérification de l'adresse en font partie : elles
          // s'adressent à quelqu'un qui n'a pas encore de compte, donc pas de
          // jeton. Y joindre un jeton périmé traîné d'une session précédente
          // ferait échouer l'inscription sur un 401 incompréhensible.
          final path = options.path.split('?')[0].trim();
          final isAuthEndpoint = path.endsWith('/auth/login') ||
              path.endsWith('/auth/register') ||
              path.endsWith('/auth/inscription/envoyer-code') ||
              path.endsWith('/auth/inscription/verifier-code');

          if (!isAuthEndpoint) {
            try {
              final token = await sl<TokenService>().getToken();

              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
                _log('🔑 Token ajouté à la requête');
              }
            } catch (e) {
              _log('⚠️ Erreur lors de la récupération du token: $e');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _log('✅ [RESPONSE] ${response.statusCode} ${response.requestOptions.path}');
          if (response.data != null && response.data is Map) {
            _log('📥 Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          _log('❌ [ERROR] ${e.type} ${e.requestOptions.path}');
          _log('📝 Message: ${e.message}');
          if (e.response != null) {
            _log('📊 Status: ${e.response!.statusCode}');
            _log('📋 Data: ${e.response!.data}');
          }
          return handler.next(e);
        },
      ),
    );

    return dio;
  });

  //================================================
  // FEATURES - AUTHENTICATION
  //================================================

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(dio: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUser(sl()));

  // BLoC
  sl.registerFactory(() => AuthBloc(
    loginUser: sl(),
  ));

  //================================================
  // FEATURES - HOME (PRODUITS / BOUTIQUES)
  //================================================

  // Data Source (réutilise le Dio partagé configuré avec API_BASE_URL + intercepteur token)
  sl.registerLazySingleton<ProduitRemoteDataSource>(
        () => ProduitRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton(() => ProduitRepository(sl()));

  // BLoC
  sl.registerFactory(() => ProduitBloc(sl()));

  //================================================
  // FEATURES - COMMANDE / PANIER (e-commerce)
  //================================================

  // Panier local persistant (réutilise SharedPreferences)
  sl.registerLazySingleton(() => PanierService(prefs: sl()));

  // Data Source (Dio partagé)
  sl.registerLazySingleton<CommandeRemoteDataSource>(
        () => CommandeRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton(() => CommandeRepository(sl()));

  // BLoC
  sl.registerFactory(() => CommandeBloc(sl()));

  //================================================
  // FEATURES - VENDEUR (gestion produits)
  //================================================

  sl.registerLazySingleton(() => VendeurProduitDataSource(sl()));

  sl.registerLazySingleton<VendeurProduitRepository>(
        () => VendeurProduitRepositoryImpl(dataSource: sl()),
  );

  sl.registerLazySingleton(() => GetMesProduits(sl()));
  sl.registerLazySingleton(() => GetCategoriesVendeur(sl()));
  sl.registerLazySingleton(() => AjouterProduitUsecase(sl()));
  sl.registerLazySingleton(() => ModifierProduitUsecase(sl()));
  sl.registerLazySingleton(() => SupprimerProduitUsecase(sl()));
  sl.registerLazySingleton(() => ToggleDisponibiliteProduitUsecase(sl()));
  sl.registerLazySingleton(() => DupliquerProduitUsecase(sl()));
  sl.registerLazySingleton(() => AjouterImagesProduitUsecase(sl()));
  sl.registerLazySingleton(() => SupprimerImageProduitUsecase(sl()));
  sl.registerLazySingleton(() => GetVendeurDashboard(sl()));

  sl.registerFactory(() => VendeurProduitBloc(
    getMesProduits: sl(),
    supprimerProduit: sl(),
    toggleDisponibilite: sl(),
  ));

  //================================================
  // FEATURES - COMPTE (profil utilisateur connecté)
  //================================================

  sl.registerLazySingleton<CompteRemoteDataSource>(
        () => CompteRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<CompteRepository>(
        () => CompteRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetMe(sl()));
  sl.registerLazySingleton(() => ModifierProfil(sl()));
  sl.registerLazySingleton(() => ChangePassword(sl()));
  sl.registerLazySingleton(() => ForgotPassword(sl()));
  sl.registerLazySingleton(() => ResetPassword(sl()));
  sl.registerLazySingleton(() => DeleteAccount(sl()));

  sl.registerFactory(() => CompteBloc(
    getMe: sl(),
    modifierProfil: sl(),
    changePassword: sl(),
    forgotPassword: sl(),
    resetPassword: sl(),
    deleteAccount: sl(),
  ));

  //================================================
  // FEATURES - BOUTIQUE (vendeur)
  //================================================

  sl.registerLazySingleton<BoutiqueRemoteDataSource>(
        () => BoutiqueRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<BoutiqueRepository>(
        () => BoutiqueRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetMaBoutique(sl()));
  sl.registerLazySingleton(() => CreerBoutique(sl()));
  sl.registerLazySingleton(() => ModifierBoutique(sl()));
  sl.registerLazySingleton(() => PauseBoutique(sl()));
  sl.registerLazySingleton(() => ReactiverBoutique(sl()));

  sl.registerFactory(() => BoutiqueBloc(
    getMaBoutique: sl(),
    creerBoutique: sl(),
    modifierBoutique: sl(),
    pauseBoutique: sl(),
    reactiverBoutique: sl(),
  ));

  //================================================
  // FEATURES - VITRINE : LE SITE WEB DE LA BOUTIQUE (vendeur)
  //================================================
  // Le site public du vendeur, distinct de sa fiche dans l'application :
  // celle-ci est la même pour toutes les boutiques, pour qu'un client s'y
  // retrouve d'un coup d'œil. Le site web, lui, porte ses couleurs.

  sl.registerLazySingleton<VitrineRemoteDataSource>(
        () => VitrineRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<VitrineRepository>(
        () => VitrineRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetMaVitrine(sl()));
  sl.registerLazySingleton(() => GetSecteursVitrine(sl()));
  sl.registerLazySingleton(() => AnalyserLogo(sl()));
  sl.registerLazySingleton(() => GenererVitrine(sl()));
  sl.registerLazySingleton(() => ModifierVitrine(sl()));

  sl.registerFactory(() => VitrineBloc(
    getMaVitrine: sl(),
    getSecteurs: sl(),
    analyserLogo: sl(),
    genererVitrine: sl(),
    modifierVitrine: sl(),
  ));

  //================================================
  // FEATURES - ABONNEMENT + PAIEMENT (vendeur)
  //================================================

  sl.registerLazySingleton<AbonnementRemoteDataSource>(
        () => AbonnementRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<AbonnementRepository>(
        () => AbonnementRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetMonAbonnement(sl()));
  sl.registerLazySingleton(() => InitierRenouvellement(sl()));
  sl.registerLazySingleton(() => GetHistoriquePaiements(sl()));
  sl.registerLazySingleton(() => Payer(sl()));
  sl.registerLazySingleton(() => GetPaiement(sl()));

  sl.registerFactory(() => AbonnementBloc(
    getMonAbonnement: sl(),
    initierRenouvellement: sl(),
    getHistoriquePaiements: sl(),
    payer: sl(),
  ));

  //================================================
  // FEATURES - FAVORIS (acheteur)
  //================================================

  sl.registerLazySingleton<FavorisRemoteDataSource>(
        () => FavorisRemoteDataSourceImpl(sl()),
  );
  // Le contrat est enregistré, pas l'implémentation : le bloc et les cas
  // d'usage ne connaissent que l'interface du domaine.
  sl.registerLazySingleton<FavorisRepository>(() => FavorisRepositoryImpl(sl()));

  sl.registerLazySingleton(() => GetBoutiquesSuivies(sl()));
  sl.registerLazySingleton(() => SuivreBoutique(sl()));
  sl.registerLazySingleton(() => NePlusSuivreBoutique(sl()));
  sl.registerLazySingleton(() => BasculerCloche(sl()));
  sl.registerLazySingleton(() => GetStatutSuivi(sl()));

  sl.registerFactory(() => FavorisBloc(
        getBoutiquesSuivies: sl(),
        suivreBoutique: sl(),
        nePlusSuivreBoutique: sl(),
        basculerCloche: sl(),
      ));

  //================================================
  // FEATURES - MESSAGERIE (temps réel via socket + REST)
  //================================================

  sl.registerLazySingleton<MessagerieRemoteDataSource>(
        () => MessagerieRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton(() => MessagerieRepository(sl()));
  sl.registerFactory(() => MessagerieBloc(sl()));

  //================================================
  // FEATURES - NOTIFICATIONS (temps réel via socket + REST) + device token
  //================================================

  sl.registerLazySingleton<NotificationsRemoteDataSource>(
        () => NotificationsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton(() => NotificationsRepository(sl()));
  sl.registerFactory(() => NotificationsBloc(sl()));

  //================================================
  // FEATURES - PROMOTIONS
  //================================================

  sl.registerLazySingleton<PromotionsRemoteDataSource>(
        () => PromotionsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton(() => PromotionsRepository(sl()));
  sl.registerFactory(() => PromotionsBloc(sl()));

  //================================================
  // FEATURES - SIGNALEMENTS
  //================================================

  sl.registerLazySingleton<SignalementsRemoteDataSource>(
        () => SignalementsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton(() => SignalementsRepository(sl()));
  sl.registerFactory(() => SignalementsBloc(sl()));

  //================================================
  // VÉRIFICATION DES VARIABLES D'ENVIRONNEMENT
  //================================================

  _validateEnvVariables();

  // Démarre immédiatement l'écoute des changements d'authentification pour
  // (re)connecter le socket temps réel (messagerie / notifications) sans
  // attendre qu'un écran le résolve explicitement.
  sl<SocketService>();
}

void _validateEnvVariables() {
  final requiredVariables = [
    'API_BASE_URL',
    'AUTH_LOGIN_PATH',
    'AUTH_REGISTER_PATH',
  ];

  final missingVariables = <String>[];

  for (final variable in requiredVariables) {
    final value = dotenv.maybeGet(variable)?.trim();
    if (value == null || value.isEmpty) {
      missingVariables.add(variable);
    }
  }

  if (missingVariables.isNotEmpty) {
    throw StateError(
      'Les variables d\'environnement suivantes sont manquantes dans votre fichier .env:\n'
          '${missingVariables.join('\n')}\n\n'
          'Assurez-vous qu\'elles sont définies avant de lancer l\'application.',
    );
  }

  _log('✅ Toutes les variables d\'environnement sont configurées');
  _log('🌐 API Base URL: ${dotenv.get('API_BASE_URL')}');
  _log('🔑 Auth Login Path: ${dotenv.get('AUTH_LOGIN_PATH')}');
  _log('📝 Auth Register Path: ${dotenv.get('AUTH_REGISTER_PATH')}');
}