import SwiftUI
import GuaWanCore

/// La coquille de navigation de l'app : une seule racine, deux présentations.
///
/// Le choix entre les deux ne repose pas seulement sur `#if os(...)` : sur
/// iOS, iPhone et iPad partagent la même plateforme mais pas la même mise en
/// page (barre d'onglets vs. barre latérale), donc on lit en plus
/// `horizontalSizeClass` — `.compact` (iPhone, iPad en split-view étroit) a
/// la barre d'onglets, `.regular` (iPad plein écran) la barre latérale.
/// macOS et visionOS n'ont pas cette notion et prennent toujours la barre
/// latérale ; tvOS n'a pas de notion de taille pertinente et prend toujours
/// la barre d'onglets (télécommande).
public struct RootView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State private var session = SessionStore()

    public init() {}

    public var body: some View {
        content
            .tint(GWColor.accent)
            .environment(session)
    }

    @ViewBuilder
    private var content: some View {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            CompactShell()
        } else {
            ExpandedShell()
        }
        #elseif os(tvOS)
        CompactShell()
        #else
        ExpandedShell()
        #endif
    }
}

/// Les sections de l'app, dans l'ordre où elles apparaissent à plat dans la
/// barre latérale (iPad/Mac/visionOS). La barre d'onglets (iPhone/tvOS)
/// n'affiche que les cinq premières ; les suivantes sont regroupées dans
/// « Plus ».
enum Destination: String, Identifiable, CaseIterable, Hashable {
    case accueil, esprit, creation, corps, univers, oracle, club, lives, calendrier, annuaire, profil

    var id: String { rawValue }

    var label: String {
        switch self {
        case .accueil: "Accueil"
        case .esprit: Carte.esprit.label
        case .creation: Carte.creation.label
        case .corps: Carte.corps.label
        case .univers: Carte.titreUnivers
        case .oracle: "L'Oracle"
        case .club: "Ici et Maintenant"
        case .lives: "Les Lives"
        case .calendrier: "Calendrier"
        case .annuaire: "Annuaire"
        case .profil: "Profil"
        }
    }

    var icon: String {
        switch self {
        case .accueil: "house"
        case .esprit: "sparkles"
        case .creation: "paintpalette"
        case .corps: "figure.mind.and.body"
        case .univers: "circle.hexagongrid"
        case .oracle: "wand.and.stars"
        case .club: "crown"
        case .lives: "dot.radiowaves.left.and.right"
        case .calendrier: "calendar"
        case .annuaire: "person.3"
        case .profil: "person.crop.circle"
        }
    }

    /// Les cinq onglets visibles directement sur iPhone/tvOS ; le reste vit dans « Plus ».
    static let onglets: [Destination] = [.accueil, .esprit, .creation, .corps, .univers]
    static let regroupées: [Destination] = [.oracle, .club, .lives, .calendrier, .annuaire, .profil]
}

/// Le contenu d'une section, partagé par les deux présentations. Chaque
/// destination porte sa propre pile de navigation (`NavigationStack`) : les
/// vues de fonctionnalité (ex. `BlocFeedView`) n'ont donc pas à fournir la
/// leur, elles s'y poussent simplement via `NavigationLink`.
struct DestinationView: View {
    let destination: Destination

    var body: some View {
        switch destination {
        case .accueil: HomeView()
        case .esprit: BlocFeedView(blocID: Carte.esprit.id)
        case .creation: BlocFeedView(blocID: Carte.creation.id)
        case .corps: BlocFeedView(blocID: Carte.corps.id)
        case .univers: UniversMapView()
        case .oracle: OracleView()
        case .club: ClubView()
        case .lives: LivesView()
        case .calendrier: CalendarView()
        case .annuaire: DirectoryView()
        case .profil: ProfilDestinationView()
        }
    }
}

/// « Profil » dépend de l'état de connexion, purement local : en l'absence
/// de membre courant, on propose de continuer en invité ou de s'inscrire,
/// plutôt que d'afficher un profil qui n'existe pas encore.
private struct ProfilDestinationView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        if let member = session.member {
            ProfileView(member: member)
        } else {
            VStack(spacing: 18) {
                Enso(seDessine: true)
                    .frame(width: 96, height: 96)
                Text("Vous n'êtes pas encore connecté")
                    .font(GWFont.titreSheet)
                Text("Continuez en invité pour explorer un profil de démonstration, ou créez votre compte.")
                    .font(GWFont.body(15))
                    .foregroundStyle(GWColor.muted)
                    .multilineTextAlignment(.center)
                Button("Continuer en invité") { session.connecterInvité() }
                    .buttonStyle(.primary)
                NavigationLink("Créer mon compte") { SignupView() }
                    .buttonStyle(.ghost)
            }
            .padding(32)
            .frame(maxWidth: 420)
            .navigationTitle("Profil")
        }
    }
}

/// iPhone / tvOS : barre d'onglets, avec les sections secondaires regroupées.
private struct CompactShell: View {
    var body: some View {
        TabView {
            ForEach(Destination.onglets) { destination in
                NavigationStack {
                    DestinationView(destination: destination)
                }
                .tabItem { Label(destination.label, systemImage: destination.icon) }
            }
            PlusShell()
                .tabItem { Label("Plus", systemImage: "ellipsis.circle") }
        }
        .background(GWColor.bg)
    }
}

/// Le contenu de l'onglet « Plus » : une liste vers les sections qui n'ont
/// pas leur propre onglet.
private struct PlusShell: View {
    var body: some View {
        NavigationStack {
            List(Destination.regroupées) { destination in
                NavigationLink(value: destination) {
                    Label(destination.label, systemImage: destination.icon)
                }
            }
            .navigationTitle("Plus")
            .navigationDestination(for: Destination.self) { destination in
                DestinationView(destination: destination)
            }
        }
    }
}

/// iPad / Mac / visionOS : barre latérale à plat, détail à droite.
private struct ExpandedShell: View {
    @State private var sélection: Destination? = .accueil

    var body: some View {
        NavigationSplitView {
            List(Destination.allCases, selection: $sélection) { destination in
                Label(destination.label, systemImage: destination.icon)
                    .tag(destination)
            }
            .navigationTitle("Guà Wàn")
        } detail: {
            NavigationStack {
                DestinationView(destination: sélection ?? .accueil)
            }
        }
        .background(GWColor.bg)
    }
}
