# Audit d'intégration des API — backend SaamBiz ↔ application mobile

Fait le 6 novembre 2026, sur `Saambiz_Back` à `e3ce0c6` et `Saambiz_Mobile` à
`4d03a7d` (corrections commitées dans `bfaa4cd`).

Méthode : extraction automatique des 208 routes Express du backend, extraction
de tous les appels Dio du mobile (constantes **et** chaînes littérales),
rapprochement route par route, puis lecture des contrôleurs et des modèles pour
les flux principaux. Les scripts d'extraction sont dans `/tmp/saambiz-audit/`.

---

## 1. Surface backend destinée au mobile

| Ensemble | Routes | Destinées au mobile |
|---|---:|---|
| Total backend | 208 | — |
| `/admin/*` et `/admin/rbac/*` | 78 | non — tableau de bord web |
| `/vitrine/*` | 5 | non — site public des boutiques |
| Webhooks paiement | 2 | non — appelés par Orange et Wave |
| **Reste** | **123** | **oui** |

Préfixe : `/saambiz/v1`. L'alias historique `/saambiz` (sans version) reste
servi avec un en-tête `Deprecation`. Le mobile vise `/saambiz/v1` via
`API_BASE_URL`.

---

## 2. API correctement intégrées — **CONFORME**

97 des 123 routes sont consommées, avec la bonne méthode HTTP et un modèle qui
correspond à la réponse. Par domaine :

| Domaine | Routes | Statut |
|---|---|---|
| **Authentification** | `POST /auth/login`, `/auth/register`, `/auth/inscription/envoyer-code`, `/auth/inscription/verifier-code`, `/auth/verify-email`, `/auth/logout`, `/auth/refresh` | CONFORME |
| **Compte** | `GET`/`DELETE /account/me`, `PUT /account/modifier-profil`, `PUT /account/change-password`, `POST /account/forgot-password`, `POST /account/reset-password` | CONFORME |
| **Catalogue public** | `GET /catalogue/produits`, `/catalogue/produits/:id`, `/catalogue/promotions`, `/catalogue/boutiques`, `/catalogue/boutiques/:id` | CONFORME — **testé en direct** |
| **Catégories** | `GET /categories`, `GET /categories/:id/boutiques` | CONFORME — **testé en direct** |
| **Acheteur** | `liste-produits`, `liste-boutiques`, `rechercher-produit-categorie`, `filtrer-produit-ville`, `liste-produit-par-boutique/:id`, `contacter-vendeur-par-whatsapp/:id`, `accueil-personnalise`, `accueil-section/:cle`, `GET`/`PUT preferences` | CONFORME |
| **Commandes** | `POST`/`GET /commandes`, `GET /commandes/:id`, `GET /commandes/vendeur`, `PUT /:id/annuler`, `POST /:id/payer`, `PATCH /:id/statut`, `POST /:id/demande-retour` | CONFORME |
| **Favoris** | les 5 routes | CONFORME |
| **Messagerie** | les 5 routes | CONFORME |
| **Notifications** | les 4 routes | CONFORME |
| **Promotions** | `actives`, `GET`/`POST /promotions`, `POST /campagne`, `PUT`/`DELETE /:id` | CONFORME |
| **Signalements** | `POST /signalements`, `GET /mes-signalements` | CONFORME |
| **Paiement** | `POST /paiement/payer`, `GET /paiement`, `GET /paiement/:id` | CONFORME |
| **Vendeur — produits** | `liste-produits`, `ajout-produit`, `modifier-produit/:id`, `supprimer-produit/:id`, `produit/:id/disponibilite`, `/dupliquer`, `/images` (POST et DELETE), `recherche-produits` | CONFORME |
| **Vendeur — boutique** | `ma-boutique`, `creer-boutique`, `modifier-boutique`, `boutique/pause`, `boutique/reactiver` | CONFORME |
| **Vendeur — vitrine** | `vitrine/secteurs`, `vitrine/analyser-logo`, `vitrine/generer`, `GET`/`PUT ma-vitrine` | CONFORME |
| **Vendeur — abonnement** | `mon-abonnement`, `initier-renouvellement`, `historique-paiements` | CONFORME |
| **Vendeur — statistiques** | `dashboard`, `statistiques`, `statistiques-vues`, `nombre-produit`, `nombre-produit-categorie`, `abonnes` | CONFORME |
| **Avis** | `GET /avis/boutique/:id`, `POST /avis` | CONFORME |

