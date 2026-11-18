import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saambiz/core/services/token_service.dart';
import 'package:saambiz/core/services/veille_session.dart';

/// Le guet qui ferme la session au retour, après un long silence.
///
/// Le serveur tranche, et c'est lui qui fait foi : un renouvellement demandé
/// après trois heures est refusé. Ce guet-ci sert au confort — sans lui,
/// revenir sur une application restée en arrière-plan affichait le compte une
/// seconde, le temps qu'une requête parte, revienne en 401 et renvoie à la
/// connexion. L'utilisateur voyait son compte s'ouvrir puis se fermer.
///
/// Ce qui est vérifié ici : la durée annoncée, et le fait que le guet
/// s'attache et se détache proprement à la durée de vie de l'application —
/// un observateur oublié continue de recevoir les changements d'état après
/// la disparition de son écran.

/// Un coffre en mémoire : les tests ne touchent pas le trousseau du
/// téléphone, qui n'existe pas ici.
class _CoffreFactice extends FlutterSecureStorage {
  final Map<String, String> _valeurs;
  const _CoffreFactice(this._valeurs);

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _valeurs[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _valeurs.remove(key);

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _valeurs.remove(key);
    } else {
      _valeurs[key] = value;
    }
  }
}

/// Une horloge que le test fait avancer à sa guise.
class _Horloge {
  DateTime maintenant = DateTime(2026, 11, 18, 9);
  DateTime lire() => maintenant;
  void avancer(Duration d) => maintenant = maintenant.add(d);
}

VeilleSession _guet({bool connecte = true, _Horloge? horloge}) => VeilleSession(
  jetons: TokenService(
    secureStorage: _CoffreFactice(connecte ? {'jwt_token': 'jeton'} : {}),
  ),
  horloge: horloge?.lire,
);

/// Pose l'écran sous surveillance, puis joue une absence de [absence].
Future<VeilleSession> _absence(
  WidgetTester t,
  Duration absence, {
  bool connecte = true,
}) async {
  final horloge = _Horloge();
  final veille = _guet(connecte: connecte, horloge: horloge);
  await t.pumpWidget(
    SousVeille(
      veille: veille,
      enfant: const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.shrink(),
      ),
    ),
  );

  veille.didChangeAppLifecycleState(AppLifecycleState.paused);
  // L'horloge avance plutôt que le test d'attendre trois heures.
  horloge.avancer(absence);
  veille.didChangeAppLifecycleState(AppLifecycleState.resumed);
  await t.pumpAndSettle();
  return veille;
}

void main() {
  test('la durée est de trois heures, comme le serveur', () {
    // Si les deux divergeaient, celle du serveur gagnerait : il refuserait
    // le renouvellement que ce guet aurait laissé passer.
    expect(VeilleSession.duree, const Duration(hours: 3));
  });

  testWidgets('le guet observe dès la pose de l’écran', (t) async {
    // Il était construit en `late final`, donc évalué à sa première lecture
    // — qui n'arrivait qu'au `dispose`. Le guet ne commençait à observer
    // qu'au moment de s'arrêter : il n'aurait jamais rien vu.
    final veille = _guet();
    await t.pumpWidget(
      SousVeille(
        veille: veille,
        enfant: const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      ),
    );

    expect(veille.observe, isTrue);
  });

  testWidgets('une courte absence ne ferme rien', (t) async {
    // Répondre à un message, prendre un appel, consulter autre chose.
    final veille = await _absence(t, const Duration(minutes: 20));

    expect(await veille.jetons.isAuthenticated, isTrue);
  });

  testWidgets('trois heures d’absence ferment la session', (t) async {
    final veille = await _absence(t, const Duration(hours: 3, minutes: 1));

    expect(await veille.jetons.isAuthenticated, isFalse);
  });

  testWidgets('un visiteur n’est pas renvoyé à la connexion', (t) async {
    // Sans session, il n'y a rien à fermer — et surtout rien qui justifie
    // d'interrompre quelqu'un qui parcourait le catalogue.
    final veille = await _absence(t, const Duration(hours: 5), connecte: false);

    expect(await veille.jetons.isAuthenticated, isFalse);
  });

  testWidgets('revenir sans être parti ne ferme rien', (t) async {
    // `resumed` sans `paused` : le sélecteur d'applications, une bannière.
    final veille = _guet();
    await t.pumpWidget(
      SousVeille(
        veille: veille,
        enfant: const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      ),
    );

    veille.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await t.pumpAndSettle();

    expect(await veille.jetons.isAuthenticated, isTrue);
  });

  testWidgets('et se détache quand elle disparaît', (t) async {
    final veille = _guet();
    await t.pumpWidget(
      SousVeille(
        veille: veille,
        enfant: const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      ),
    );

    // Remplacer l'arbre détruit l'état, donc retire l'observateur. S'il
    // restait attaché, les changements d'état continueraient de l'atteindre
    // et il pourrait renvoyer à la connexion depuis un écran disparu.
    await t.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.shrink(),
      ),
    );

    expect(find.byType(SousVeille), findsNothing);
    expect(veille.observe, isFalse);
  });
}
