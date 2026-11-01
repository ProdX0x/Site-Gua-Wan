import SwiftUI
import GuaWanCore

/// La page d'accueil : hero avec l'ensō, les trois voies, le mot du créateur
/// épinglé, et un aperçu des dernières fiches — reflet de `viewAccueil()`
/// dans la maquette web.
public struct HomeView: View {
    @State private var fiches: [Fiche] = []
    @State private var enChargement = true

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                hero
                voies
                motDuCréateur
                dernièresFiches
            }
            .padding(20)
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(GWColor.bg)
        .navigationTitle("Accueil")
        .task { await chargerFiches() }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Enso(seDessine: true)
                .frame(width: 110, height: 110)
            Text("Bienvenue, Humain")
                .font(GWFont.kicker)
                .foregroundStyle(GWColor.muted)
            Text("\(Carte.racineSousTitre).")
                .font(GWFont.display(28))
                .foregroundStyle(GWColor.fg)
            Text("« L'éveil de l'esprit commence par l'éveil du corps. »")
                .font(GWFont.citation)
                .foregroundStyle(GWColor.muted)
            HStack(spacing: 12) {
                NavigationLink("Rejoindre les Humains") { SignupView() }
                    .buttonStyle(.primary)
                NavigationLink { ClubView() } label: {
                    Label("Ici et Maintenant", systemImage: "crown")
                }
                .buttonStyle(.ghost)
            }
        }
    }

    // MARK: Les trois voies

    private var voies: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Les trois voies", sousTitre: "Informer · Éduquer")
            ForEach(Carte.blocs) { bloc in
                NavigationLink { BlocFeedView(blocID: bloc.id) } label: {
                    voieCard(bloc)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func voieCard(_ bloc: Bloc) -> some View {
        HStack(spacing: 16) {
            Text(bloc.kanji)
                .font(GWFont.kanjiBloc)
                .foregroundStyle(GWColor.couleur(nommee: bloc.couleur))
                .frame(width: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(bloc.label).font(GWFont.body(17, weight: .semibold))
                Text("\(bloc.tousLesSalons.count) salons")
                    .font(GWFont.mono(12))
                    .foregroundStyle(GWColor.muted)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(GWColor.faint)
        }
        .padding(16)
        .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(GWColor.line))
    }

    // MARK: Mot du créateur

    private var motDuCréateur: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Le mot du créateur", sousTitre: nil)
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    avatar(Member.createur.initials, couleur: GWColor.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Member.createur.name).font(GWFont.body(15, weight: .semibold))
                        Text("Épinglé · Accueil").font(GWFont.mono(11)).foregroundStyle(GWColor.muted)
                    }
                    Spacer()
                }
                Text("Bienvenue sur Guà Wàn").font(GWFont.titreFiche)
                Text("Ici, chaque personne est le centre de son propre univers. Personne n'est au-dessus, personne n'est en dessous : il y a des univers qui s'expriment et s'épanouissent, côte à côte.")
                    .font(GWFont.body(15))
                Text("Guà Wàn a deux missions : informer et éduquer. Sur l'esprit, sur la création, sur le corps et les sens.")
                    .font(GWFont.body(15))
                    .foregroundStyle(GWColor.muted)
            }
            .padding(18)
            .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    // MARK: Dernières publications

    private var dernièresFiches: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Dernières publications", sousTitre: "Contenus d'exemple")
            if enChargement {
                ProgressView().frame(maxWidth: .infinity)
            } else if fiches.isEmpty {
                Text("Aucune fiche pour l'instant.").foregroundStyle(GWColor.muted)
            } else {
                ForEach(fiches) { fiche in
                    NavigationLink { FicheDetailView(fiche: fiche) } label: {
                        ficheApercu(fiche)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func ficheApercu(_ fiche: Fiche) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(fiche.salon.uppercased())
                .font(GWFont.mono(11))
                .foregroundStyle(GWColor.muted)
            Text(fiche.title).font(GWFont.body(16, weight: .semibold))
            Text(fiche.excerpt)
                .font(GWFont.body(14))
                .foregroundStyle(GWColor.muted)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Aides

    private func sectionTitle(_ titre: String, sousTitre: String?) -> some View {
        HStack {
            Text(titre).font(GWFont.titreSheet)
            Spacer()
            if let sousTitre {
                Text(sousTitre).font(GWFont.mono(11)).foregroundStyle(GWColor.muted)
            }
        }
    }

    private func avatar(_ initiales: String, couleur: Color) -> some View {
        Text(initiales)
            .font(GWFont.body(13, weight: .semibold))
            .foregroundStyle(GWColor.onColor)
            .frame(width: 36, height: 36)
            .background(couleur, in: Circle())
    }

    private func chargerFiches() async {
        do {
            let résultat = try await BundledJSONContentRepository().loadFiches()
            fiches = Array(résultat.fiches.prefix(6))
        } catch {
            fiches = []
        }
        enChargement = false
    }
}
