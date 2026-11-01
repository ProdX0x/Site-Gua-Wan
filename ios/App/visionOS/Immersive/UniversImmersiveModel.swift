import Foundation
import GuaWanCore

/// Le modèle de l'espace immersif « L'Univers ».
///
/// Choix assumé : cette scène possède son propre `UniversStore`, distinct de
/// celui de `UniversMapView` (la carte plate) — pour cette première passe,
/// chaque scène (fenêtre 2D, espace immersif) a son propre état d'ouverture
/// et de recherche, plutôt qu'un store partagé entre elles. Un partage pourra
/// être envisagé plus tard si l'on veut qu'ouvrir une branche dans l'une se
/// reflète dans l'autre.
@MainActor
@Observable
final class UniversImmersiveModel {
    let store = UniversStore()

    // MARK: - Conversion « monde » (moteur radial) → mètres RealityKit

    /// 1 unité « monde » du moteur radial (voir `UniversStore`/`UniversGeometry`,
    /// dont les anneaux de référence vont de 330 à 1740 unités, et les bulles
    /// de 128 à 228) devient ce nombre de mètres. À cette échelle, l'anneau
    /// des blocs (rayon ≈ 330 unités) s'étale sur un peu plus d'un mètre de
    /// part et d'autre de « Vous » : une largeur de bras confortable à la
    /// distance où ce premier anneau est placé (voir `profondeurRacine`).
    private static let metresParUnite: Float = 0.0022

    /// Distance (mètres, négative = devant la personne) de la racine « Vous ».
    /// Dans le repère d'un `ImmersiveSpace` non ancré, l'origine se situe au
    /// sol à l'endroit où l'espace s'ouvre, les Y pointent vers le haut et
    /// l'avant de la personne est -Z — c'est la convention habituelle du
    /// contenu visionOS non ancré à la tête/au sol (comme les exemples
    /// d'Apple) ; elle reste une approximation à confirmer à l'usage.
    private static let profondeurRacine: Float = -1.7

    /// Recul supplémentaire par palier de profondeur (bloc → branche → fiche).
    /// C'est ce qui transforme les anneaux concentriques de la carte plate en
    /// vraies strates spatiales, à des distances croissantes de la personne,
    /// plutôt qu'une carte plate simplement posée dans l'espace.
    private static let pasProfondeur: Float = -0.4

    /// Hauteur approximative des yeux (mètres), pour centrer la carte à
    /// hauteur de regard plutôt qu'au sol. Approximation : ce repère ne
    /// connaît pas la vraie taille de la personne.
    private static let hauteurYeux: Float = 1.5

    /// Position 3D (mètres, repère monde de l'espace immersif) d'un nœud.
    func position3D(for node: UniversNode) -> SIMD3<Float> {
        let pos = store.position(of: node)
        let x = Float(pos.x) * Self.metresParUnite
        // Les y du moteur radial grandissent vers le bas de l'écran (repère
        // SwiftUI classique) ; on les inverse pour que le haut de l'éventail
        // reste en haut dans l'espace, où Y pointe vers le haut.
        let y = Self.hauteurYeux - Float(pos.y) * Self.metresParUnite
        let z = Self.profondeurRacine + Self.pasProfondeur * Float(node.depth)
        return SIMD3<Float>(x, y, z)
    }

    /// Taille (mètres) de la bulle d'un nœud — même échelle que les positions,
    /// pour conserver les proportions et le non-recouvrement déjà garantis
    /// par le moteur radial en 2D.
    func taille3D(for node: UniversNode) -> Float {
        Float(UniversGeometry.taille(node.kind)) * Self.metresParUnite
    }
}
