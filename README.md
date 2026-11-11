# SaamBiz — application mobile

Marketplace sénégalaise : les acheteurs trouvent des boutiques près d'eux, les
vendeurs tiennent leur boutique, leur catalogue, leurs commandes et leur site
public depuis leur téléphone.

Flutter **3.47.6** / Dart **3.13.5**. API : `Saambiz_Back`
(`https://api.saambiz.com/saambiz/v1`).

---

## Ce qu'il faut sur le poste

| | iOS | Android |
|---|---|---|
| Flutter | 3.47.6 | 3.47.6 |
| Xcode | oui | — |
| JDK | — | **17 ou plus** (pour exécuter Gradle) |
| Android SDK | — | plateforme 36, build-tools, NDK 28.2.13676358 |

Le JDK 17 n'est pas le même réglage que `sourceCompatibility = 11` dans
`android/app/build.gradle.kts` : celui-ci dit en quel niveau de langage le
code Kotlin/Java de l'application est compilé, le JDK dit avec quoi Gradle
lui-même tourne. Android Gradle Plugin 8.11 exige 17 pour tourner.

Si `java -version` ne répond rien, rien ne se construira côté Android. Le plus
simple sur macOS :

```bash
brew install --cask temurin@17 android-commandlinetools
```

Puis déclarer le SDK (Gradle le cherche dans cet ordre : `local.properties`,
`ANDROID_HOME`, emplacement par défaut) :

```bash
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" "ndk;28.2.13676358"
```

`flutter doctor --android-licenses` accepte les licences, sans quoi la
construction s'arrête dessus.

---

## Configuration : tout passe par `--dart-define`

Rien de sensible n'est écrit dans le dépôt. `lib/core/config/env.dart` lit
chaque valeur à la compilation, et **ignore le `.env` en release** — ce fichier
est un confort pour les postes de développement, il part dans le paquet comme
asset, et l'adresse d'émulateur qui y traîne ferait appeler le vide à une
application publiée.

| Variable | Rôle | Sans elle |
|---|---|---|
| `ENVIRONNEMENT` | `prod` ou `dev` | `dev` : pas de contrôle de cohérence, pas d'épinglage |
| `API_BASE_URL` | adresse de l'API | la production, en dur par défaut |
| `GOOGLE_SERVER_CLIENT_ID` | client OAuth « Application Web » — *sans objet aujourd'hui, voir plus bas* | bouton Google masqué sur Android |
| `GOOGLE_IOS_CLIENT_ID` | client OAuth iOS — *idem* | bouton Google masqué sur iOS |
| `URL_CONFIG_APP` | version minimale exigée, maintenance | contrôle de mise à jour inactif |
| `EMPREINTES_CERTIFICAT` | épinglage TLS (`sha256/…`) | validation système seule |

`ENVIRONNEMENT=prod` ne fait pas que changer une étiquette : il active
`Env.verifier()`, qui refuse de démarrer si l'adresse de l'API est en HTTP
simple ou pointe sur une adresse locale. C'est le garde-fou contre la version
publiée qui appelle le poste du développeur.

---

## Construire la version Android pour Google Play

```bash
flutter clean
flutter pub get
flutter analyze lib test
flutter test
flutter build appbundle --release \
  --dart-define=ENVIRONNEMENT=prod \
  --dart-define=API_BASE_URL=https://api.saambiz.com/saambiz/v1 \
  --obfuscate --split-debug-info=build/symboles-android
```

Pas de `GOOGLE_SERVER_CLIENT_ID` : les boutons de connexion sociale ne sont
plus affichés (voir « Connexion Google et Apple — débranchée »). Le jour où ils
reviennent, c'est la ligne à ajouter ici.

Le résultat : `build/app/outputs/bundle/release/app-release.aab`.

**Gardez le dossier `build/symboles-android`** de chaque version publiée, hors
du dépôt. Sans lui, les rapports de plantage de cette version restent des
adresses mémoire illisibles — et les symboles d'un autre build ne les
traduisent pas.

