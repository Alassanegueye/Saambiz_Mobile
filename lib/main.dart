import 'dart:async';
import 'package:saambiz/core/demo/donnees_demo.dart';
import 'package:saambiz/core/routes/app_router.dart';
import 'package:saambiz/core/theme/app_theme.dart';
import 'package:saambiz/core/utils/app_logger.dart';
import 'package:saambiz/core/widgets/fermeture_clavier.dart';
import 'package:saambiz/core/widgets/intro_marque.dart';
import 'package:saambiz/features/auth/presentation/bloc/auth_bloc.dart'; // <-- IMPORT AJOUTÉ
import 'package:saambiz/features/auth/presentation/pages/app_bootstrap.dart';
import 'package:saambiz/injection_container.dart' as di;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saambiz/core/connection/auth_interceptor.dart';
import 'core/routes/observateur_routes.dart';
import 'core/services/fcm_service.dart';
import 'core/services/veille_session.dart';

void main() async {
  // Capture toute erreur non interceptée (synchrone ou asynchrone) pour éviter
  // un crash silencieux en production et un écran rouge exposant la stack
  // trace à l'utilisateur final.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Erreurs du framework Flutter (construction, mise en page, peinture).
      // Remontées à Crashlytics : ce sont elles qui produisent l'écran blanc
      // qu'un vendeur décrit par « ça ne marche pas ».
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        logErreur(
          'erreur Flutter : ${details.context ?? 'sans contexte'}',
          details.exception,
          details.stack,
        );
      };

      // Erreurs asynchrones non capturées, hors du framework.
      PlatformDispatcher.instance.onError = (error, stack) {
        logErreur('erreur asynchrone non interceptée', error, stack);
        return true; // empêche l'arrêt du processus
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

      // Notifications push (Firebase), sans effet si non configuré.
      await initialiserFirebase();

      // Captures App Store : les photos des produits de démonstration sont
      // embarquées, rien n'est téléchargé. Sans --dart-define=DEMO=true,
      // cet appel est éliminé à la compilation.
      if (modeDemo) installerImagesDemo();

      runApp(const MyApp());
    },
    (error, stack) {
      // Dernier filet : ce qui n'a été attrapé nulle part ailleurs.
      logErreur('erreur non gérée (zone racine)', error, stack);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => di.sl<AuthBloc>())],
      child: MaterialApp(
        navigatorKey: AuthInterceptor.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'SaamBiz',
        theme: AppTheme.light(),
        // Défilement élastique partout, Android compris : les listes
        // « respirent » au lieu de buter sur un halo.
        scrollBehavior: const _DefilementSouple(),
        // Sous surveillance : trois heures sans revenir, et la session se
        // ferme d'elle-même au retour, sans laisser le compte s'afficher une
        // seconde avant que le serveur ne refuse le renouvellement.
        home: const SousVeille(enfant: AppBootstrap()),
        onGenerateRoute: AppRouter.onGenerateRoute,
        navigatorObservers: [observateurRoutes],
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
          // Écran d'arrivée (logo animé du site), au-dessus de tout : il se
          // lève sur le premier écran une fois celui-ci choisi.
          child: IntroMarque(
            child: FermetureClavier(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}

class _DefilementSouple extends MaterialScrollBehavior {
  const _DefilementSouple();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}
