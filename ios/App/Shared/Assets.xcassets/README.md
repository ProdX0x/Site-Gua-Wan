# Icônes à ajouter avant de livrer au client

Ce catalogue d'assets contient déjà :

- **`AccentColor`** : la teinte d'accentuation système (shu — `#B83E26` en clair,
  `#E3613F` en sombre), identique à `GWColor.accent`. Rien à faire ici.
- **`AppIcon`** (format « taille unique » d'Xcode 14+, universel) : la *case*
  existe, mais aucune image n'est fournie — il n'y a pas d'artwork d'icône
  dans ce dépôt. Glissez un PNG `1024×1024` (sans coins arrondis, sans canal
  alpha) dans cette case depuis Xcode pour l'iPhone/iPad/Mac/Vision Pro.

Ce `README.md` n'est pas un fichier d'asset : Xcode l'ignore, il ne sert qu'à
documenter ce dossier.

## Apple TV : un cas particulier

tvOS n'utilise pas un simple `AppIcon.appiconset` : il veut un jeu **« App
Icon & Top Shelf Image »**, avec des couches avant/arrière pour l'effet de
parallaxe au focus, plus une image « Top Shelf » large affichée en haut de
l'écran d'accueil quand l'app est sélectionnée. Ce format se construit
correctement dans l'éditeur d'assets d'Xcode (New App Icon & Top Shelf
Image), à partir de vraies couches d'illustration — pas quelque chose qu'on
peut raisonnablement écrire à la main en JSON sans le vérifier dans Xcode.

En attendant, `ios/project.yml` ne fixe **aucun**
`ASSETCATALOG_COMPILER_APPICON_NAME` pour la cible tvOS : Xcode affichera une
icône par défaut jusqu'à ce que ce jeu d'icônes soit créé puis référencé.