Un `.aab` et non un `.apk` : Google Play n'accepte plus que l'App Bundle pour
une nouvelle application. Pour essayer sur un téléphone branché en USB,
`flutter build apk --release` avec les mêmes options, ou `flutter install`.

### Vérifier la signature avant de téléverser

```bash
jarsigner -verify -verbose:summary build/app/outputs/bundle/release/app-release.aab
```

Et le contenu du certificat — l'alias doit être le vôtre, pas `androiddebugkey` :

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Un `.aab` signé avec la clé de débogage se construit sans erreur et n'est
refusé qu'au téléversement, après le temps d'envoi. Gradle affiche désormais un
encadré d'avertissement quand `android/key.properties` manque.

---

## La clé de signature

Elle n'est pas dans le dépôt, et ne doit jamais y entrer : qui la possède peut
fabriquer une mise à jour que les téléphones accepteront comme la vôtre.
`android/.gitignore` écarte `key.properties`, `*.jks` et `*.keystore`, et un
test le vérifie (`test/android/config_release_test.dart`).

La procédure est dans `android/key.properties.example`. En résumé :

```bash
keytool -genkey -v -keystore ~/cles-android/saambiz-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
cp android/key.properties.example android/key.properties   # puis remplir
```

**Sauvegardez le `.jks` et ses mots de passe ailleurs que sur ce Mac.** Avec
Play App Signing (activé par défaut pour toute nouvelle application), cette clé
n'est que la clé de *téléversement* : Google garde la vraie clé de signature et
peut vous réinitialiser l'autre en cas de perte. Sans Play App Signing, la
perdre interdit toute mise à jour — il faut republier sous un autre
`applicationId`, et les utilisateurs installés ne suivent pas.

---

## Notifications push

`firebase_core` + `firebase_messaging` pour l'acheminement,
`flutter_local_notifications` pour l'affichage quand l'application est ouverte.
Le canal Android `saambiz_push_channel` est nommé en trois endroits — le
manifeste, `lib/core/services/fcm_service.dart` et `push.service.js` côté
serveur ; un test vérifie que les deux premiers concordent.

Les deux fichiers de configuration Firebase **ne sont pas dans le dépôt** :

| Plateforme | Fichier | Emplacement |
|---|---|---|
| Android | `google-services.json` | `android/app/` |
| iOS | `GoogleService-Info.plist` | `ios/Runner/` |

Tant qu'ils manquent, l'application se construit et tourne normalement : le
plugin Gradle n'est appliqué que si le fichier existe, et
`initialiserFirebase()` encaisse l'échec. Simplement, aucune notification
n'arrive.

