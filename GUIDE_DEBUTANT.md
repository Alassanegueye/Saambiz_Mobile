# 🧭 Guide du débutant — Fait Maison (Mobile Flutter)

Ce guide t'explique **comment l'app est organisée** et **par où commencer** pour modifier
des choses sans te perdre. Il est écrit pour quelqu'un qui découvre Flutter.

---

## 1. C'est quoi ce projet ?

Une app mobile de **boutiques / produits faits maison**, avec deux types d'utilisateurs :

- **Acheteur** (client) → parcourt et commande des produits
- **Vendeur** → gère sa boutique et ses produits

Le dossier `fait-maison-mobile` est la **partie mobile** (Flutter).
Il y a aussi `fait-maison-backend` (le serveur/API en Node) et `fait-maison-frontend` (le web).
L'app mobile **parle au backend** via des requêtes HTTP (l'adresse est dans le fichier `.env`).

---

## 2. Les notions Flutter à connaître (le minimum)

| Terme | En français simple |
|---|---|
| **Widget** | Une brique d'interface (un bouton, un texte, une page entière). Tout est widget. |
| **StatelessWidget** | Un widget qui n'évolue pas tout seul (affichage figé). |
| **StatefulWidget** | Un widget qui change au fil du temps (animation, formulaire, etc.). |
| **BLoC** | Le « cerveau » d'une page : il reçoit des **événements** et renvoie des **états**. |
| **pubspec.yaml** | La liste des dépendances (les packages installés). Comme `package.json` en Node. |
| **pub get** | La commande qui télécharge ces dépendances. |

---

## 3. La structure des dossiers

Tout le code que tu vas modifier est dans `lib/`.

```
lib/
├── main.dart                ← Point de départ de l'app (le tout premier fichier exécuté)
├── injection_container.dart ← "Branchement" de tous les services (voir §5)
│
├── core/                    ← Code PARTAGÉ par toute l'app
│   ├── theme/               ← Couleurs (app_color.dart) et thème global
│   ├── routes/              ← La liste des pages et leurs adresses (app_router.dart)
│   ├── widgets/             ← Boutons, champs de texte réutilisables
│   ├── services/            ← Gestion du token (connexion), WhatsApp...
│   ├── connection/          ← Réseau + ajout automatique du token aux requêtes
│   ├── errors/              ← Types d'erreurs
│   └── provider/            ← Gestion de la langue
│
└── features/               ← Les FONCTIONNALITÉS, une par dossier
    ├── auth/                ← Connexion / Inscription
    └── home/                ← Accueil, produits, profils (acheteur & vendeur)
```

> 💡 **Règle d'or** : une fonctionnalité = un dossier dans `features/`.
> Si tu ajoutes « les commandes », tu crées `features/commande/`.

---

## 4. Comment une fonctionnalité est découpée (très important)

Le projet suit la **Clean Architecture**. Chaque feature (`auth`, `home`) a **3 couches** :

```
features/auth/
├── presentation/   ← Ce que l'utilisateur VOIT et touche
│   ├── pages/        → Les écrans (login_page.dart, register_page.dart...)
│   ├── widgets/      → Morceaux d'écran réutilisables
│   └── bloc/         → Le cerveau (events / states / bloc)
│
├── domain/         ← Les RÈGLES MÉTIER (pur Dart, pas d'interface)
│   ├── entities/     → Les objets "propres" (ex: User)
│   ├── repositories/ → Les CONTRATS (ce qu'on PEUT faire, sans dire comment)
│   └── usecases/     → Une action précise (ex: LoginUser, RegisterUser)
│
└── data/           ← D'où viennent les DONNÉES (l'API, le téléphone)
    ├── datasources/  → Les vrais appels HTTP au backend
    ├── models/       → Comme entities, mais sait lire/écrire du JSON
    └── repositories/ → L'implémentation réelle des contrats du domain
```

### Le chemin complet d'un clic « Se connecter » 👇

```
1. login_page.dart        L'utilisateur tape ses infos et clique
        │  envoie un événement LoginRequested
        ▼
2. auth_bloc.dart         Reçoit l'événement, passe en état "AuthLoading"
        │  appelle le usecase
        ▼
3. login_user.dart        (usecase) demande au repository de connecter
        │
        ▼
4. auth_repository_impl    Implémente l'action, appelle la datasource
        │
        ▼
5. auth_remote_datasource  Fait le VRAI appel HTTP (dio.post) au backend
        │  réponse du serveur
        ▼
   Le résultat remonte en sens inverse → le bloc émet "AuthSuccess" ou "AuthFailure"
        │
        ▼
   login_page.dart écoute le bloc et réagit (affiche une erreur OU navigue)
```

> Ça paraît long, mais chaque couche a un seul rôle. **Pour modifier l'écran**, tu touches
> `presentation/`. **Pour changer l'appel au serveur**, tu touches `data/datasources/`.

---

## 5. Le fichier `injection_container.dart` (le tableau électrique)

Ce fichier **crée et relie** tous les objets au démarrage (avec le package `get_it`).
C'est lui qui dit : « le AuthBloc a besoin de LoginUser, qui a besoin du repository, etc. »

