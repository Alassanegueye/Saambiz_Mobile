# Fichiers sources (hors bundle)

Ce dossier garde les visuels **d'origine**, en pleine résolution. Il n'est pas
déclaré dans `pubspec.yaml` : rien de ce qui est ici n'est embarqué dans l'APK
ou l'IPA. `assets/` ne contient que les versions préparées pour l'application.

## `onboarding/` — `1.png`, `2.png`, `3.png`

Les trois visuels d'accueil, tels que livrés. Ils portent leurs points de
progression gravés (et un bouton « Commencer » gravé sur le 3ᵉ).

Ce qui est embarqué : `assets/images/onb1.jpg`, `onb2.jpg`, `onb3.jpg` — mêmes
visuels rognés juste au-dessus de ces éléments (c'est le code qui dessine les
points animés et le bouton), redimensionnés à 1080 px de large et convertis en
JPEG qualité 88. Ce sont des photographies : le PNG les stockait sans
compression utile, la conversion fait passer les trois de 4,4 Mo à 650 Ko sans
différence visible.

Pour régénérer après une nouvelle livraison, rogner chaque visuel juste
au-dessus des points gravés puis exporter en JPEG 1080 px.

## `brand/` — `Pictogramme SaamBizz - Blanc.png`

Le pictogramme sur fond blanc, en 1254 px.

Ce qui est embarqué : `assets/icons/picto_saambiz.png` — même pictogramme avec
le fond blanc rendu transparent et détouré au plus juste, en 320 px. Il sert de
marque dans l'en-tête des écrans d'inscription et sur l'écran de bienvenue
vendeur, où le fond n'est pas blanc.
