import SwiftUI
import GuaWanCore

/// Les icônes de la carte « L'Univers » : univers.js porte ~45 tracés SVG
/// faits main (24×24, trait fin, voir `ICONS` dans univers.js). En attendant
/// une vraie passe d'iconographie dessinée pour l'app, on retombe sur des SF
/// Symbols visuellement proches — un compromis assumé, pas un blocage : voir
/// le rapport de livraison de `UniversMapView`.
enum UniversIcon {

    /// Le nom SF Symbol le plus proche d'une clé d'icône `UniversNode.icon`.
    static func symbolName(_ icon: String) -> String {
        table[icon] ?? "circle.fill"
    }

    static func symbolName(for node: UniversNode) -> String {
        if let verrou = node.verrou, !verrou.isEmpty { return symbolName("verrou") }
        return symbolName(node.icon)
    }

    private static let table: [String: String] = [
        "esprit": "brain.head.profile",
        "creation": "paintpalette.fill",
        "corps": "figure.stand",
        "sensualite": "hand.draw.fill",
        "verrou": "lock.fill",
        "philo": "theatermasks.fill",
        "spiritualites": "moon.stars.fill",
        "textes": "book.closed.fill",
        "meditation": "figure.mind.and.body",
        "mythes": "wand.and.stars",
        "ethique": "checkmark.seal.fill",
        "sciences": "flask.fill",
        "cosmos": "globe",
        "arts": "paintbrush.fill",
        "musique": "music.note",
        "ecriture": "pencil",
        "cinema": "film.fill",
        "ia": "wand.and.rays",
        "gout": "fork.knife",
        "odorat": "wind",
        "toucher": "hand.tap.fill",
        "ouie": "ear.fill",
        "vue": "eye.fill",
        "audela": "infinity",
        "mouvement": "figure.walk",
        "soin": "heart.fill",
        "point": "circle.fill",
        "chevron": "chevron.down",
        "x": "xmark",
        // Utiles à l'habillage de la carte (filtres, recherche), hors liste des
        // icônes de contenu — pas de source univers.js à porter ici.
        "region": "globe",
        "mission": "flag.fill",
    ]
}