**Aucune divergence de méthode HTTP n'a été trouvée.** Les cas à risque ont été
vérifiés un par un : `PATCH` sur `/commandes/:id/statut`, `/favoris/:id/cloche`,
`/vendeur/produit/:id/disponibilite`, `/vendeur/boutique/pause|reactiver` ;
`PUT` sur `/commandes/:id/annuler`, `/acheteurs/preferences`,
`/notifications/toutes-lues` ; `DELETE` sur `/device-token/unregister` et
`/account/me`.

**Aucun appel mobile ne vise une route inexistante.**

---

## 3. API non intégrées — **NON INTÉGRÉE**

26 routes existent côté backend sans être appelées par le mobile. Trois
catégories.

### a) Corrigées par cet audit — désormais intégrées

| Route | Conséquence de l'absence |
|---|---|
| `GET /prix-abonnement` | le prix n'était connu que du serveur → le renouvellement partait avec `montant: 0`, rejeté |
| `GET /app/config` | les mises en maintenance et versions minimales n'atteignaient pas les téléphones |
| `POST /acheteurs/produit/:id/vue` | « Visites » restait à 0 chez tous les vendeurs, le tri `populaires` sans effet |

### b) Fonctionnalités d'accueil doublonnées (12 routes)

`GET /acheteurs/accueil`, `/decouverte`, `/produits`, `/produits-tendance`,
`/nouvelles-boutiques`, `/boutiques-verifiees`, `/promotions-actives`,
`/recherche`, `/boutiques-proches`, `/boutique/:id`, `/mon-tableau-de-bord`,
`/mes-conversations`.

Le mobile passe par `accueil-personnalise`, `accueil-section/:cle` et
`/catalogue/*`, qui couvrent les mêmes besoins. **Aucune correction faite** :
ce sont des routes redondantes côté backend, pas un manque côté mobile. Elles
méritent d'être retirées du backend plutôt qu'intégrées.

### c) Fonctionnalités réellement absentes de l'application (11 routes)

| Route | Ce qui manque dans l'app |
|---|---|
| `POST /device-token/register`, `DELETE /unregister` | déclarées et codées, **jamais appelées** : il n'y a aucun SDK push (ni Firebase ni APNs) dans le projet |
| `GET /vendeur/statut-verification`, `POST /vendeur/soumettre-verification` | le vendeur ne peut pas demander le badge « Boutique vérifiée » depuis le mobile |
| `GET /vendeur/ma-vitrine/apercu` | pas d'aperçu du site avant publication |
| `DELETE /vendeur/ma-vitrine` | le vendeur ne peut pas supprimer son site |
| `GET /vendeur/abonnes/:id`, `/vendeur/mes-conversations` | détail d'un abonné, liste de conversations vendeur |
| `GET /avis/boutique/:id/mon-avis`, `DELETE /avis/boutique/:id` | l'acheteur ne peut ni relire ni retirer son avis |
| `GET /categories/:id` | fiche d'une catégorie seule |
| `POST /auth/resend-verification`, `POST /auth/changer-mot-de-passe` | doublons des routes déjà utilisées |

Aucune n'a été intégrée : ce sont des **fonctionnalités à décider**, pas des
anomalies. Les intégrer demande des écrans, pas une correction de plomberie.

---

## 4. Incohérences détectées entre requêtes et réponses

