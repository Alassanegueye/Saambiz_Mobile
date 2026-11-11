# Visuels Play Store

| Fichier | Format exigé | Ce qu'il est |
|---|---|---|
| `icone-512.png` | 512 × 512, PNG, < 1 Mo | icône de la fiche |
| `banniere-play-1024x500.png` | 1024 × 500, PNG, < 15 Mo | graphique de présentation |
| `banniere.html` | — | la **source** de la bannière |

L'icône est dérivée de `ios/Runner/.../Icon-App-1024x1024@1x.png`, celle
qu'Apple a déjà validée : même logo sur les deux magasins.

```bash
sips -z 512 512 <source-1024>.png --out icone-512.png
```

## Régénérer la bannière

Elle est dessinée sur un canvas plutôt que mise en page en HTML : une capture
d'écran dépend de la taille de la fenêtre et du rapport de pixels, le canvas
non. Ce qui sort fait exactement 1024 × 500, sur n'importe quelle machine.

```bash
cd design/play-store && python3 -m http.server 8713
```

Ouvrir `http://localhost:8713/banniere.html`, puis enregistrer le canvas
(clic droit → Enregistrer l'image).

Deux pièges, corrigés dans la source et commentés sur place :

- **fond plat, jamais de dégradé** — le logo porte son propre fond marine, et
  sur un dégradé son carré se détache ;
- **attendre les polices explicitement** avec `document.fonts.load()` pour
  chaque graisse. `document.fonts.ready` ne suffit pas pour un canvas : le
  dessin part en Helvetica sans prévenir, et ça ne se voit qu'à l'image finale.

## Ce qui manque encore

Les **captures d'écran** (2 minimum, 8 maximum pour le téléphone). Celles de
l'App Store sont au format iPhone : une encoche et des coins d'iPhone sur une
fiche Android se repèrent au premier coup d'œil. À refaire depuis un émulateur
Android.
