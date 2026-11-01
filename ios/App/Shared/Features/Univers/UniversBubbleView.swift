import SwiftUI
import GuaWanCore

/// Une bulle de la carte, stylée selon son type — racine (ensō + « Vous »),
/// bloc (kanji), branche (icône + libellé), fiche (carré arrondi + titre court).
///
/// Ne connaît que « comment dessiner ce nœud » : la position, l'échelle et
/// l'opacité viennent de `UniversStore` (voir `layout()`), et c'est SwiftUI,
/// pas une boucle main, qui anime leur changement (la bulle lit juste l'état
/// courant à chaque rafraîchissement).
struct UniversBubbleView: View {
    let node: UniversNode
    let store: UniversStore
    var onTap: (UniversNode) -> Void

    private var couleur: Color { GWColor.couleur(nommee: node.couleur) }
    private var taille: CGFloat { CGFloat(UniversGeometry.taille(node.kind)) }
    private var estVerrouille: Bool { node.verrou != nil }
    private var estAVenir: Bool { node.aVenir != nil && node.kind != .carte }
    private var estEnValeur: Bool {
        store.apparenceFiltre(de: node).estCorrespondance || store.pingedNodeId == node.id
    }

    var body: some View {
        let pos = store.position(of: node)
        let estAttenue = store.apparenceFiltre(de: node).estAttenue

        // Un vrai `Button` plutôt qu'un `.onTapGesture` : seul `Button` répond
        // de façon fiable au Focus Engine de tvOS (et au regard+pincement de
        // visionOS), pas seulement au tap iOS/clic macOS.
        Button {
            onTap(node)
        } label: {
            content
                .frame(width: taille, height: taille)
                .overlay(alignment: .bottom) { badge }
        }
        .buttonStyle(.plain)
        .saturation(estAttenue ? 0.35 : 1)
        .scaleEffect(CGFloat(pos.popScale * store.bubbleBreathScale) * store.scale)
        .opacity(pos.opacity * (estAttenue ? 0.22 : 1))
        .position(
            x: store.offset.width + CGFloat(pos.x) * store.scale,
            y: store.offset.height + CGFloat(pos.y) * store.scale
        )
        .allowsHitTesting(pos.visible)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText))
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var content: some View {
        switch node.kind {
        case .racine: racineContent
        case .bloc: blocContent
        case .branche: brancheContent
        case .carte: carteContent
        }
    }

    private var racineContent: some View {
        ZStack {
            backgroundView(Circle(), dashed: false, highlighted: estEnValeur)
            Enso(seDessine: true, couleurTrait: GWColor.fg, couleurPoint: GWColor.accent, largeurTrait: 5)
                .padding(taille * 0.09)
            VStack(spacing: 4) {
                Circle()
                    .fill(GWColor.accent)
                    .frame(width: 12, height: 12)
                    .shadow(color: GWColor.accent.opacity(0.7), radius: 8)
                Text(node.label)
                    .font(GWFont.display(32, weight: .bold))
                    .foregroundStyle(GWColor.fg)
                if let sousTitre = node.sousTitre {
                    Text(sousTitre)
                        .font(GWFont.body(11, weight: .regular))
                        .foregroundStyle(GWColor.muted)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .frame(maxWidth: taille * 0.58)
                }
            }
        }
    }

    private var blocContent: some View {
        ZStack {
            backgroundView(Circle(), dashed: false, highlighted: estEnValeur)
            VStack(spacing: 7) {
                Text(node.kanji ?? "")
                    .font(GWFont.kanjiBloc)
                    .foregroundStyle(couleur)
                    .frame(width: taille * 0.32, height: taille * 0.32)
                    .background(couleur.opacity(0.13), in: Circle())
                Text(node.label)
                    .font(GWFont.display(19, weight: .semibold))
                    .foregroundStyle(GWColor.fg)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(taille * 0.13)
        }
    }

    private var brancheContent: some View {
        ZStack {
            backgroundView(Circle(), dashed: estVerrouille || estAVenir, highlighted: estEnValeur)
            VStack(spacing: 7) {
                Image(systemName: UniversIcon.symbolName(for: node))
                    .font(.system(size: taille * 0.2))
                    .frame(width: taille * 0.28, height: taille * 0.28)
                    .background(
                        (estVerrouille || estAVenir ? GWColor.sunken : couleur.opacity(0.14)),
                        in: Circle()
                    )
                    .foregroundStyle(estVerrouille || estAVenir ? GWColor.muted : couleur)
                Text(node.label)
                    .font(GWFont.body(13.5, weight: .medium))
                    .foregroundStyle(estAVenir ? GWColor.muted : GWColor.fg)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                if let sous = sousTitreAffiche {
                    Text(sous)
                        .font(GWFont.mono(10))
                        .foregroundStyle(GWColor.muted)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(taille * 0.13)
        }
    }

    private var carteContent: some View {
        ZStack {
            backgroundView(RoundedRectangle(cornerRadius: 24, style: .continuous), dashed: false, highlighted: estEnValeur)
            VStack(spacing: 7) {
                Image(systemName: UniversIcon.symbolName(for: node))
                    .font(.system(size: taille * 0.15))
                    .foregroundStyle(couleur)
                Text(node.fiche?.shortTitle ?? node.label)
                    .font(GWFont.body(11.5, weight: .medium))
                    .foregroundStyle(GWColor.fg)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private var badge: some View {
        if node.peutOuvrir {
            let estOuvert = store.isExpanded(node)
            Text(estOuvert ? "−" : (node.leaves > 0 ? "\(node.leaves)" : "à venir"))
                .font(GWFont.mono(10.5, weight: .medium))
                .padding(.horizontal, 7)
                .frame(height: 18)
                .background(estOuvert ? GWColor.sunken : couleur, in: Capsule())
                .foregroundStyle(estOuvert ? GWColor.muted : GWColor.onColor)
                .overlay {
                    if estOuvert { Capsule().strokeBorder(GWColor.lineStrong, lineWidth: 1) }
                }
                .offset(y: taille * 0.08)
        }
    }

    /// Fond partagé (cercle ou carré arrondi) : léger dégradé vers la couleur
    /// du nœud, bordure pleine ou tiretée (fermé/à venir), mise en évidence
    /// (filtre/recherche) — reflet de `.bubble`/`is-locked`/`is-match` dans
    /// univers.css.
    private func backgroundView<S: InsettableShape>(_ shape: S, dashed: Bool, highlighted: Bool) -> some View {
        ZStack {
            shape.fill(GWColor.surface)
            shape.fill(
                RadialGradient(colors: [couleur.opacity(0.17), .clear], center: .top, startRadius: 1, endRadius: taille * 0.75)
            )
            shape.strokeBorder(
                couleur.opacity(highlighted ? 0.95 : 0.36),
                style: StrokeStyle(lineWidth: highlighted ? 2 : 1, dash: dashed ? [5, 4] : [])
            )
        }
    }

    private var sousTitreAffiche: String? {
        if estVerrouille { return "Fermé" }
        if estAVenir { return "À venir" }
        return node.sousTitre
    }

    /// Reflet de `ariaOf()` dans univers.js.
    private var accessibilityText: String {
        if node.kind == .carte { return "\(node.label). Ouvrir la fiche." }
        if let verrou = node.verrou { return "\(node.label), fermé. \(verrou)" }
        if let aVenir = node.aVenir { return "\(node.label), à venir. \(aVenir)" }
        if node.kind == .racine { return "\(node.label) : \(node.sousTitre ?? "")" }
        return "\(node.label), \(node.leaves) fiche\(node.leaves > 1 ? "s" : "")"
    }
}
