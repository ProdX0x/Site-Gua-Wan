import SwiftUI
import GuaWanCore

/// La carte radiale « L'Univers » — porte fidèlement, en SwiftUI, la
/// maquette `maquette/univers/univers.js` : une carte centrée sur « Vous »
/// qui déploie en éventail L'Esprit, La Création et Le Corps, jusqu'aux
/// fiches.
///
/// Autonome : crée son propre `UniversStore` et charge le contenu dans
/// `.task`. Les gestes (glisser pour déplacer, pincer pour zoomer) sont
/// branchés ici ; `UniversStore` n'expose que l'état caméra et les méthodes
/// pour le faire évoluer (voir le commentaire sur `UniversStore`).
public struct UniversMapView: View {
    @State private var store = UniversStore()
    @State private var selectedFiche: Fiche?
    @State private var showFilterSheet = false
    @State private var searchText = ""
    @State private var toastMessage: String?
    @State private var hintVisible = true
    @State private var lastDragTranslation: CGSize = .zero
    @State private var lastMagnification: CGFloat = 1

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                mapLayer
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .contentShape(Rectangle())
                    .gesture(dragGesture)
                    #if os(iOS) || os(macOS) || os(visionOS)
                    .gesture(magnifyGesture)
                    #endif

                chrome(largeur: geo.size.width, safeArea: geo.safeAreaInsets)