Les télécharger : [console Firebase](https://console.firebase.google.com) →
projet SaamBiz → ⚙️ Paramètres du projet → section *Vos applications* →
l'application Android `com.saambiz.app` → *google-services.json*.

---

## Connexion Google et Apple — débranchée

**Il n'y a rien à configurer aujourd'hui.** Les boutons « Continuer avec
Google » et « Continuer avec Apple » ne sont plus affichés : le commit
`3a4cfd2` (10/11/2026) a retiré `BoutonsConnexionSociale` de
`login_page.dart`, et aucune autre page ne l'utilise. Rien n'émet donc
`ConnexionSocialeDemandee`.

Tout le reste de la chaîne est encore là et fonctionne : le widget, le
datasource (`ConnexionSocialeSource`), l'événement du bloc, la route
`/auth/social` côté API. **Dormant, pas supprimé.**

Pour le rebrancher, il suffit de remettre le widget dans `login_page.dart`.
Il faut alors, et alors seulement :

1. **`GOOGLE_SERVER_CLIENT_ID`** à la compilation (client OAuth « Application
   Web ») pour Android, **`GOOGLE_IOS_CLIENT_ID`** pour iOS. Sans eux le bouton
   reste masqué — `ConnexionSocialeSource.googleDisponible` le vérifie, pour ne
   pas proposer une connexion qui ne peut pas aboutir.
2. **L'empreinte SHA-1** du certificat de signature, déclarée comme client
   OAuth Android pour le paquet `com.saambiz.app` — dans **le projet Google
   Cloud `402258191800`**, celui qui porte déjà le client iOS, et **non** dans
   le projet Firebase (`994725734865`) qui ne sert qu'aux notifications. Ce
   sont deux projets distincts, et c'est le piège.

   ```bash
   keytool -list -v -keystore ~/cles-android/saambiz-upload.jks -alias upload
   ```

   Il y en a **deux à déclarer** : celle de votre clé de téléversement, et
   celle de la clé que Google utilise pour signer ce qu'il distribue (Play
   Console → Configuration → Intégrité de l'application). Avec la première
   seule, la connexion marche depuis votre `.aab` local et échoue pour tout
   utilisateur venu du Play Store.

La connexion Apple n'est de toute façon proposée que sur iPhone : sur Android
elle passerait par un détour web qui n'est pas mis en place
(`ConnexionSocialeSource.appleDisponible`). Conséquence utile tant que les deux
boutons restent débranchés : la règle 4.8 de l'App Store, qui impose « Se
connecter avec Apple » dès qu'une connexion tierce est proposée, ne s'applique
pas.

---

## Ce que la version Android déclare

Lisible dans `android/app/src/main/AndroidManifest.xml`, et figé par
`test/android/config_release_test.dart` :

| | |
|---|---|
| `applicationId` / `namespace` | `com.saambiz.app` |
| `minSdk` | 24 (Android 7.0) |
| `targetSdk` / `compileSdk` | 36 |
| Trafic en clair | refusé (réautorisé pour les seuls builds debug) |
| Sauvegarde système | désactivée |
| R8 | réduction + obfuscation + `shrinkResources` |

Nous en déclarons **quatre** : `INTERNET`, `POST_NOTIFICATIONS`,
`ACCESS_COARSE_LOCATION` et `ACCESS_FINE_LOCATION`. Les deux dernières servent
aux boutiques proches, et un refus n'empêche rien. Il n'y a **pas** de
permission caméra : `image_picker` passe par l'application appareil photo du
système, qui n'en demande pas.

Mais le paquet final en porte **neuf** : les plugins ajoutent les leurs à la
fusion, et c'est le manifeste fusionné qui compte pour Google Play. Les voir
pour de vrai, après un build :

```bash
grep -oE 'android:name="android\.permission\.[A-Z_]+"' \
  build/app/intermediates/merged_manifest/release/*/AndroidManifest.xml | sort -u
```

| Ajoutée par | Permissions |
|---|---|
| `firebase_messaging` | `WAKE_LOCK`, `ACCESS_NETWORK_STATE`, `c2dm.permission.RECEIVE` |
| `flutter_local_notifications` | `VIBRATE` |
| `androidx.biometric` (via `flutter_secure_storage`) | `USE_BIOMETRIC`, `USE_FINGERPRINT` |

Aucune n'est sensible au sens de Google Play : elles ne déclenchent pas de
demande d'autorisation et n'appellent aucune justification. `USE_FINGERPRINT`
est dépréciée et ne vient que de la compatibilité d'`androidx.biometric` avec
les anciennes versions. Le rapport qui dit d'où vient chaque ligne est écrit à
chaque build dans
`build/app/intermediates/manifest_merge_blame_file/release/`.

Le bloc `<queries>` déclare les liens `https` parce que depuis Android 11 une
application ne voit plus les autres : sans cette ligne, `canLaunchUrl`
répondait toujours faux et « Contacter sur WhatsApp » prétendait que WhatsApp
n'était pas installé.

---

## Développement

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/saambiz/v1
```

`10.0.2.2` est l'alias de la machine hôte vu depuis l'émulateur Android. Sur un
téléphone physique, mettez l'adresse IP du poste. Le manifeste de debug
réautorise le trafic en clair pour ce cas précis, et pour lui seul.

```bash
flutter test                      # 192 tests
flutter analyze lib test
```

## Documents

- `PRIVACY_POLICY.md` — politique de confidentialité. **À publier sur une page
  web accessible** et à renseigner dans Play Console et l'App Store ; elle
  comporte encore des `[À COMPLÉTER]` (raison sociale, date, e-mail).
- `AUDIT-API.md` — état de l'intégration des routes du backend.
