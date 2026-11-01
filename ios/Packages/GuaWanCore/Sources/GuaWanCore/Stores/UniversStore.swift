import Foundation
import SwiftUI

/// Les tailles de bulle par type de nœud (voir `SIZE` dans univers.js).
public enum UniversGeometry {
    public static func taille(_ kind: NodeKind) -> Double {
        switch kind {
        case .racine: 228
        case .bloc: 196
        case .branche: 150
        case .carte: 128
        }
    }
}

/// La disposition calculée d'un nœud à l'instant présent : sa position dans le
/// monde (indépendante de la caméra), son échelle et son opacité d'apparition.
///
/// Volontairement séparé d'`UniversNode` (qui reste un modèle de donnée pur) :
/// c'est l'état mouvant du moteur radial, recalculé à chaque `layout()`. La
/// vue lit ces valeurs à travers un simple `.position`/`.scaleEffect`/`.opacity`
/// et laisse SwiftUI les animer — pas de boucle d'animation main (voir le
/// commentaire sur `withLayoutAnimation`).
public struct NodePosition: Sendable, Equatable {
    /// Coordonnées monde (racine = origine), indépendantes du zoom/pan.
    public var x: Double = 0
    public var y: Double = 0
    /// Échelle d'apparition : 0.3 repliée/masquée → 1 pleinement affichée.
    public var popScale: Double = 0.3
    public var opacity: Double = 0
    public var visible: Bool = false
}

/// Le filtre actif (région ou mission) : quelles fiches correspondent exactement,
/// et quelles bulles (ancêtres compris) doivent rester nettes autour d'elles.
public struct ActiveFilter: Sendable, Equatable {
    public let filtreId: String
    public let valeur: String
    public let correspondances: Set<String>
    public let conserver: Set<String>
}

/// Une valeur possible d'un filtre (ex. une région), et le nombre de fiches
/// qui s'y rattachent — ce que liste la feuille de filtre.
public struct FiltreValeur: Identifiable, Sendable, Equatable {
    public var id: String { valeur }
    public let valeur: String
    public let compte: Int
}

/// Le moteur de la carte « L'Univers » : portage fidèle de `univers.js`
/// (géométrie radiale, caméra, ouverture en cascade, recherche tolérante,
/// filtres) en un store SwiftUI observable.
///
/// Toute la mécanique vit ici ; `UniversNode` reste un arbre de donnée
/// immuable et `UniversMapView` ne fait que lire cet état et retransmettre
/// les gestes. Isolé sur `@MainActor` : c'est là que vivent l'arbre, les
/// positions et la caméra, et c'est aussi le fil sur lequel SwiftUI anime.
@Observable
@MainActor
public final class UniversStore {

    // MARK: Contenu

    public private(set) var root: UniversNode?
    public private(set) var isLoading = false
    public private(set) var loadProblems: [String] = []

    // MARK: Ouverture / disposition

    public private(set) var expanded: Set<String> = []
    public private(set) var positions: [String: NodePosition] = [:]

    // MARK: Caméra

    /// Position écran du point monde (0,0) — c'est-à-dire du centre de « Vous ».
    public private(set) var offset: CGSize = .zero
    public private(set) var scale: CGFloat = 1

    // MARK: Filtre

    public private(set) var filtre: ActiveFilter?

    /// L'identifiant du nœud qu'on vient de révéler (recherche, lien profond) :
    /// la vue peut y accrocher un halo pulsé passager (voir `reveal`).
    public private(set) var pingedNodeId: String?

    // MARK: - Implémentation

    private let repository: ContentRepository
    private var allNodes: [UniversNode] = []
    private var byId: [String: UniversNode] = [:]
    private var searchIndex: [SearchEntry] = []
    private var ringScale: Double = 1
    private var userMoved = false
    /// La zone de l'écran dans laquelle la carte doit tenir (hors topbar/contrôles),
    /// dans le repère de la vue — équivalent de `area()` dans univers.js, mais
    /// fourni par la vue (qui seule connaît ses propres marges de chrome).
    private var viewportArea = CGRect(x: 0, y: 0, width: 1000, height: 800)

    private struct SearchEntry {
        let node: UniversNode
        let titre: [String]
        let hay: [String]
    }

    private struct LayoutScratch {
        var need: Double = 0
        var rows: Int = 0
        var perRow: Int = 0
        var step: Double = 0
    }

