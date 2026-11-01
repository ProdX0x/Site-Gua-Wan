import SwiftUI
import GuaWanCore

/// Les anneaux concentriques et les liens courbes entre bulles, dans un seul
/// `Canvas` passé à l'échelle de la caméra.
///
/// Simplification assumée par rapport à univers.js : là où le site anime le
/// tracé des liens (dash offset progressif) et les laisse suivre image par
/// image la position interpolée de chaque bulle, ce `Canvas` relit l'état
/// *courant* du store à chaque rafraîchissement et redessine instantanément —
/// les bulles elles-mêmes glissent en douceur (`.position` animé par
/// SwiftUI), mais les traits qui les relient « sautent » directement à leur
/// nouvelle place plutôt que de se retracer. Un vrai tracé progressif
/// demanderait un `Shape` animable dédié par lien ; pour cette passe, le
/// compromis visuel (bulles animées, liens non animés) est jugé suffisant.
struct UniversLinkLayer: View {
    let store: UniversStore

    var body: some View {
        Canvas { context, _ in
            context.translateBy(x: store.offset.width, y: store.offset.height)
            context.scaleBy(x: store.scale, y: store.scale)

            for r in store.anneauxVisibles {
                let side = CGFloat(r * 2)
                var path = Path()
                path.addEllipse(in: CGRect(x: -side / 2, y: -side / 2, width: side, height: side))
                context.stroke(
                    path,
                    with: .color(GWColor.lineStrong),
                    style: StrokeStyle(lineWidth: store.epaisseurAnneaux, dash: store.tiretsAnneaux)
                )
            }

            for n in store.tousLesNoeuds {
                guard let parent = n.parent else { continue }
                let pos = store.position(of: n)
                guard pos.opacity > 0 else { continue }
                let path = linkPath(from: store.position(of: parent), parentKind: parent.kind, parentDepth: parent.depth, to: pos, childKind: n.kind)
                context.stroke(
                    path,
                    with: .color(GWColor.couleur(nommee: n.couleur).opacity(0.42)),
                    style: StrokeStyle(lineWidth: store.epaisseurLiens, lineCap: .round)
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Reflet de `linkPath()` dans univers.js : une courbe de Bézier qui
    /// quitte la bulle mère dans l'axe du rayonnement et rejoint la fille
    /// par l'intérieur.
    private func linkPath(
        from p: NodePosition, parentKind: NodeKind, parentDepth: Int,
        to c: NodePosition, childKind: NodeKind
    ) -> Path {
        let dx = c.x - p.x, dy = c.y - p.y
        let length = (dx * dx + dy * dy).squareRoot()
        let rp = UniversGeometry.taille(parentKind) / 2 * store.bubbleBreathScale + 4
        let rc = UniversGeometry.taille(childKind) / 2 * store.bubbleBreathScale + 4
        guard length >= rp + rc + 2 else { return Path() }
        let ux = dx / length, uy = dy / length
        let x1 = p.x + ux * rp, y1 = p.y + uy * rp
        let x2 = c.x - ux * rc, y2 = c.y - uy * rc
        let k = (length - rp - rc) * 0.42
        let (px, py) = parentDepth > 0 ? unit(p.x, p.y) : (ux, uy)
        let (cx, cy) = unit(c.x, c.y)

        var path = Path()
        path.move(to: CGPoint(x: CGFloat(x1), y: CGFloat(y1)))
        path.addCurve(
            to: CGPoint(x: CGFloat(x2), y: CGFloat(y2)),
            control1: CGPoint(x: CGFloat(x1 + px * k), y: CGFloat(y1 + py * k)),
            control2: CGPoint(x: CGFloat(x2 - cx * k), y: CGFloat(y2 - cy * k))
        )
        return path
    }

    private func unit(_ x: Double, _ y: Double) -> (Double, Double) {
        let l = (x * x + y * y).squareRoot()
        guard l > 0 else { return (0, 0) }
        return (x / l, y / l)
    }
}
