# Aperçus du design

Captures de chaque écran de l'application, avec des données fictives
(boutiques, produits et commandes inventés). Rien ne part sur le réseau.

## Lancer

- Android Studio : configuration **« Aperçu design »**, bouton Run.
- Ou en ligne de commande, depuis `Mobile/` :

      flutter test test_apercu/apercu_test.dart

Les images arrivent dans `test_apercu/captures/` (une par écran), avec
`journal.txt` : requêtes auxquelles les données fictives ne répondent pas et
erreurs de mise en page (débordements…).

## Contenu

| Fichier | Rôle |
|---|---|
| `apercu_test.dart` | La liste des écrans capturés |
| `donnees.dart` | Les données fictives, servies à la place de l'API |
| `outils.dart` | Préparation (polices, images, faux serveur) et capture |
| `images/` | Visuels des produits et logos des boutiques (Fluent Emoji 3D de Microsoft, licence MIT, et monogrammes) |

Le dossier est hors de `test/` : `flutter test` seul ne le lance pas.
