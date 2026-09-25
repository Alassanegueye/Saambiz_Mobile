import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../injection_container.dart';

/// Premier écran de l'application — sans interface.
///
/// Il remplace l'ancienne page de chargement (logo + « Préparation en cours »)
/// qui imposait près de 3 secondes d'attente à chaque ouverture. La lecture du
/// jeton prend quelques millisecondes : on redirige aussitôt, sur un simple
/// fond bleu marine identique à celui de l'écran de démarrage natif, donc sans
/// transition visible.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _router());
  }

  Future<void> _router() async {
    final storage = sl<FlutterSecureStorage>();

    String? token;
    try {
      token = await storage.read(key: 'jwt_token');
    } catch (_) {
      /* jeton illisible : on repart de l'onboarding */
    }

    if (!mounted) return;

    // Session encore valide → on entre directement, selon le rôle.
    if (token != null && token.isNotEmpty) {
      try {
        if (!Jwt.isExpired(token)) {
          final role = (Jwt.parseJwt(token)['role'] ?? '').toString();
          Navigator.of(context).pushReplacementNamed(
            role == 'Vendeur'
                ? AppRouter.vendeurRoute
                : AppRouter.acheteurRoute,
            arguments: role == 'Vendeur' ? null : const {'isGuest': false},
          );
          return;
        }
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
    // Aucun contenu : ce fond ne doit pas se distinguer du splash natif.
    return const Scaffold(backgroundColor: Color(0xFF0D1B3D));
  }
}