| # | Incohérence | Gravité | Statut |
|---|---|---|---|
| 1 | `montant ?? 0` envoyé à `POST /paiement/payer`, refusé par le backend (`montant <= 0`) | **bloquante** | corrigée |
| 2 | `transactionId` lu dans la réponse de `/paiement/payer`, que le backend ne renvoie pas | cosmétique | documentée, non corrigée (valeur toujours nulle, sans effet) |
| 3 | `AuthEndpoints.resendVerification` et `ProduitEndpoints.produit(id)` déclarées, jamais appelées | propreté | constante morte retirée |
| 4 | Page d'aide annonçant « Free Money et les cartes bancaires » alors que le backend n'accepte que `orange_money` et `wave` | **trompeuse** | corrigée |

Les charges utiles ont été vérifiées contre les schémas Joi du backend pour
`creerCommande`, `payerCommande`, `changerStatut`, `signalement`, `promotion`,
`message` et `account` : **elles correspondent**, champs obligatoires et
facultatifs compris. Le multipart de `ajout-produit` et `vitrine/analyser-logo`
correspond également aux champs attendus par Multer.

---

## 5. Gestion des erreurs et des validations

**Ce qui allait déjà bien.** L'intercepteur Dio (`injection_container.dart`)
renouvelle le jeton sur un 401, rejoue la requête une fois — `FormData` cloné,
ce qui est le piège classique — et renvoie vers la connexion si le
renouvellement est refusé. Les routes d'inscription sont exemptées de l'en-tête
`Authorization`, ce qui évite les 401 incompréhensibles sur un jeton périmé.

**Le défaut principal, corrigé.** Le même extracteur de message était recopié
dans **onze fichiers**, et tous retombaient sur `e.message`, rédigé par Dio en
anglais. Concrètement, sur une coupure réseau l'utilisateur lisait
`The connection errored: Failed host lookup`, et sur un dépassement de délai
`The request connection took longer than 0:00:30.000000`.

`lib/core/errors/message_erreur.dart` remplace les onze copies et traite :

- le message du backend, qui garde la priorité (il est le seul à connaître la
  raison métier) ;
- les erreurs de validation en tableau (`errors: [{ message }]`) ;
- coupure réseau, délais de connexion, d'envoi et de réception, annulation,
  certificat invalide ;
- 400, 401, 403, 404, 409, 413, 422, 429, 500, 502, 503, 504 ;
- les réponses vides ou en HTML — une page d'erreur Nginx n'est plus affichée
  telle quelle.

**Ce qui reste à faire.** Les indicateurs de chargement et les boutons
« réessayer » existent sur les écrans principaux (accueil, catalogue, commandes)
mais pas partout ; ce n'est pas une anomalie d'intégration et cela n'a pas été
modifié.

---

## 6. Corrections effectuées

Commit `bfaa4cd`, cinq corrections.

| # | Correction | Fichiers |
|---|---|---|
| 1 | Le prix de l'abonnement vient du serveur ; plus jamais `montant: 0` ; message clair si le prix est introuvable | `core/services/config_publique_service.dart` (nouveau), `core/constants/api_endpoints.dart`, `features/abonnement/presentation/pages/mon_abonnement_page.dart`, `injection_container.dart` |
| 2 | La fiche produit signale son ouverture au backend | `features/catalogue/data/catalogue_remote_datasource.dart`, `features/catalogue/presentation/pages/produit_detail_page.dart` |
| 3 | Lecture de `/app/config` au démarrage et écran de maintenance | `core/services/config_publique_service.dart`, `features/auth/presentation/pages/app_bootstrap.dart` |
| 4 | Messages d'erreur centralisés et traduits | `core/errors/message_erreur.dart` (nouveau) + 10 repositories et blocs |
| 5 | Moyens de paiement rectifiés dans l'aide | `features/compte/presentation/pages/aide_page.dart` |

