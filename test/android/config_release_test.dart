import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ce que la version Android doit porter pour être publiable.
///
/// Ces réglages ne vivent pas dans du Dart : ils sont dans le manifeste et
/// dans Gradle, donc l'analyseur ne les voit pas et aucun test d'interface ne
/// les traverse. Ils se perdent en silence — à une fusion, à un
/// `flutter create` relancé pour régénérer un dossier, à un copier-coller
/// depuis un autre projet —, et la perte ne se remarque qu'après le
/// téléversement, ou pire, sur le téléphone d'un client.
///
/// D'où ces lectures de fichiers. Chaque attente ci-dessous correspond à un
/// défaut réellement rencontré sur ce projet.
void main() {
  late String gradleApp;
  late String manifestePrincipal;
  late String manifesteDebug;
  late String fcmDart;

  setUpAll(() {
    gradleApp = File('android/app/build.gradle.kts').readAsStringSync();
    manifestePrincipal = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    manifesteDebug = File(
      'android/app/src/debug/AndroidManifest.xml',
    ).readAsStringSync();
    fcmDart = File('lib/core/services/fcm_service.dart').readAsStringSync();
  });

  group('Identité de l’application', () {
    test('applicationId et namespace valent com.saambiz.app', () {
      // Définitif dès la première mise en ligne : Google n'autorise aucun
      // changement ensuite. Il a valu « com.faitmaison.app », hérité de
      // l'ancien nom du projet.
      expect(gradleApp, contains('applicationId = "com.saambiz.app"'));
      expect(gradleApp, contains('namespace = "com.saambiz.app"'));
    });

    test('le nom affiché sous l’icône est SaamBiz', () {
      expect(manifestePrincipal, contains('android:label="SaamBiz"'));
    });
  });

  group('Réglages de la release', () {
    test('R8 réduit et obscurcit le code', () {
      expect(gradleApp, contains('isMinifyEnabled = true'));
      expect(gradleApp, contains('isShrinkResources = true'));
    });

    test('les règles de conservation R8 sont référencées', () {
      expect(gradleApp, contains('proguard-rules.pro'));
      expect(File('android/app/proguard-rules.pro').existsSync(), isTrue);
    });

    test('le modèle de signature est documenté et le vrai fichier ignoré', () {
      // Sans keystore, la release est signée avec la clé de débogage et Google
      // Play la refuse — mais seulement au téléversement.
      expect(File('android/key.properties.example').existsSync(), isTrue);
      final ignore = File('android/.gitignore').readAsStringSync();
      expect(ignore, contains('key.properties'));
      expect(ignore, contains('*.jks'));
      // Et le vrai fichier ne doit jamais être suivi.
      final suivi = Process.runSync('git', [
        'ls-files',
        'android/key.properties',
      ]).stdout.toString().trim();
      expect(suivi, isEmpty, reason: 'android/key.properties est versionné !');
    });
  });

  group('Permissions et réseau', () {
    test('INTERNET est déclarée dans le manifeste principal', () {
      // Les manifestes debug et profile la portent aussi, mais eux seuls :
      // sans cette ligne, la version publiée ne fait AUCUN appel réseau.
      expect(
        manifestePrincipal,
        contains('android.permission.INTERNET'),
      );
    });

    test('les notifications Android 13+ sont déclarées', () {
      expect(
        manifestePrincipal,
        contains('android.permission.POST_NOTIFICATIONS'),
      );
    });

    test('le trafic en clair est refusé en production', () {
      expect(
        manifestePrincipal,
        contains('android:usesCleartextTraffic="false"'),
      );
    });

    test('le développement le réautorise pour lui seul', () {
      // `tools:replace` sur le manifeste debug : l'émulateur appelle
      // http://10.0.2.2, sans certificat.
      expect(manifesteDebug, contains('android:usesCleartextTraffic="true"'));
      expect(
        manifesteDebug,
        contains('tools:replace="android:usesCleartextTraffic"'),
      );
    });

    test('la sauvegarde système est désactivée', () {
      // Les sauvegardes Android recopieraient les données de l'application
      // ailleurs, jetons de session compris.
      expect(manifestePrincipal, contains('android:allowBackup="false"'));
    });

    test('aucune permission sensible non utilisée', () {
      // Chaque permission sensible doit se justifier devant Google Play.
      // Celles-ci n'ont aucun code derrière elles dans ce projet.
      for (final permission in const [
        'android.permission.CAMERA',
        'android.permission.RECORD_AUDIO',
        'android.permission.READ_CONTACTS',
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.WRITE_EXTERNAL_STORAGE',
        'android.permission.QUERY_ALL_PACKAGES',
        'android.permission.ACCESS_BACKGROUND_LOCATION',
      ]) {
        expect(
          manifestePrincipal,
          isNot(contains(permission)),
          reason: '$permission est déclarée sans usage dans le code',
        );
      }
    });
  });

  group('Visibilité des autres applications (Android 11+)', () {
    test('les liens web sont déclarés, sinon canLaunchUrl répond faux', () {
      // Sans cette déclaration, « Contacter sur WhatsApp » affichait
      // « vérifiez que l'application est installée » sur tout Android 11 ou
      // plus récent, WhatsApp installé ou non : l'API renvoie une adresse
      // https://wa.me/… et `canLaunchUrl` ne voyait aucun navigateur.
      final queries = RegExp(
        r'<queries>(.*?)</queries>',
        dotAll: true,
      ).firstMatch(manifestePrincipal);
      expect(queries, isNotNull, reason: 'aucun bloc <queries>');

      final contenu = queries!.group(1)!;
      expect(contenu, contains('android.intent.action.VIEW'));
      expect(contenu, contains('android:scheme="https"'));
    });

    test('rien ne demande la liste complète des applications', () {
      // QUERY_ALL_PACKAGES est une permission à part, que Google Play fait
      // justifier et refuse dans la plupart des cas.
      expect(manifestePrincipal, isNot(contains('QUERY_ALL_PACKAGES')));
    });
  });

  group('Canal de notification', () {
    test('le manifeste et le code Dart nomment le même canal', () {
      // Trois endroits portent cet identifiant : ce manifeste, fcm_service.dart
      // et le serveur (push.service.js). S'ils divergent, Android crée un
      // second canal muet et la notification n'apparaît jamais — sans erreur.
      final duManifeste = RegExp(
        r'default_notification_channel_id"\s*\n?\s*android:value="([^"]+)"',
      ).firstMatch(manifestePrincipal);
      expect(duManifeste, isNotNull, reason: 'canal absent du manifeste');

      final duDart = RegExp(
        r"_kCanalId\s*=\s*'([^']+)'",
      ).firstMatch(fcmDart);
      expect(duDart, isNotNull, reason: 'canal absent de fcm_service.dart');

      expect(duManifeste!.group(1), duDart!.group(1));
    });
  });

  group('L’allure de la notification', () {
    test('la petite icône n’est pas l’icône de lancement', () {
      // Depuis Android 5, le système ne garde que le CANAL ALPHA de la petite
      // icône : la forme est remplie d'une couleur unie et le dessin est
      // perdu. `@mipmap/ic_launcher` est un carré plein de marine — il donnait
      // donc un carré blanc dans la barre d'état, le « blob » bien connu.
      final icone = RegExp(
        r'default_notification_icon"\s*\n?\s*android:resource="([^"]+)"',
      ).firstMatch(manifestePrincipal);
      expect(icone, isNotNull, reason: 'icône de notification absente');
      expect(
        icone!.group(1),
        isNot('@mipmap/ic_launcher'),
        reason: 'une icône de lancement pleine devient un carré blanc',
      );
      expect(icone.group(1), '@drawable/ic_launcher_foreground');

      // Et le fichier existe vraiment, dans plusieurs densités.
      final densites = Directory('android/app/src/main/res')
          .listSync()
          .whereType<Directory>()
          .where(
            (d) => File(
              '${d.path}/ic_launcher_foreground.png',
            ).existsSync(),
          );
      expect(densites.length, greaterThanOrEqualTo(4));
    });

    test('la teinte de la notification est déclarée', () {
      expect(manifestePrincipal, contains('default_notification_color'));
      final couleurs = File(
        'android/app/src/main/res/values/colors.xml',
      ).readAsStringSync();
      expect(couleurs, contains('couleur_notification'));
    });

    test('l’image est affichée aussi quand l’application est ouverte', () {
      // `android.notification.imageUrl` envoyé par le serveur n'est honoré
      // que lorsque le SYSTÈME dessine la notification — application fermée
      // ou en arrière-plan. Au premier plan, c'est l'application qui dessine,
      // et sans style « grande image » le logo de la boutique disparaissait.
      expect(fcmDart, contains('BigPictureStyleInformation'));
      expect(fcmDart, contains('ByteArrayAndroidBitmap'));
      // L'image vient de la clé `image`, celle que push.service.js ajoute.
      expect(fcmDart, contains("donnees['image']"));
    });

    test('les trois états de réception sont câblés', () {
      // Application ouverte : c'est nous qui affichons.
      expect(fcmDart, contains('FirebaseMessaging.onMessage'));
      // Application en arrière-plan, notification touchée.
      expect(fcmDart, contains('onMessageOpenedApp'));
      // Application lancée DEPUIS la notification, après avoir été fermée.
      expect(fcmDart, contains('getInitialMessage'));
      // Et le gestionnaire d'arrière-plan, qui doit rester de haut niveau.
      expect(fcmDart, contains("@pragma('vm:entry-point')"));
      expect(fcmDart, contains('onBackgroundMessage'));
    });
  });
}
