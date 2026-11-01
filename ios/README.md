# Guà Wàn — app native (iOS · iPadOS · macOS · tvOS · visionOS)

Port 100 % natif SwiftUI de la maquette web `maquette/` (site principal + « L'Univers »).
Ce code a été écrit depuis une machine Linux, **sans Xcode ni toolchain Swift disponibles
pour le compiler ici** : il doit être ouvert et construit sur un Mac. Relisez-le comme un
premier passage à valider en build réel, pas comme un livrable déjà compilé.

## Pourquoi XcodeGen plutôt qu'un .xcodeproj

Le projet Xcode (`GuaWan.xcodeproj`) n'est **pas versionné** : il est généré à partir de
[`project.yml`](project.yml) par [XcodeGen](https://github.com/yonaskolb/XcodeGen). C'est
volontaire et pensé pour l'évolutivité demandée :

- `project.yml` est un fichier texte lisible, qui diffe proprement dans Git — contrairement
  à un `.pbxproj` binaire-ish, source classique de conflits de fusion.
- Ajouter un fichier Swift dans `App/Shared`, `App/iOS`, etc. suffit : il est ramassé
  automatiquement au prochain `xcodegen generate` (pas d'édition manuelle du projet).

### Premier lancement (sur un Mac, avec Xcode 16+ installé)

```bash
brew install xcodegen   # une seule fois
cd ios
xcodegen generate
open GuaWan.xcodeproj
```

Quatre schémas sont générés : `GuaWan-iOS`, `GuaWan-macOS`, `GuaWan-tvOS`, `GuaWan-visionOS`.
Avant de lancer sur un appareil (le simulateur n'en a pas besoin), renseignez votre équipe
de signature dans Xcode → target → *Signing & Capabilities* (le `DEVELOPMENT_TEAM` est
volontairement laissé vide dans `project.yml`).

## Organisation

```
ios/
├── project.yml              # spec XcodeGen (4 cibles d'app)
├── sync-content.sh          # synchronise docs/articles/*.json → ressources du bundle
├── Packages/GuaWanCore/     # tout le code partagé, multi-plateforme (Swift Package)
│   └── Sources/GuaWanCore/
│       ├── Models/          # Fiche, Carte (blocs/groupes/salons), Univers, modèles sociaux
│       ├── Content/         # ContentRepository : chargement + validation des fiches JSON
│       ├── DesignSystem/    # couleurs, typographie, ensō, composants (boutons, chips…)
│       ├── Stores/          # état observable : UniversStore (moteur radial), FeedStore…
│       ├── Services/        # protocoles + implémentations (Oracle IA, etc.), mockables
│       └── Resources/Content/*.json   # les fiches embarquées (voir sync-content.sh)
└── App/
    ├── Shared/              # SwiftUI commun aux 4 plateformes (vues, navigation)
    ├── iOS/                 # point d'entrée + Info.plist iPhone/iPad
    ├── macOS/               # point d'entrée + Info.plist Mac
    ├── tvOS/                # point d'entrée + Info.plist Apple TV
    └── visionOS/            # point d'entrée + Info.plist Vision Pro (+ espace immersif)
```

## Ajouter une fiche (le point central de l'évolutivité demandée)

1. Déposer un fichier JSON dans `../docs/articles/` (même schéma que les fichiers
   existants : `salon, title, excerpt, tag, body, pratique, sources, …` — voir
   `scripts/integrer-articles.py` à la racine du dépôt pour le détail exact des champs).
2. `./sync-content.sh`
3. Recompiler. La fiche apparaît automatiquement dans son salon, dans le fil du bloc
   correspondant **et** dans la carte « L'Univers » (le bloc/groupe/salon doivent déjà
   exister dans `Carte.swift` — ajouter un salon entièrement nouveau demande d'y ajouter
   une ligne, ajouter une fiche dans un salon existant ne demande rien de plus que l'étape 1).

Aucune recompilation d'un pipeline séparé n'est nécessaire côté app (contrairement au site
web, où `construire-univers.py`/`integrer-articles.py` doivent être rejoués) : l'app
construit l'arbre de L'Univers et les fils par bloc **au runtime**, directement depuis les
fiches chargées.

## Ce qui est fonctionnel vs. prévu comme point d'extension

Voir le rapport d'architecture donné dans la conversation : la lecture de fiches, la carte
L'Univers et la navigation sont construites pour être réellement utilisables. L'Oracle (IA),
le Club (abonnement), les Lives, le Calendrier, l'Annuaire et la Carte des Humains sont
câblés et navigables mais reposent sur des services mockés (protocoles clairement
identifiés dans `Services/`) en attendant un vrai backend — exactement comme la maquette
web les présentait déjà comme tels (bandeau « Maquette »).