    private static let zMin: CGFloat = 0.05
    private static let zMax: CGFloat = 2.4
    private static let zFitMax: CGFloat = 1
    private static let bsRef: Double = 0.62
    private static let bsMax: Double = 1.16
    private static let dureeAnimation: Double = 0.68
    private static let motsVides: Set<String> = Set(
        "le la les de des du un une et en au aux que qui quoi pour par sur avec est ce ces son sa ses mon ma mes comment pourquoi"
            .split(separator: " ").map(String.init)
    )

    public init(repository: ContentRepository = BundledJSONContentRepository()) {
        self.repository = repository
    }

    // MARK: - Chargement

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await repository.loadFiches()
            loadProblems = result.problems
            let tree = UniversTreeBuilder.build(fiches: result.fiches)
            root = tree
            indexer(tree)
        } catch {
            loadProblems = ["Chargement du contenu impossible : \(error.localizedDescription)"]
        }
    }

    private func indexer(_ tree: UniversNode) {
        var flat: [UniversNode] = []
        UniversTreeBuilder.walk(tree) { flat.append($0) }
        allNodes = flat
        byId = Dictionary(uniqueKeysWithValues: flat.map { ($0.id, $0) })
        searchIndex = flat.filter { $0.depth > 0 }.map { n in
            let chemin = n.ancetres.map(\.label).joined(separator: " › ")
            let hayComponents: [String?] = [n.fiche?.excerpt, n.fiche?.repere, chemin, n.sousTitre]
            let hayParts = hayComponents.compactMap { $0 }
            return SearchEntry(
                node: n,
                titre: TextNormalization.words(n.label),
                hay: TextNormalization.words(hayParts.joined(separator: " "))
            )
        }
    }

    public func node(id: String) -> UniversNode? { byId[id] }

    /// Tous les nœuds de l'arbre, à plat — pour que la vue puisse dessiner
    /// chaque bulle/lien sans réimplémenter le parcours de l'arbre.
    public var tousLesNoeuds: [UniversNode] { allNodes }

    /// À appeler une fois après `load()`, quand la vue connaît sa largeur :
    /// ouvre la racine (et, si l'écran est assez large, les trois blocs
    /// d'emblée) — équivalent de `setInitialOpen()` dans univers.js.
    public func setInitialOpen(wide: Bool) {
        guard let root else { return }
        expanded = [root.id]
        if wide { expanded.formUnion(root.children.map(\.id)) }
        layout()
    }

    // MARK: - État

    public func isExpanded(_ n: UniversNode) -> Bool { expanded.contains(n.id) }
    public func position(of n: UniversNode) -> NodePosition { positions[n.id] ?? NodePosition() }

    public var toutEstOuvert: Bool {
        allNodes.allSatisfy { !$0.peutOuvrir || expanded.contains($0.id) }
    }

    public var nombreFiches: Int { root?.leaves ?? 0 }
    public var nombreBlocs: Int { root?.children.count ?? 0 }
    public var nombreSalons: Int {
        allNodes.filter { $0.kind == .branche && !$0.children.isEmpty && $0.estUnSalonDeFiches }.count
    }

    /// Les bulles grossissent légèrement quand on dézoome, pour rester lisibles
    /// (`--bs` côté web).
    public var bubbleBreathScale: Double {
        min(Self.bsMax, max(1, (Self.bsRef / Double(scale)).squareRoot()))
    }

    /// Épaisseur de trait à utiliser pour les liens/anneaux dessinés dans un
    /// repère monde mis à l'échelle par la caméra, pour rester visuellement
    /// constante à l'écran quel que soit le zoom (compense le `scaleBy` du
    /// `Canvas` — même idée que `strokeWidth = 1.6 / view.z` côté web).
    public var epaisseurLiens: CGFloat { max(0.4, 1.6 / scale) }
    public var epaisseurAnneaux: CGFloat { max(0.3, 1 / scale) }
    public var tiretsAnneaux: [CGFloat] { [max(0.3, 1.5 / scale), max(1, 9 / scale)] }

    /// Rayons des anneaux à dessiner, un par profondeur actuellement visible
    /// (hors fiches) — équivalent de `updateOrbits()`.
    public var anneauxVisibles: [Double] {
        let depths = Set(
            allNodes
                .filter { $0.depth > 0 && $0.kind != .carte && (positions[$0.id]?.visible ?? false) }
                .map(\.depth)
        )
        return depths.sorted().map(ringR)
    }

    public var centreCadre: CGPoint { CGPoint(x: viewportArea.midX, y: viewportArea.midY) }

    // MARK: - Ouverture en cascade

    public func toggle(_ n: UniversNode) {
        guard n.peutOuvrir else { return }
        filtre = nil
        withLayoutAnimation {
            if expanded.contains(n.id) {
                collapse(n)
            } else {
                expanded.insert(n.id)
            }
            layout()
        }
        if expanded.contains(n.id) { ensureVisible(n) }
    }

    private func collapse(_ n: UniversNode) {
        expanded.remove(n.id)
        for c in n.children { collapse(c) }
    }

    public func openAll() {
        filtre = nil
        withLayoutAnimation {
            for n in allNodes where n.peutOuvrir { expanded.insert(n.id) }
            layout()
        }
        fitVisible()
    }

    public func closeAll(wide: Bool) {
        filtre = nil
        withLayoutAnimation { setInitialOpen(wide: wide) }
        fitVisible()
    }

    /// Ouvre le chemin jusqu'à une bulle et l'amène à l'écran — recherche et
    /// liens profonds s'en servent (équivalent de `reveal()`).
    public func reveal(_ n: UniversNode) {
        filtre = nil
        withLayoutAnimation {
            for a in n.ancetres { expanded.insert(a.id) }
            if n.peutOuvrir { expanded.insert(n.id) }
            layout()
        }
        pingedNodeId = n.id
        Task { [self] in
            try? await Task.sleep(for: .seconds(3.4))
            if self.pingedNodeId == n.id { self.pingedNodeId = nil }
        }
        if n.kind == .carte, let parent = n.parent {
            fitTo([parent] + parent.children)
        } else {
            ensureVisible(n)
        }
    }

    /// `withAnimation` plutôt qu'une boucle `requestAnimationFrame` main :
    /// chaque bulle anime son `.position`/`.scaleEffect`/`.opacity` tout seule
    /// dès que `positions` change sous une transaction animée.
    private func withLayoutAnimation(_ body: () -> Void) {
        withAnimation(.easeOut(duration: Self.dureeAnimation), body)
    }

    // MARK: - Géométrie radiale (measure / share / place / placeCards / layout)

    private func ringR(_ depth: Int) -> Double {
        let idx = min(depth, Geometry.rings.count - 1)
        let extra = max(0, depth - Geometry.rings.count + 1)
        return (Geometry.rings[idx] + Double(extra) * 280) * ringScale
    }

    private enum Geometry {
        static let rings: [Double] = [0, 330, 620, 900, 1180, 1460, 1740]
        static let gap: Double = 32
        static let pitch: Double = UniversGeometry.taille(.carte) + 26
        static let rowGap: Double = 150
        static let maxRows = 4
        static let perRow = 5
    }

    @discardableResult
    private func measure(_ n: UniversNode, _ scratch: inout [String: LayoutScratch]) -> Double {
        let own = n.depth > 0 ? (UniversGeometry.taille(n.kind) + Geometry.gap) / ringR(n.depth) : 0
        guard expanded.contains(n.id), n.peutOuvrir else {
            scratch[n.id] = LayoutScratch(need: own)
            return own
        }
        if n.estUnSalonDeFiches {
            let k = n.children.count
            let rows = min(Geometry.maxRows, Int(ceil(Double(k) / Double(Geometry.perRow))))
            let perRow = Int(ceil(Double(k) / Double(rows)))
            let step = Geometry.pitch / ringR(n.depth + 1)
            let need = max(own, (Double(perRow) + (rows > 1 ? 0.5 : 0)) * step)
            scratch[n.id] = LayoutScratch(need: need, rows: rows, perRow: perRow, step: step)
            return need
        }
        // Boucle plutôt que `reduce` : un paramètre `inout` ne se capture pas
        // proprement dans une fermeture récursive.
        var childrenNeed = 0.0
        for c in n.children { childrenNeed += measure(c, &scratch) }
        let need = max(own, childrenNeed)
        scratch[n.id] = LayoutScratch(need: need)
        return need
    }

    /// Parts égales pour tous, sauf pour qui a besoin de plus.
    private func share(_ needs: [Double], total: Double) -> [Double] {
        guard !needs.isEmpty else { return [] }
        var fixed = Set<Int>()
        while true {
            let free = needs.indices.filter { !fixed.contains($0) }
            if free.isEmpty {
                let sum = needs.reduce(0, +)
                let denom = sum == 0 ? 1 : sum
                return needs.map { $0 * total / denom }
            }
            let fixedSum = fixed.reduce(0.0) { $0 + needs[$1] }
            let each = (total - fixedSum) / Double(free.count)
            let over = free.filter { needs[$0] > each + 1e-9 }
            if over.isEmpty {
                return needs.indices.map { fixed.contains($0) ? needs[$0] : each }
            }
            over.forEach { fixed.insert($0) }
        }
    }

    private func place(
        _ n: UniversNode, _ a0: Double, _ a1: Double,
        _ scratch: inout [String: LayoutScratch],
        _ tx: inout [String: Double], _ ty: inout [String: Double], _ angle: inout [String: Double]
    ) {
        let a = (a0 + a1) / 2
        angle[n.id] = a
        let r = ringR(n.depth)
        tx[n.id] = r * cos(a)
        ty[n.id] = r * sin(a)
        guard expanded.contains(n.id), n.peutOuvrir else { return }
        if n.estUnSalonDeFiches {
            placeCards(n, scratch, &tx, &ty, angle)
            return
        }
        let parts = share(n.children.map { scratch[$0.id]?.need ?? 0 }, total: a1 - a0)
        var cursor = a0
        for (i, c) in n.children.enumerated() {
            place(c, cursor, cursor + parts[i], &scratch, &tx, &ty, &angle)
            cursor += parts[i]
        }
    }

    private func placeCards(
        _ n: UniversNode, _ scratch: [String: LayoutScratch],
        _ tx: inout [String: Double], _ ty: inout [String: Double], _ angle: [String: Double]
    ) {
        guard let info = scratch[n.id], info.perRow > 0 else { return }
        let k = n.children.count
        let r0 = ringR(n.depth + 1)
        let stagger = info.rows > 1 ? 0.25 : 0.0
        let parentAngle = angle[n.id] ?? 0
        for (i, c) in n.children.enumerated() {
            let row = i / info.perRow
            let col = i % info.perRow
            let inRow = min(info.perRow, k - row * info.perRow)
            let sign = row % 2 != 0 ? stagger : -stagger
            let a = parentAngle + (Double(col) - Double(inRow - 1) / 2 + sign) * info.step
            tx[c.id] = (r0 + Double(row) * Geometry.rowGap) * cos(a)
            ty[c.id] = (r0 + Double(row) * Geometry.rowGap) * sin(a)
        }
    }

    private func layout() {
        guard let root else { return }

        var vis: [String: Bool] = [:]
        for n in allNodes {
            if let parent = n.parent {
                vis[n.id] = (vis[parent.id] ?? false) && expanded.contains(parent.id)
            } else {
                vis[n.id] = true
            }
        }

        ringScale = 1
        var scratch: [String: LayoutScratch] = [:]
        let room = Double.pi * 2 * 0.96
        let need = measure(root, &scratch)
        if need > room {
            ringScale = need / room
            scratch.removeAll()
            _ = measure(root, &scratch)
        }

        var tx: [String: Double] = [root.id: 0]
        var ty: [String: Double] = [root.id: 0]
        var angle: [String: Double] = [root.id: 0]

        if expanded.contains(root.id), !root.children.isEmpty {
            let parts = share(root.children.map { scratch[$0.id]?.need ?? 0 }, total: .pi * 2)
            var a = -Double.pi / 2 - parts[0] / 2
            for (i, c) in root.children.enumerated() {
                place(c, a, a + parts[i], &scratch, &tx, &ty, &angle)
                a += parts[i]
            }
        }

        // Une bulle cachée se replie dans son plus proche parent visible.
        for n in allNodes where n.id != root.id && vis[n.id] != true {
            var a = n.parent
            while let anc = a, vis[anc.id] != true { a = anc.parent }
            if let anc = a {
                tx[n.id] = tx[anc.id]
                ty[n.id] = ty[anc.id]
            }
        }

        for n in allNodes {
            let estVisible = vis[n.id] ?? false
            positions[n.id] = NodePosition(
                x: tx[n.id] ?? positions[n.id]?.x ?? 0,
                y: ty[n.id] ?? positions[n.id]?.y ?? 0,
                popScale: estVisible ? 1 : 0.3,
                opacity: estVisible ? 1 : 0,
                visible: estVisible
            )
        }
    }

    // MARK: - Caméra

    private func clampZ(_ z: CGFloat) -> CGFloat { min(Self.zMax, max(Self.zMin, z)) }

    public func viewportDidChange(to rect: CGRect) {
        viewportArea = rect
        if !userMoved { fitVisible(animate: false) }
    }

    private func camTo(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat, animate: Bool = true) {
        let clamped = clampZ(z)
        if animate {
            withAnimation(.easeOut(duration: Self.dureeAnimation)) {
                offset = CGSize(width: x, height: y)
                scale = clamped
            }
        } else {
            offset = CGSize(width: x, height: y)
            scale = clamped
        }
    }

    private func bbox(_ list: [UniversNode]) -> CGRect {
        guard !list.isEmpty else { return .zero }
        var x0 = Double.infinity, y0 = Double.infinity, x1 = -Double.infinity, y1 = -Double.infinity
        for n in list {
            let pos = positions[n.id] ?? NodePosition()
            let r = UniversGeometry.taille(n.kind) / 2 * Self.bsMax + 14
            x0 = min(x0, pos.x - r); x1 = max(x1, pos.x + r)
            y0 = min(y0, pos.y - r); y1 = max(y1, pos.y + r)
        }
        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    public func fitTo(_ list: [UniversNode], animate: Bool = true, maxZoom: CGFloat = UniversStore.zFitMax) {
        guard !list.isEmpty else { return }
        let b = bbox(list)
        let a = viewportArea
        guard b.width > 0, b.height > 0, a.width > 0, a.height > 0 else { return }
        let z = clampZ(min(a.width / CGFloat(b.width), a.height / CGFloat(b.height), maxZoom))
        camTo(a.midX - CGFloat(b.midX) * z, a.midY - CGFloat(b.midY) * z, z, animate: animate)
    }

    public func fitVisible(animate: Bool = true) {
        fitTo(allNodes.filter { positions[$0.id]?.visible == true }, animate: animate)
    }

    /// Après une ouverture : glisser juste ce qu'il faut pour voir la bulle et
    /// ses filles, ou dézoomer si besoin.
    public func ensureVisible(_ n: UniversNode) {
        let list = [n] + n.children.filter { positions[$0.id]?.visible == true }
        let b = bbox(list)
        let a = viewportArea
        let z = scale
        let sx0 = CGFloat(b.minX) * z + offset.width, sx1 = CGFloat(b.maxX) * z + offset.width
        let sy0 = CGFloat(b.minY) * z + offset.height, sy1 = CGFloat(b.maxY) * z + offset.height
        if sx1 - sx0 > a.width || sy1 - sy0 > a.height {
            fitTo(list)
            return
        }
        var dx: CGFloat = 0, dy: CGFloat = 0
        if sx0 < a.minX { dx = a.minX - sx0 } else if sx1 > a.maxX { dx = a.maxX - sx1 }
        if sy0 < a.minY { dy = a.minY - sy0 } else if sy1 > a.maxY { dy = a.maxY - sy1 }
        guard dx != 0 || dy != 0 else { return }
        camTo(offset.width + dx, offset.height + dy, z)
    }

    /// Zoom ancré à un point écran précis (pincement) : pas d'animation, pour
    /// suivre le doigt sans latence.
    public func zoomAt(_ point: CGPoint, factor: CGFloat) {
        let z = clampZ(scale * factor)
        let newX = point.x - (point.x - offset.width) * z / scale
        let newY = point.y - (point.y - offset.height) * z / scale
        offset = CGSize(width: newX, height: newY)
        scale = z
        userMoved = true
    }

    /// Zoom centré sur le cadre (boutons +/−), animé.
    public func zoomBy(_ factor: CGFloat) {
        let a = viewportArea
        let z = clampZ(scale * factor)
        userMoved = true
        camTo(a.midX - (a.midX - offset.width) * z / scale, a.midY - (a.midY - offset.height) * z / scale, z)
    }

    public func pan(by delta: CGSize) {
        offset.width += delta.width
        offset.height += delta.height
        userMoved = true
    }

    public func recenter() {
        userMoved = false
        fitVisible()
    }

    // MARK: - Filtres région / mission

    private func cardesCorrespondantes(filtreId: String, valeur: String) -> [UniversNode] {
        allNodes.filter { n in
            guard n.kind == .carte, let fiche = n.fiche else { return false }
            switch filtreId {
            case "region": return Carte.regionsOf(repere: fiche.repere).contains(valeur)
            case "mission": return fiche.tag.rawValue == valeur
            default: return false
            }
        }
    }

    /// Les valeurs possibles d'un filtre et le nombre de fiches qui s'y
    /// rattachent, triées comme dans `openFilter()` (compte décroissant, puis
    /// ordre alphabétique).
    public func compteurs(pourFiltre filtreId: String) -> [FiltreValeur] {
        guard let root else { return [] }
        var counts: [String: Int] = [:]
        UniversTreeBuilder.walk(root) { n in
            guard n.kind == .carte, let fiche = n.fiche else { return }
            let valeurs: [String] = filtreId == "region" ? Carte.regionsOf(repere: fiche.repere)
                : filtreId == "mission" ? [fiche.tag.rawValue] : []
            for v in valeurs { counts[v, default: 0] += 1 }
        }
        return counts
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map { FiltreValeur(valeur: $0.key, compte: $0.value) }
    }

    public func applyFilter(_ filtreId: String, valeur: String) {
        guard let root else { return }
        let matches = Set(cardesCorrespondantes(filtreId: filtreId, valeur: valeur))
        let keep = Set(matches.flatMap(\.ancetres)).union([root])
        withLayoutAnimation {
            expanded = [root.id]
            for c in matches { for a in c.ancetres { expanded.insert(a.id) } }
            layout()
        }
        filtre = ActiveFilter(
            filtreId: filtreId, valeur: valeur,
            correspondances: Set(matches.map(\.id)), conserver: Set(keep.map(\.id))
        )
        fitTo(Array(matches) + Array(keep))
    }

    public func clearFilter() {
        filtre = nil
    }

    /// Statut d'affichage d'un nœud sous le filtre actif : correspond-il
    /// exactement, ou doit-il au moins rester net (ancêtre d'une correspondance) ?
    public func apparenceFiltre(de n: UniversNode) -> (estCorrespondance: Bool, estAttenue: Bool) {
        guard let filtre else { return (false, false) }
        let match = filtre.correspondances.contains(n.id)
        let net = match || filtre.conserver.contains(n.id)
        return (match, !net)
    }

    // MARK: - Recherche tolérante

    private func oneEdit(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        let ac = Array(a), bc = Array(b)
        let la = ac.count, lb = bc.count
        if abs(la - lb) > 1 { return false }
        var i = 0, j = 0, edits = 0
        while i < la && j < lb {
            if ac[i] == bc[j] { i += 1; j += 1; continue }
            edits += 1
            if edits > 1 { return false }
            if la > lb { i += 1 } else if lb > la { j += 1 } else { i += 1; j += 1 }
        }
        return edits + (la - i) + (lb - j) <= 1
    }

    private func tokenScore(_ t: String, _ e: SearchEntry) -> Int {
        var best = 0
        for w in e.titre {
            if w == t { return 8 }
            if w.hasPrefix(t) { best = max(best, 6) }
            else if t.count >= 4 && (oneEdit(t, w) || oneEdit(t, String(w.prefix(t.count)))) { best = max(best, 4) }
        }
        if best > 0 { return best }
        for w in e.hay {
            if w.hasPrefix(t) { best = max(best, w == t ? 3 : 2) }
            else if t.count >= 5 && oneEdit(t, w) { best = max(best, 1) }
        }
        return best
    }

    /// Recherche tolérante (sans accents, une faute de frappe permise par mot) —
    /// jusqu'à 8 résultats, meilleur score puis ordre alphabétique.
    public func search(_ query: String) -> [UniversNode] {
        let toks = TextNormalization.words(query).filter { !Self.motsVides.contains($0) }
        guard !toks.isEmpty else { return [] }
        var scored: [(node: UniversNode, score: Int)] = []
        for e in searchIndex {
            var s = 0
            for t in toks {
                let v = tokenScore(t, e)
                if v == 0 { s = 0; break }
                s += v
            }
            guard s > 0 else { continue }
            scored.append((e.node, s + (e.node.kind == .carte ? 0 : 1)))
        }
        return scored
            .sorted {
                $0.score != $1.score
                    ? $0.score > $1.score
                    : $0.node.label.localizedStandardCompare($1.node.label) == .orderedAscending
            }
            .prefix(8)
            .map(\.node)
    }
}
