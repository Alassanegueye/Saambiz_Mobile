import 'package:flutter/widgets.dart';

import '../connection/auth_interceptor.dart';
import '../routes/app_router.dart';
import '../utils/app_logger.dart';
import '../../injection_container.dart';
import 'token_service.dart';

/// Ferme la session après un long silence.
///
/// Le jeton de rafraîchissement vit dix ans : tant qu'on s'en servait, la
/// session ne finissait jamais. Un téléphone reposé dix jours rouvrait
/// directement sur le compte — pratique, jusqu'au jour où le téléphone est
/// perdu, prêté, ou qu'on le pose sur un comptoir.
///
/// Le serveur tranche, et c'est lui qui fait foi : un renouvellement demandé
/// après une semaine de silence est refusé. CE GUET N'EST PAS LA SÉCURITÉ,
/// il en est la bonne manière : sans lui, revenir sur une application restée
/// en arrière-plan affichait le compte pendant une seconde — le temps qu'une
/// requête parte, revienne en 401 et renvoie à la connexion. L'utilisateur
/// voyait son compte s'ouvrir puis se fermer sous ses yeux.
///
/// Ce qui n'en relève pas : l'application FERMÉE puis rouverte. Là, c'est
/// `AppBootstrap` qui lit le jeton, constate qu'il est périmé, tente un
/// renouvellement et se fait refuser — même résultat, autre chemin.
class VeilleSession with WidgetsBindingObserver {
  /// Une semaine, la même valeur que le serveur (`inactiviteMaxMs`). Si
  /// elles divergeaient, celle du serveur gagnerait : il refuserait le
  /// renouvellement que ce guet aurait laissé passer.
  static const duree = Duration(days: 7);

  final TokenService jetons;

  /// L'heure courante. Injectable pour que les tests jouent une absence de
  /// une semaine sans en attendre une.
  final DateTime Function() horloge;

  /// Dernier moment où l'application était à l'écran.
  DateTime? _depuis;

  bool _observe = false;

  VeilleSession({required this.jetons, DateTime Function()? horloge})
    : horloge = horloge ?? DateTime.now;

  /// Vrai tant que le guet reçoit les changements d'état.
  bool get observe => _observe;

  void demarrer() {
    if (_observe) return;
    WidgetsBinding.instance.addObserver(this);
    _observe = true;
  }

  void arreter() {
    if (!_observe) return;
    WidgetsBinding.instance.removeObserver(this);
    _observe = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    switch (etat) {
      // `paused` : l'application quitte l'écran. `hidden` et `inactive` ne
      // comptent pas — une notification qui glisse, un appel qui s'affiche,
      // le sélecteur d'applications : on n'a pas quitté pour autant.
      case AppLifecycleState.paused:
        _depuis = horloge();
      case AppLifecycleState.resumed:
        _verifier();
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _verifier() async {
    final depuis = _depuis;
    _depuis = null;
    if (depuis == null) return;

    final absence = horloge().difference(depuis);
    if (absence < duree) return;

    // Pas de session en cours : rien à fermer, et surtout rien à faire
    // dériver un visiteur vers l'écran de connexion.
    if (!await jetons.isAuthenticated) return;

    logDebug('Session fermée après ${absence.inMinutes} min sans activité');
    await jetons.clearToken();

    AuthInterceptor.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRouter.loginRoute,
      (_) => false,
    );
  }
}

/// Branche [VeilleSession] sur la durée de vie de l'application.
class SousVeille extends StatefulWidget {
  final Widget enfant;

  /// Le guet à brancher. Fourni par les tests ; en production il se construit
  /// sur le service de jetons de l'application.
  final VeilleSession? veille;

  const SousVeille({super.key, required this.enfant, this.veille});

  @override
  State<SousVeille> createState() => _SousVeilleState();
}

class _SousVeilleState extends State<SousVeille> {
  VeilleSession? _veille;

  // CONSTRUIT ICI, PAS EN `late final`. Un `late final` ne s'évalue qu'à sa
  // première lecture : le seul endroit qui lisait ce champ était `dispose`,
  // si bien que le guet ne commençait à observer qu'au moment de s'arrêter.
  // Il n'aurait jamais rien vu.
  @override
  void initState() {
    super.initState();
    _veille = widget.veille ?? VeilleSession(jetons: sl<TokenService>());
    _veille!.demarrer();
  }

  @override
  void dispose() {
    _veille?.arreter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.enfant;
}
