import SwiftUI
import GuaWanCore

/// Les trois scènes de Guà Wàn sur visionOS :
/// - la fenêtre principale (`RootView`, inchangée dans son principe — c'est
///   elle qui affiche `UniversVisionEntry` pour la rubrique L'Univers) ;
/// - l'espace immersif de L'Univers (`Immersive/UniversImmersiveSpace.swift`),
///   ouvert/fermé depuis `UniversVisionEntry` ;
/// - une fenêtre auxiliaire paramétrée par une `Fiche`, pour lire une fiche
///   sans quitter l'immersion (ouverte via `openWindow(value:)` au tap sur
///   une bulle-fiche dans l'espace immersif).
@main
struct GuaWanApp: App {
    var body: some Scene {
        WindowGroup(id: "main") {
            RootView()
        }

        WindowGroup(id: "fiche-detail", for: Fiche.self) { $fiche in
            if let fiche {
                FicheDetailView(fiche: fiche)
            }
        }

        ImmersiveSpace(id: UniversVisionEntry.idEspaceImmersif) {
            UniversImmersiveSpace()
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
