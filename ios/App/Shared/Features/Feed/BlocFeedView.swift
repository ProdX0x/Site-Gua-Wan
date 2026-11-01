import SwiftUI
import GuaWanCore

/// Le fil d'un bloc (L'Esprit / La Création / Le Corps) — port de `viewBloc(id)`
/// côté site principal : en-tête de bloc, chips de salons (avec leur compteur
/// de fiches), sélecteur de mission (Informer / Éduquer / Tout), puis la
/// liste filtrée des fiches en cartes cliquables.
///
/// Charge elle-même son contenu (comme demandé) plutôt que de dépendre d'un
/// store partagé : chaque instance a son propre `ContentRepository`, et
/// retrouve son bloc dans `Carte.blocs` à partir du seul `blocID` reçu.
public struct BlocFeedView: View {
    public let blocID: String

    public init(blocID: String) {
        self.blocID = blocID
    }

    @State private var repository = BundledJSONContentRepository()
    @State private var toutesLesFiches: [Fiche] = []
    @State private var chargementTermine = false
    @State private var salonSelectionne: String?
    @State private var missionSelectionnee: Mission?
    /// La fiche ouverte dans un `.sheet` — plus robuste qu'un `NavigationLink`
    /// ici : cette vue peut être poussée dans une navigation déjà existante
    /// (celle de L'Univers, par exemple), et une seconde `NavigationStack`
    /// imbriquée casserait sa mise en page.
    @State private var ficheOuverte: Fiche?

    private var bloc: Bloc? { Carte.blocs.first { $0.id == blocID } }
    private var couleurBloc: Color { GWColor.couleur(nommee: bloc?.couleur ?? "racine") }

    private var fichesDuBloc: [Fiche] {
        guard let bloc else { return [] }
        let nomsDeSalons = Set(bloc.tousLesSalons.map(\.nom))
        return toutesLesFiches.filter { nomsDeSalons.contains($0.salon) }
    }

    private var fichesFiltrees: [Fiche] {
        var fiches = fichesDuBloc
        if let salonSelectionne {
            fiches = fiches.filter { $0.salon == salonSelectionne }
        }
        if let missionSelectionnee {
            fiches = fiches.filter { $0.tag == missionSelectionnee }
        }
        return fiches
    }

    private func compte(pourSalonNomme nom: String) -> Int {
        fichesDuBloc.filter { $0.salon == nom }.count
    }

    public var body: some View {
        Group {
            if let bloc, bloc.aDesFiches {
                contenu(bloc)
            } else if let bloc {
                etatVide(
                    bloc: bloc,
                    titre: "\(bloc.label) arrive bientôt",
                    message: "Cette voie est prête mais encore vide : les premières fiches sont en préparation."
                )
            } else {
                etatVide(
                    bloc: nil,
                    titre: "Bloc introuvable",
                    message: "Ce bloc n'existe pas (ou plus) dans la taxonomie de Guà Wàn."
                )
            }
        }
        .task(id: blocID) { await charger() }
        .sheet(item: $ficheOuverte) { fiche in
            NavigationStack {
                FicheDetailView(fiche: fiche)
            }
        }
    }

    private func charger() async {
        do {
            let resultat = try await repository.loadFiches()
            toutesLesFiches = resultat.fiches
        } catch {
            toutesLesFiches = []
        }
        chargementTermine = true
    }

    // MARK: - Contenu (bloc avec des fiches)

