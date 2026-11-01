import SwiftUI

/// Le tracé d'un ensō (円相) : le cercle tracé d'un seul geste, jamais
/// totalement refermé, qui sert de signature visuelle à Guà Wàn (logo,
/// racine de L'Univers, fond de la page d'accueil).
///
/// Sur le site web, l'irrégularité du trait vient d'un filtre SVG
/// (`feTurbulence` + `feDisplacementMap`, voir le `<filter id="brush">`
/// dans `maquette/univers/index.html`). SwiftUI n'a pas d'équivalent direct :
/// on obtient un effet de pinceau comparable en perturbant le rayon le long
/// du tracé par une onde déterministe (pas de hasard à chaque frame, sinon
/// le trait « grouille » au lieu de rester un dessin stable).
public struct EnsoShape: Shape {
    /// Portion du cercle laissée ouverte, comme un vrai ensō.
    public var gap: Angle
    public var wobble: Double

    public init(gap: Angle = .degrees(20), wobble: Double = 0.045) {
        self.gap = gap
        self.wobble = wobble
    }

    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let start = Angle.degrees(-112)
        let sweep = Angle.degrees(360) - gap
        let steps = 140
        var path = Path()
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let angle = start + sweep * t
            let wob = 1 + wobble * sin(t * 15 * .pi) * (0.25 + 0.75 * t)
            let r = radius * wob
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle.radians)) * r,
                y: center.y + CGFloat(sin(angle.radians)) * r
            )
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

/// Vue prête à l'emploi : le trait, et son point d'accent (comme `.enso-dot`).
public struct Enso: View {
    /// Si vrai, le trait se dessine progressivement à l'apparition (comme sur
    /// la racine de la carte L'Univers : `.enso-stroke.draw` dans univers.css).
    public var seDessine: Bool
    public var couleurTrait: Color
    public var couleurPoint: Color?
    public var largeurTrait: CGFloat

    @State private var avancement: CGFloat = 0

    public init(seDessine: Bool = false, couleurTrait: Color = GWColor.fg,
                couleurPoint: Color? = GWColor.accent, largeurTrait: CGFloat = 9) {
        self.seDessine = seDessine
        self.couleurTrait = couleurTrait
        self.couleurPoint = couleurPoint
        self.largeurTrait = largeurTrait
    }

    public var body: some View {
        ZStack {
            EnsoShape()
                .trim(from: 0, to: seDessine ? avancement : 1)
                .stroke(couleurTrait, style: StrokeStyle(lineWidth: largeurTrait, lineCap: .round))
            if let couleurPoint {
                Circle()
                    .fill(couleurPoint)
                    .frame(width: 12, height: 12)
                    .shadow(color: couleurPoint.opacity(0.7), radius: 8)
            }
        }
        .onAppear {
            guard seDessine else { return }
            withAnimation(.easeOut(duration: 1.6).delay(0.1)) { avancement = 1 }
        }
    }
}