Quand tu crées une nouvelle feature, tu devras **enregistrer** ses objets ici (en copiant
le bloc `FEATURES - AUTHENTICATION` à la fin du fichier).

On récupère un objet ailleurs dans le code avec `sl<MonType>()` (sl = *service locator*).

---

## 6. Lancer l'application

```bash
cd fait-maison-mobile

flutter pub get          # 1. Installe les dépendances (à faire au début et après tout changement du pubspec)
flutter devices          # 2. Voir les appareils/émulateurs disponibles
flutter run              # 3. Lancer l'app sur l'appareil branché/émulateur
```

Pendant que `flutter run` tourne :
- Appuie sur **`r`** = *hot reload* (recharge tes changements en ~1 seconde, garde l'état)
- Appuie sur **`R`** = *hot restart* (redémarre l'app à zéro)
- Appuie sur **`q`** = quitter

> ⚠️ L'app a besoin du fichier `.env` (déjà présent) contenant `API_BASE_URL`,
> `AUTH_LOGIN_PATH`, `AUTH_REGISTER_PATH`. Si une de ces variables manque, l'app
> refuse de démarrer (voir `_validateEnvVariables()` dans `injection_container.dart`).
> Le **backend doit être lancé** pour que la connexion fonctionne.

---

## 7. Par où commencer à modifier ? (du plus simple au plus avancé)

### 🟢 Niveau 1 — Changer l'apparence (sans risque)
- **Couleurs globales** → `lib/core/theme/app_color.dart`
- **Couleurs d'un écran** : beaucoup d'écrans ont une petite classe locale `_C { ... }`
  en haut du fichier (ex: en haut de `login_page.dart`, `splash_page.dart`). Change les codes couleur là.
- **Textes affichés** → cherche le texte dans le fichier de la page et modifie-le.
- **Logo / images** → remplace les fichiers dans `assets/images/`.

### 🟡 Niveau 2 — Modifier un écran existant
- Écran de connexion → `features/auth/presentation/pages/login_page.dart`
- Écran d'inscription → `features/auth/presentation/pages/register_page.dart`
- Navigation du bas (acheteur) → `features/home/presentation/pages/acheteur/main_client_page.dart`
- Navigation du bas (vendeur) → `features/home/presentation/pages/vendeur/main_vendeur_page.dart`

### 🟠 Niveau 3 — Ajouter / changer un appel au backend
- L'URL de base et les chemins → fichier `.env`
- Le code de l'appel → `features/<feature>/data/datasources/..._remote_datasource.dart`

### 🔴 Niveau 4 — Ajouter une nouvelle fonctionnalité complète
1. Crée `features/ma_feature/` avec les 3 couches (`presentation`, `domain`, `data`).
   Le plus simple : **copie le dossier `auth/`** et adapte.
2. Ajoute la page dans `core/routes/app_router.dart` (une nouvelle `case`).
3. Enregistre les nouveaux objets dans `injection_container.dart`.
4. Si la page utilise un BLoC, ajoute-le au `MultiBlocProvider` dans `main.dart`.

---

## 8. Fichiers à connaître absolument

| Pour... | Va voir... |
|---|---|
| Comprendre le démarrage | `lib/main.dart` |
| Voir toutes les pages et leurs adresses | `lib/core/routes/app_router.dart` |
| Voir comment tout est branché | `lib/injection_container.dart` |
| Le premier écran affiché | `lib/features/auth/presentation/pages/splash_page.dart` |
| Un exemple complet de feature | tout le dossier `lib/features/auth/` |

---

## 9. Points d'attention repérés dans le code (à savoir, pas urgent)

Ces petits soucis existent déjà — utile à connaître quand tu exploreras :

1. **`splash_page.dart`** : les deux branches du `if (token...)` (lignes ~109-113) font
   exactement la même chose → l'app va **toujours** vers `login`, même si l'utilisateur
   était déjà connecté. C'est probablement à corriger un jour (rediriger vers l'accueil si connecté).
2. **Clé du token** : le splash lit la clé `'jwt_token'`, vérifie que le `TokenService`
   (`core/services/token_service.dart`) enregistre bien sous le même nom.
3. **Dossier `features/home/domain/`** : il contient des copies des fichiers de `auth`
   (`user.dart`, `login_user.dart`...). C'est probablement du code en double laissé là ;
   ne t'appuie pas dessus, le vrai `auth` est dans `features/auth/`.
4. `dotenv.load(...)` est appelé deux fois (dans `main.dart` ET `injection_container.dart`) —
   sans gravité, mais bon à savoir.

---

## 10. Conseil de méthode pour débuter

1. Lance l'app et fais-la tourner (`flutter run`).
2. Change **une couleur** dans `app_color.dart`, fais `r` (hot reload), regarde le résultat.
3. Change **un texte** sur l'écran de login, hot reload, observe.
4. Suis le « chemin d'un clic » du §4 dans le vrai code, fichier par fichier.
5. Ensuite seulement, tente d'ajouter une feature en copiant `auth/`.

Bon courage ! 🚀