    @ViewBuilder
    private func contenu(_ bloc: Bloc) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                entete(bloc)
                chipsSalons(bloc)
                selecteurMission
                listeFiches
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(GWColor.bg)
        .navigationTitle(bloc.label)
    }

    private func entete(_ bloc: Bloc) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(bloc.kanji)
                .font(GWFont.kanjiBloc)
                .foregroundStyle(couleurBloc)
            Text(bloc.label)
                .font(GWFont.titreSheet)
                .foregroundStyle(GWColor.fg)
            Text(
                "\(fichesDuBloc.count) fiche\(fichesDuBloc.count > 1 ? "s" : "") · "
                + "\(bloc.tousLesSalons.count) salon\(bloc.tousLesSalons.count > 1 ? "s" : "")"
            )
            .font(GWFont.mono(11.5))
            .tracking(1)
            .foregroundStyle(GWColor.muted)
        }
    }

    private func chipsSalons(_ bloc: Bloc) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    salonSelectionne = nil
                } label: {
                    Text("Tous les salons")
                }
                .buttonStyle(ChipButtonStyle(actif: salonSelectionne == nil, teinte: couleurBloc))

                ForEach(bloc.tousLesSalons, id: \.nom) { salon in
                    Button {
                        salonSelectionne = salon.nom
                    } label: {
                        HStack(spacing: 6) {
                            Text(salon.nom)
                            Text("\(compte(pourSalonNomme: salon.nom))")
                                .font(GWFont.mono(10.5))
                                .opacity(0.7)
                        }
                    }
                    .buttonStyle(ChipButtonStyle(actif: salonSelectionne == salon.nom, teinte: couleurBloc))
                }
            }
        }
    }

    private var selecteurMission: some View {
        HStack(spacing: 8) {
            missionBouton(titre: "Tout", mission: nil)
            ForEach(Mission.allCases) { mission in
                missionBouton(titre: mission.rawValue, mission: mission)
            }
        }
    }

    private func missionBouton(titre: String, mission: Mission?) -> some View {
        Button {
            missionSelectionnee = mission
        } label: {
            Text(titre).frame(maxWidth: .infinity)
        }
        .buttonStyle(ChipButtonStyle(actif: missionSelectionnee == mission, teinte: couleurBloc))
    }

    @ViewBuilder
    private var listeFiches: some View {
        if !chargementTermine {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else if let salonSelectionne, compte(pourSalonNomme: salonSelectionne) == 0 {
            etatSalonVide(nom: salonSelectionne)
        } else if fichesFiltrees.isEmpty {
            etatSansResultat
        } else {
            VStack(spacing: 12) {
                ForEach(fichesFiltrees) { fiche in
                    Button {
                        ficheOuverte = fiche
                    } label: {
                        FicheCardView(fiche: fiche)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - États vides

    /// Bloc entier sans contenu (La Création aujourd'hui) ou identifiant de
    /// bloc inconnu — même esprit que les blocs « maquette / à venir » du
    /// site d'origine : un message clair plutôt qu'une liste vide muette.
    private func etatVide(bloc: Bloc?, titre: String, message: String) -> some View {
        let teinte = bloc.map { GWColor.couleur(nommee: $0.couleur) } ?? GWColor.muted
        return VStack(spacing: 18) {
            Enso(couleurTrait: teinte.opacity(0.5), couleurPoint: nil)
                .frame(width: 120, height: 120)
            Text(titre)
                .font(GWFont.titreSheet)
                .foregroundStyle(GWColor.fg)
                .multilineTextAlignment(.center)
            Text(message)
                .font(GWFont.body(15))
                .foregroundStyle(GWColor.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GWColor.bg)
    }

    /// Un salon qui existe dans la taxonomie mais n'a encore aucune fiche
    /// (ex. un salon tout juste ajouté à `Carte`).
    private func etatSalonVide(nom: String) -> some View {
        VStack(spacing: 14) {
            Enso(couleurTrait: couleurBloc.opacity(0.4), couleurPoint: nil)
                .frame(width: 90, height: 90)
            Text("Salon en préparation")
                .font(GWFont.body(16, weight: .semibold))
                .foregroundStyle(GWColor.fg)
            Text("« \(nom) » existe déjà, mais aucune fiche n'y a encore été publiée.")
                .font(GWFont.body(14.5))
                .foregroundStyle(GWColor.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
    }

    /// La sélection courante (salon + mission) ne laisse aucune fiche, mais
    /// le salon lui-même n'est pas vide — juste ce filtre-ci.
    private var etatSansResultat: some View {
        VStack(spacing: 10) {
            Text("Aucune fiche pour ce filtre")
                .font(GWFont.body(16, weight: .semibold))
                .foregroundStyle(GWColor.fg)
            Text("Essayez « Tout » ou choisissez un autre salon.")
                .font(GWFont.body(14.5))
                .foregroundStyle(GWColor.muted)
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
    }
}