La lecture de `/app/config` est lancée **en parallèle** de la lecture du jeton :
elle n'ajoute aucune attente au démarrage, et une panne du serveur la laisse
sans réponse sans bloquer l'entrée dans l'application.

**Aucune modification du backend n'a été nécessaire** : toutes les anomalies
étaient côté mobile.

---

## 7. Tests réalisés

| Test | Résultat |
|---|---|
| Suite backend (`npm test`) | **152 tests, 14 suites — tous passent** |
| Suite mobile (`flutter test`) | **78 tests — tous passent** (66 avant, 12 ajoutés) |
| `flutter analyze lib` | **0 erreur** |
| Appels réels sur l'API de production | 6 routes publiques, toutes en HTTP 200 |

Les 12 tests ajoutés (`test/core/message_erreur_test.dart`) couvrent la priorité
au message backend, les erreurs de validation en tableau, les coupures réseau,
les délais, chaque code HTTP, les réponses vides ou en HTML, et la comparaison
de versions — y compris le piège `1.10.0` contre `1.2.0`.

Appels réels vérifiés contre `https://api.saambiz.com/saambiz/v1` :

| Route | Code | Réponse | Modèle mobile |
|---|---|---|---|
| `GET /app/config` | 200 | `{minVersionAndroid, minVersionIos, maintenance, message}` | correspond |
| `GET /prix-abonnement` | 200 | `{prix: 2000, devise: "FCFA"}` | correspond |
| `GET /categories` | 200 | `{success, categories: [...]}` | correspond |
| `GET /catalogue/produits` | 200 | `{success, produits, pagination}` | correspond |
| `GET /catalogue/boutiques` | 200 | `{success, boutiques}` | correspond |
| `GET /catalogue/promotions` | 200 | `{success, produits, pagination}` | correspond |

---

## 8. Ce qui reste à résoudre

**Les routes authentifiées sont NON TESTÉES en conditions réelles.** 117 des
123 routes exigent un jeton. Les tester vraiment demandait soit un compte de
test sur la production — ce que je n'utilise pas sans le mot de passe du
propriétaire —, soit un backend local. Ce dernier n'est pas montable sur ce
poste : **Docker n'est pas installé** et il n'y a pas de `.env` dans
`Saambiz_Back`. Leur conformité est donc établie par lecture croisée du code
(route, méthode, schéma de validation, forme de la réponse, modèle mobile), pas
par un appel réel.

Pour lever cette réserve : installer Docker, copier `.env.example` en `.env`,
`docker compose up`, puis rejouer les flux principaux. Je peux écrire le script
d'appels si vous le souhaitez.

**Le catalogue de production est vide.** `/catalogue/produits` et
`/catalogue/boutiques` renvoient des listes vides. L'intégration est correcte,
mais aucun écran acheteur ne peut afficher quoi que ce soit en l'état.

**Pas de notifications push.** `device-token/register` est codé côté mobile et
côté backend, mais aucun SDK push n'est présent : les utilisateurs ne reçoivent
rien téléphone fermé. C'est la fonctionnalité manquante la plus visible pour un
vendeur qui attend une commande.

**La vérification de version minimale est à moitié branchée.** `/app/config`
annonce `minVersionIos` et `ConfigApp.miseAJourExigee()` sait la comparer, mais
l'application ne connaît pas sa propre version à l'exécution : `package_info_plus`
n'est pas dans les dépendances. Ajouter ce paquet juste avant une soumission à
l'App Store n'était pas raisonnable ; la maintenance, elle, fonctionne sans.

**`AUTH_LOGIN_PATH` vient du `.env`.** Le chemin de connexion est lu à
l'exécution avec `/auth/login` en repli. Cela fonctionne, mais un `.env` mal
rempli déplacerait la connexion vers une route inexistante. Les autres chemins
sont des constantes compilées ; celui-ci mériterait de l'être aussi.

**12 routes redondantes côté backend** (section 3b) : à supprimer plutôt qu'à
intégrer.
