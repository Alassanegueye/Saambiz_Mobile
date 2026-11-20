import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/services/config_publique_service.dart';
import '../../../../core/widgets/intro_marque.dart';
import '../../../../core/services/session_service.dart';
import '../../data/models/user_model.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/comptes_memorises.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';

/// Premier écran sous le rideau d'arrivée ([IntroMarque]) : il lit la session
/// et choisit où entrer (onboarding, connexion ou espace du rôle). Le logo
/// animé est dessiné par [IntroMarque], posé au-dessus ; cet écran reste un
/// simple fond blanc, et signale au rideau qu'il peut se lever.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

/// Où aller quand aucune session n'est ouverte.
///
/// Extraite de l'aiguillage pour être vérifiable : le reste de `_router`
/// interroge le réseau, le stockage sécurisé et le navigateur, et cette
/// décision-là se lit en trois lignes.
///
/// * onboarding jamais vu → les trois écrans de présentation ;
/// * déjà vu, des comptes sur ce téléphone → l'écran de connexion, qui les
///   propose ;
/// * déjà vu, aucun compte → l'inscription.
///
/// Les deux derniers cas sont exactement ce que donne la FIN de l'onboarding
/// (`OnboardingPage._finish`) : on y va directement, sans rebalayer.
String destinationSansSession({required bool vu, required bool comptes}) {
  if (!vu) return AppRouter.onboardingRoute;
  return comptes ? AppRouter.loginRoute : AppRouter.profileChoiceRoute;
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
    // Lancée avant la lecture du jeton et attendue plus bas : la vérification
    // de l'état du service n'ajoute donc aucune attente au démarrage, et une
    // panne du serveur la laisse sans réponse (`null`) sans bloquer l'entrée.
    final etatService = sl<ConfigPubliqueService>().configApp();

    // Pas d'attente minimale ici : le rideau garde le logo à l'écran le temps
    // de son animation.
    var token = await _lireJeton();

    // `/app/config` existait côté backend sans que personne ne l'appelle :
    // une mise en maintenance n'atteignait pas les téléphones, qui
    // continuaient de frapper une API arrêtée et affichaient des erreurs
    // réseau incompréhensibles.
    final etat = await etatService;
    if (!mounted) return;
    if (etat != null && etat.maintenance) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _EcranMaintenance(message: etat.message),
        ),
      );
      return;
    }

    // Jeton expiré : on tente d'en obtenir un autre avant de demander quoi que
    // ce soit à l'utilisateur.
    if (token != null && token.isNotEmpty && _expire(token)) {
      final resultat = await sl<SessionService>().renouveler();
      if (resultat == ResultatRenouvellement.renouvele) {
        token = await _lireJeton();
      } else if (resultat == ResultatRenouvellement.injoignable ||
          resultat == ResultatRenouvellement.serveurIndisponible) {
        // Hors ligne : la session reste valable, elle sera renouvelée au retour
        // du réseau par la première requête. On entre quand même.
      } else {
        token = null; // session refusée : retour à l'onboarding
      }
    }

    if (!mounted) return;

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

    // Personne n'est connecté : déconnexion, session refusée après trois
    // heures sans activité, ou toute première ouverture.
    //
    // L'onboarding ne se montre qu'une fois : une session se ferme après
    // trois heures de silence, et revenir le matin ne doit pas obliger à
    // rebalayer trois écrans avant d'atteindre son compte.
    final vu = OnboardingPage.dejaVu();

    // Les comptes ne sont lus que si l'onboarding a déjà été vu : à la
    // première ouverture, il n'y en a de toute façon aucun.
    var comptes = false;
    if (vu) {
      try {
        comptes = (await sl<ComptesMemorises>().lister()).isNotEmpty;
      } catch (_) {
        // Stockage illisible : l'écran de connexion sait aussi se présenter
        // sans compte mémorisé.
        comptes = true;
      }
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacementNamed(destinationSansSession(vu: vu, comptes: comptes));
  }

  @override
  Widget build(BuildContext context) {
    // Fond blanc, comme le rideau d'arrivée posé au-dessus.
    return const Scaffold(backgroundColor: Colors.white);
  }
}

/// Affiché quand le backend se déclare en maintenance.
///
/// Sans cet écran, l'application entrait normalement puis échouait requête
/// après requête, et l'utilisateur ne pouvait pas distinguer une coupure
/// annoncée d'une panne de son téléphone.
class _EcranMaintenance extends StatelessWidget {
  final String? message;
  const _EcranMaintenance({this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.build_outlined,
                size: 56,
                color: Color(0xFF01154B),
              ),
              const SizedBox(height: 20),
              const Text(
                'SaamBiz est en maintenance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF01154B),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message?.trim().isNotEmpty == true
                    ? message!.trim()
                    : 'Le service est momentanément indisponible. '
                          'Réessayez dans quelques minutes.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
