import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/services/session_service.dart';
import '../../data/models/user_model.dart';
import '../../../../injection_container.dart';

/// Écran de chargement, juste après l'écran de démarrage natif (pictogramme
/// bleu marine sur fond blanc) : logo SaamBiz complet et fine barre de
/// chargement, sur le même fond blanc.
///
/// Le jeton est lu pendant que le logo s'affiche : l'écran reste au moins
/// 0,6 s (le temps de voir la marque), sans attente fixe supplémentaire.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fondu = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _router());
  }

  @override
  void dispose() {
    _fondu.dispose();
    super.dispose();
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
    final lecture = _lireJeton();
    await Future.wait([
      lecture,
      Future.delayed(const Duration(milliseconds: 600)),
    ]);
    var token = await lecture;

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
        /* jeton illisible : on continue vers l'onboarding */
      }
    }

    // Personne n'est connecté → les trois écrans d'onboarding, puis le choix
    // du profil.
    //
    // Volontairement à chaque ouverture, et non « une seule fois » : le drapeau
    // vivait dans le stockage sécurisé, que la sauvegarde automatique d'Android
    // restaure après une réinstallation. L'onboarding devenait alors
    // invisible et intestable. Il reste court (trois écrans, balayage,
    // bouton « Passer ») et ne concerne que les visiteurs sans session.
    Navigator.of(context).pushReplacementNamed(AppRouter.onboardingRoute);
  }

  @override
  Widget build(BuildContext context) {
    // Fond blanc, comme l'écran de démarrage natif : aucune coupure de couleur.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre invisible au-dessus : le logo reste exactement au centre.
            const TickerMode(
              enabled: false,
              child: ExcludeSemantics(
                child: Opacity(opacity: 0, child: _Chargement()),
              ),
            ),
            Image.asset(
              'assets/images/logo.png',
              width: 240,
              cacheWidth: 960,
              semanticLabel: 'SaamBiz',
            ),
            FadeTransition(opacity: _fondu, child: const _Chargement()),
          ],
        ),
      ),
    );
  }
}

/// Barre de chargement sous le logo.
class _Chargement extends StatelessWidget {
  const _Chargement();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: SizedBox(
        width: 120,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          child: LinearProgressIndicator(
            minHeight: 4,
            color: Color(0xFF01154B),
            backgroundColor: Color(0xFFFEF3D6),
          ),
        ),
      ),
    );
  }
}
