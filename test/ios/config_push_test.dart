import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ce que la version iOS doit porter pour que les notifications arrivent.
///
/// Rien de tout cela ne vit dans du Dart : c'est le projet Xcode, le fichier
/// d'habilitations et l'Info.plist. L'analyseur ne les voit pas, aucun test
/// d'interface ne les traverse, et le manque ne produit aucune erreur — juste
/// un iPhone qui ne sonne jamais.
///
/// Chaque attente ci-dessous correspond à un défaut réellement rencontré sur
/// ce projet.
void main() {
  late String projet;
  late String habilitations;
  late String infoPlist;

  setUpAll(() {
    projet = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    habilitations = File('ios/Runner/Runner.entitlements').readAsStringSync();
    infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
  });

  group('Configuration Firebase embarquée', () {
    test('GoogleService-Info.plist existe et porte le bon projet', () {
      final fichier = File('ios/Runner/GoogleService-Info.plist');
      expect(fichier.existsSync(), isTrue);

      final contenu = fichier.readAsStringSync();
      // Un plist du MAUVAIS projet Firebase s'initialise sans broncher et
      // n'atteint jamais les téléphones de celui-ci.
      expect(contenu, contains('saambiz-ca926'));
      // Le bundle identifier doit correspondre, sinon Firebase refuse.
      expect(contenu, contains('com.saambiz.app'));
    });

    test('il est DÉCLARÉ dans la cible Runner, pas seulement posé là', () {
      // Le défaut : le fichier était bien dans ios/Runner/, et absent du
      // projet Xcode. Or seuls les fichiers listés dans la phase « Copy
      // Bundle Resources » entrent dans l'application ; Flutter ne touche
      // pas aux ressources iOS. Résultat vérifié sur le bundle construit :
      // aucun GoogleService-Info.plist dedans, donc
      // `Firebase.initializeApp()` lève, FcmService abandonne en silence
      // (« Firebase non configuré »), et AUCUN iPhone ne reçoit de push —
      // clé APNs ou pas.
      expect(
        projet,
        contains('GoogleService-Info.plist'),
        reason: 'le plist n’est pas référencé par le projet Xcode',
      );

      // Et précisément dans la phase Resources de la cible Runner.
      final phase = RegExp(
        r'97C146EC1CF9000F007C117D /\* Resources \*/ = \{.*?\};',
        dotAll: true,
      ).firstMatch(projet);
      expect(phase, isNotNull, reason: 'phase Resources de Runner introuvable');
      expect(
        phase!.group(0),
        contains('GoogleService-Info.plist'),
        reason: 'déclaré au projet mais pas copié dans le bundle',
      );
    });
  });

  group('Habilitations APNs', () {
    test('aps-environment est déclaré', () {
      // Sans cette habilitation, iOS ne délivre aucun jeton APNs : Firebase
      // n'a rien à qui parler et le serveur reçoit
      // « messaging/third-party-auth-error » pour chaque iPhone.
      expect(habilitations, contains('aps-environment'));
      expect(habilitations, contains('<string>production</string>'));
    });

    test('le fichier d’habilitations est bien relié aux trois configurations', () {
      // Debug, Release et Profile : un fichier d'habilitations relié à une
      // seule configuration laisse les deux autres sans push, sans erreur.
      final liens = RegExp(
        r'CODE_SIGN_ENTITLEMENTS = Runner/Runner\.entitlements;',
      ).allMatches(projet);
      expect(liens.length, greaterThanOrEqualTo(3));
    });
  });

  group('Réveil en arrière-plan', () {
    test('remote-notification est déclaré dans Info.plist', () {
      // Nécessaire pour qu'iOS réveille l'application sur une notification
      // silencieuse et pour que FCM remette la main au code.
      expect(infoPlist, contains('UIBackgroundModes'));
      expect(infoPlist, contains('remote-notification'));
    });
  });
}
