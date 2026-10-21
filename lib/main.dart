import 'dart:async';
import 'package:saambiz/core/routes/app_router.dart';
import 'package:saambiz/core/theme/app_theme.dart';
import 'package:saambiz/core/utils/app_logger.dart';
import 'package:saambiz/features/auth/presentation/bloc/auth_bloc.dart'; // <-- IMPORT AJOUTÉ
import 'package:saambiz/features/auth/presentation/pages/app_bootstrap.dart';
import 'package:saambiz/injection_container.dart' as di;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/connection/auth_interceptor.dart';



void main() async {
  // Capture toute erreur non interceptée (synchrone ou asynchrone) pour éviter
  // un crash silencieux en production et un écran rouge exposant la stack
  // trace à l'utilisateur final.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Erreurs du framework Flutter (build/layout/paint) : loguées en debug
    // uniquement (aucune fuite de données en production). À brancher plus tard
    // sur un service de crash reporting (Crashlytics/Sentry) si besoin.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      logDebug('💥 FlutterError: ${details.exceptionAsString()}');
    };

    // Erreurs asynchrones non capturées (hors du framework Flutter).
    PlatformDispatcher.instance.onError = (error, stack) {
      logDebug('💥 Erreur non interceptée: $error');
      return true; // empêche le crash du process
    };

    // En release, remplace l'écran rouge par défaut (qui expose la stack trace)
    // par un écran neutre pour l'utilisateur final.
    if (kReleaseMode) {
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return const Material(
          color: Colors.white,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Une erreur est survenue. Veuillez réessayer.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ),
          ),
        );
      };
    }

    // dotenv est chargé une seule fois, à l'intérieur de di.init().
    await di.init();

    runApp(const MyApp());
  }, (error, stack) {
    logDebug('💥 Erreur non gérée (zone racine): $error\n$stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
      ],
      child: MaterialApp(
        navigatorKey: AuthInterceptor.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'SaamBiz',
        theme: AppTheme.light(),
        home: const AppBootstrap(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        // Barre d'état par défaut : fond transparent, icônes sombres (heure,
        // réseau, batterie lisibles sur les écrans blancs). Sans ce réglage,
        // les icônes blanches laissées par un écran bleu (connexion,
        // inscription) devenaient invisibles sur l'accueil. Les écrans à
        // en-tête bleu posent leur propre réglage, qui l'emporte.
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