                if let toastMessage {
                    toastView(toastMessage)
                }
            }
            .ignoresSafeArea()
            .onChange(of: geo.size) { _, nouvelleTaille in
                store.viewportDidChange(to: cadreVisible(pour: nouvelleTaille, safeArea: geo.safeAreaInsets))
            }
            .task {
                await store.load()
                store.setInitialOpen(wide: geo.size.width > 720)
                store.viewportDidChange(to: cadreVisible(pour: geo.size, safeArea: geo.safeAreaInsets))
                store.fitVisible(animate: false)
            }
        }
        .background(GWColor.bg)
        .sheet(item: $selectedFiche) { fiche in
            FicheDetailView(fiche: fiche)
        }
        .sheet(isPresented: $showFilterSheet) {
            UniversFilterSheet(store: store)
        }
    }

    // MARK: - Calque de la carte

    private var mapLayer: some View {
        ZStack {
            GWColor.bg
            UniversLinkLayer(store: store)
            ForEach(store.tousLesNoeuds) { noeud in
                UniversBubbleView(node: noeud, store: store) { tapped in
                    gererTap(sur: tapped)
                }
            }
        }
    }

    // MARK: - Chrome (recherche, filtres, contrôles)

    @ViewBuilder
    private func chrome(largeur: CGFloat, safeArea: EdgeInsets) -> some View {
        let etroit = largeur <= 720
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                UniversSearchBar(store: store, text: $searchText) { noeud in
                    reveler(noeud)
                }
                HStack {
                    Spacer(minLength: 0)
                    Button {
                        showFilterSheet = true
                    } label: {
                        if etroit {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        } else {
                            Label("Filtrer", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    }
                    .buttonStyle(.pill)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, max(14, safeArea.top + 6))

            Spacer(minLength: 0)

            if let filtre = store.filtre {
                HStack {
                    Spacer(minLength: 0)
                    clearFilterPill(filtre)
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 10)
            } else if hintVisible, !etroit {
                HStack {
                    Spacer(minLength: 0)
                    hintBar
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 10)
            }

            HStack(alignment: .bottom) {
                Button(store.toutEstOuvert ? "Tout refermer" : "Tout ouvrir") {
                    if store.toutEstOuvert {
                        store.closeAll(wide: !etroit)
                    } else {
                        store.openAll()
                    }
                }
                .buttonStyle(.pill)

                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    Button { store.zoomBy(1.4) } label: { Image(systemName: "plus") }
                        .buttonStyle(RoundIconButtonStyle())
                    Button { store.zoomBy(1 / 1.4) } label: { Image(systemName: "minus") }
                        .buttonStyle(RoundIconButtonStyle())
                    Button { store.recenter() } label: { Image(systemName: "viewfinder") }
                        .buttonStyle(RoundIconButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, max(16, safeArea.bottom + 8))
        }
    }

    private func clearFilterPill(_ filtre: ActiveFilter) -> some View {
        let libelle = Carte.filtres.first { $0.id == filtre.filtreId }?.court ?? "Filtre"
        let n = filtre.correspondances.count
        return Button {
            store.clearFilter()
        } label: {
            HStack(spacing: 10) {
                Text("\(libelle) : \(filtre.valeur) · \(n) fiche\(n > 1 ? "s" : "")")
                Image(systemName: "xmark")
                    .padding(6)
                    .background(Color.white.opacity(0.18), in: Circle())
            }
        }
        .buttonStyle(PrimaryButtonStyle(tint: GWColor.accent))
    }

    /// Reflet de `#hint`/`hintText` dans univers.js.
    private var hintBar: some View {
        HStack(spacing: 10) {
            Text("\(store.nombreFiches) fiches · \(store.nombreSalons) salons · touchez une bulle pour explorer · glissez pour vous déplacer")
                .lineLimit(1)
            Button {
                hintVisible = false
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
        }
        .font(GWFont.mono(11.5))
        .foregroundStyle(GWColor.muted)
        .padding(.horizontal, 16)
        .frame(height: 38)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(GWColor.line, lineWidth: 1))
    }

    private func toastView(_ message: String) -> some View {
        VStack {
            Text(message)
                .font(GWFont.body(14))
                .foregroundStyle(GWColor.fg)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(GWColor.line, lineWidth: 1))
                .padding(.top, 80)
            Spacer(minLength: 0)
        }
        .allowsHitTesting(false)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Gestes

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { valeur in
                let delta = CGSize(
                    width: valeur.translation.width - lastDragTranslation.width,
                    height: valeur.translation.height - lastDragTranslation.height
                )
                lastDragTranslation = valeur.translation
                store.pan(by: delta)
            }
            .onEnded { _ in lastDragTranslation = .zero }
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .onChanged { valeur in
                let facteur = valeur / lastMagnification
                lastMagnification = valeur
                store.zoomAt(store.centreCadre, factor: facteur)
            }
            .onEnded { _ in lastMagnification = 1 }
    }
    #endif

    // MARK: - Actions

    /// Reflet de `onNodeClick()` dans univers.js.
    private func gererTap(sur noeud: UniversNode) {
        if noeud.kind == .carte, let fiche = noeud.fiche {
            selectedFiche = fiche
        } else if let verrou = noeud.verrou {
            afficherToast("\(noeud.label) · \(verrou)")
        } else if let aVenir = noeud.aVenir {
            afficherToast("\(noeud.label) · \(aVenir)")
        } else {
            store.toggle(noeud)
        }
    }

    /// Reflet de `reveal()` : révélé par la recherche, puis la fiche s'ouvre
    /// après un court délai pour laisser voir le chemin parcouru.
    private func reveler(_ noeud: UniversNode) {
        store.reveal(noeud)
        guard noeud.kind == .carte, let fiche = noeud.fiche else { return }
        Task {
            try? await Task.sleep(for: .seconds(0.95))
            selectedFiche = fiche
        }
    }

    private func afficherToast(_ message: String) {
        withAnimation { toastMessage = message }
        Task {
            try? await Task.sleep(for: .seconds(3.6))
            if toastMessage == message { withAnimation { toastMessage = nil } }
        }
    }

    /// Reflet de `area()` dans univers.js : la zone dans laquelle la carte
    /// doit tenir, hors recherche/contrôles — approximée ici par des marges
    /// fixes plutôt que mesurées sur le vrai chrome rendu.
    private func cadreVisible(pour taille: CGSize, safeArea: EdgeInsets) -> CGRect {
        let etroit = taille.width <= 720
        let haut = (etroit ? 118 : 96) + safeArea.top
        let bas = (etroit ? 70 : 86) + safeArea.bottom
        let droite = (etroit ? 64 : 82) + safeArea.trailing
        let gauche: CGFloat = 16 + safeArea.leading
        return CGRect(
            x: gauche, y: haut,
            width: max(10, taille.width - gauche - droite),
            height: max(10, taille.height - haut - bas)
        )
    }
}

/// Petit bouton rond pour les contrôles de caméra (zoom/recentrer) — pas
/// d'équivalent dans `ButtonStyles.swift` partagé, propre à cette carte.
private struct RoundIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .frame(width: 46, height: 46)
            .background(.thinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(GWColor.lineStrong, lineWidth: 1))
            .foregroundStyle(GWColor.fg)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
