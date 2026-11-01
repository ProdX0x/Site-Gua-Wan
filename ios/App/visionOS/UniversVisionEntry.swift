import SwiftUI
import GuaWanCore

/// Le point d'entrée de « L'Univers » sur visionOS.
///
/// Affiche la carte plate déjà livrée (`UniversMapView`, inchangée) avec un
/// bouton superposé pour basculer vers l'espace immersif en 3D
/// (`UniversImmersiveSpace`, voir `Immersive/`). C'est ce type, avec ce nom
/// et cette visibilité, qui remplace `UniversMapView()` dans `RootView` sur
/// cette seule plateforme.
public struct UniversVisionEntry: View {
    /// Doit correspondre à l'identifiant déclaré pour l'`ImmersiveSpace` dans
    /// `GuaWanApp.swift`.
    static let idEspaceImmersif = "univers-immersif"

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var estImmersif = false
    @State private var enTransition = false

    public init() {}

    public var body: some View {
        UniversMapView()
            .overlay(alignment: .topTrailing) {
                Button {
                    Task { await basculer() }
                } label: {
                    Label(
                        estImmersif ? "Quitter l'espace immersif" : "Ouvrir en immersif",
                        systemImage: estImmersif ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
                    )
                }
                .disabled(enTransition)
                .padding(.top, 72)
                .padding(.trailing, 20)
            }
    }

    private func basculer() async {
        guard !enTransition else { return }
        enTransition = true
        defer { enTransition = false }
        if estImmersif {
            await dismissImmersiveSpace()
            estImmersif = false
        } else {
            let resultat = await openImmersiveSpace(id: Self.idEspaceImmersif)
            if case .opened = resultat {
                estImmersif = true
            }
        }
    }
}
