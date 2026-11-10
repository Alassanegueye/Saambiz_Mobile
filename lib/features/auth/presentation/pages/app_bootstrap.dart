import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/intro_marque.dart';
import '../../../../core/services/session_service.dart';
import '../../data/models/user_model.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../../injection_container.dart';

/// Premier écran sous le rideau d'arrivée ([IntroMarque]) : il lit la session
/// et choisit où entrer (onboarding, connexion ou espace du rôle). Le logo
/// animé est dessiné par [IntroMarque], posé au-dessus ; cet écran reste un
/// simple fond blanc, et signale au rideau qu'il peut se lever.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _router();
      } finally {
        // Quoi qu'il arrive, le rideau ne doit pas rester baissé.
        IntroMarque.signalerPret();
      }
    });
  }

  Future<String?> _lireJeton() async {
    try {
      return await sl<FlutterSecureStorage>().read(key: 'jwt_token');
    } catch (_) {
      return null; // jeton illisible : on repart de l'onboarding
    }
  }

  bool _expire(String token) {
    try {
      return Jwt.isExpired(token);
    } catch (_) {
      return false; // illisible : traité plus bas, comme sans session
    }
  }

  Future<void> _router() async {
    // Pas d'attente minimale ici : le rideau garde le logo à l'écran le temps
    // de son animation.
    var token = await _lireJeton();

    // Jeton expiré : on tente d'en obtenir un autre avant de demander quoi que
    // ce soit à l'utilisateur.
    var sessionRefusee = false;
    if (token != null && token.isNotEmpty && _expire(token)) {
      final resultat = await sl<SessionService>().renouveler();
      if (resultat == ResultatRenouvellement.renouvele) {
        token = await _lireJeton();
      } else if (resultat == ResultatRenouvellement.injoignable) {
        // Hors ligne : la session reste valable, elle sera renouvelée au retour
        // du réseau par la première requête. On entre quand même.
      } else {
        token = null;
        sessionRefusee = true;
      }
    }

    if (!mounted) return;

    if (sessionRefusee) {
      Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      return;
    }

    // Session encore valide → on entre directement, selon le rôle.
    if (token != null && token.isNotEmpty) {
      try {
        // Le jeton porte déjà l'identité : les écrans la connaissent dès le
        // premier affichage, sans attendre le serveur.
        final user = UserModel.fromJson(Jwt.parseJwt(token));
        Navigator.of(context).pushReplacementNamed(
          user.role == 'Vendeur'
              ? AppRouter.vendeurRoute
              : AppRouter.acheteurRoute,
          arguments: user,
        );
        return;
      } catch (_) {
        /* jeton illisible : traité comme sans session */
      }
    }

    // Personne n'est connecté. Les trois écrans d'onboarding ne se montrent
    // qu'à la première ouverture de l'application (voir [OnboardingPage]) ;
    // ensuite, on arrive directement sur la connexion, qui propose aussi de
    // créer un compte.
    //
    // Le drapeau vit dans les préférences (effacées à la désinstallation sur
    // iOS comme sur Android) et non dans le stockage sécurisé : le trousseau
    // iOS survit à la désinstallation, et la sauvegarde automatique d'Android
    // est coupée (android:allowBackup="false").
    if (OnboardingPage.dejaVu()) {
      Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRouter.onboardingRoute);
  }

  @override
  Widget build(BuildContext context) {
    // Fond blanc, comme le rideau d'arrivée posé au-dessus.
    return const Scaffold(backgroundColor: Colors.white);
  }
}
