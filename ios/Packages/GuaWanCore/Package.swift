// swift-tools-version: 6.0
import PackageDescription

/// Module partagé, multi-plateforme, de l'application Guà Wàn.
///
/// Contient tout ce qui n'est pas lié à une coquille d'app précise :
/// modèles de contenu, chargement/validation des fiches, design system,
/// et les stores (@Observable) qui portent la logique métier — notamment
/// le moteur de disposition radiale de L'Univers.
///
/// Les cibles d'application (iOS/macOS/tvOS/visionOS, voir ../project.yml)
/// dépendent de ce package mais n'y ajoutent que de la mise en page et
/// des adaptations propres à chaque plateforme.
let package = Package(
    name: "GuaWanCore",
    defaultLocalization: "fr",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(name: "GuaWanCore", targets: ["GuaWanCore"])
    ],
    targets: [
        .target(
            name: "GuaWanCore",
            resources: [
                // Les fiches JSON du client : ajouter un fichier ici (même schéma
                // que docs/articles/*.json à la racine du dépôt) suffit à faire
                // apparaître une nouvelle fiche dans l'app, sans toucher au code.
                // `sync-content.sh` tient ce dossier synchronisé avec docs/articles/.
                .copy("Resources/Content")
            ]
        ),
        .testTarget(
            name: "GuaWanCoreTests",
            dependencies: ["GuaWanCore"]
        ),
    ]
)
