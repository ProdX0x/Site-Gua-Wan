import SwiftUI
import GuaWanCore

/// L'annuaire des Humains — reflet de `viewDir()`/`renderDir()` dans la
/// maquette web. En l'absence de backend, la liste se limite au créateur et
/// à quelques profils fictifs déclarés ici même (voir `membresDémonstration`) ;
/// `Social.swift` n'a pas besoin d'en savoir plus pour l'instant.
public struct DirectoryView: View {
    @State private var recherche = ""
    @State private var voieFiltre: String?

    private let membresDémonstration: [Member] = [
        .createur,
        Member(id: "camille", name: "Camille Rousseau", initials: "CR", city: "Lyon, France",
               voies: ["esprit", "corps"], online: true,
               bio: "Passionnée de méditation et de philosophie stoïcienne."),
        Member(id: "hugo", name: "Hugo Lefèvre", initials: "HL", city: "Montréal, Canada",
               voies: ["creation"], club: true,
               bio: "Musicien amateur, en quête de nouvelles inspirations."),
        Member(id: "mei", name: "Mei Tanaka", initials: "MT", city: "Kyoto, Japon",
               voies: ["esprit", "creation", "corps"], online: true,
               bio: "Calligraphe, pratique le zazen chaque matin."),
        Member(id: "ines", name: "Inès Dubois", initials: "ID", city: "Marseille, France",
               voies: ["corps"],
               bio: "Danseuse, explore le mouvement et les sens."),
    ]

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                entête
                outils
                résultats
            }
            .padding(20)
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(GWColor.bg)
        .navigationTitle("Annuaire")
    }

    private var entête: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Annuaire").font(GWFont.kicker).foregroundStyle(GWColor.muted)
            Text("Les Humains").font(GWFont.display(26))
            Text("Retrouvez les Humains par voie, et découvrez leur univers.")
                .font(GWFont.body(14))
                .foregroundStyle(GWColor.muted)
        }
    }

    // MARK: Outils de recherche

    private var outils: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(GWColor.muted)
                TextField("Un prénom, une ville, une passion…", text: $recherche)
            }
            .padding(10)
            .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 12))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button("Toutes les voies") { voieFiltre = nil }
                        .buttonStyle(ChipButtonStyle(actif: voieFiltre == nil))
                    ForEach(Carte.blocs) { bloc in
                        Button(bloc.label) { voieFiltre = bloc.id }
                            .buttonStyle(ChipButtonStyle(actif: voieFiltre == bloc.id, teinte: GWColor.couleur(nommee: bloc.couleur)))
                    }
                }
            }
        }
    }

    // MARK: Résultats

    private var membresFiltrés: [Member] {
        membresDémonstration.filter { membre in
            let correspondRecherche = recherche.isEmpty
                || membre.name.localizedCaseInsensitiveContains(recherche)
                || (membre.city?.localizedCaseInsensitiveContains(recherche) ?? false)
                || (membre.bio?.localizedCaseInsensitiveContains(recherche) ?? false)
            let correspondVoie = voieFiltre == nil || membre.voies.contains(voieFiltre ?? "")
            return correspondRecherche && correspondVoie
        }
    }

    private var résultats: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(membresFiltrés.count) Humain\(membresFiltrés.count > 1 ? "s" : "") sur \(membresDémonstration.count) · profils d'exemple")
                .font(GWFont.mono(11))
                .foregroundStyle(GWColor.muted)
            if membresFiltrés.isEmpty {
                VStack(spacing: 12) {
                    Enso(seDessine: true).frame(width: 70, height: 70)
                    Text("Aucun Humain ne correspond. Essayez une autre recherche.")
                        .foregroundStyle(GWColor.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
                    ForEach(membresFiltrés) { membre in
                        NavigationLink { ProfileView(member: membre) } label: {
                            carteMembre(membre)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func carteMembre(_ membre: Member) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                avatar(membre)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(membre.name).font(GWFont.body(15, weight: .semibold))
                        if membre.club {
                            Text("今")
                                .font(GWFont.body(10, weight: .semibold))
                                .foregroundStyle(GWColor.onColor)
                                .padding(3)
                                .background(GWColor.gold, in: Circle())
                        }
                    }
                    Text(membre.creator ? "Créateur de Guà Wàn" : (membre.city ?? ""))
                        .font(GWFont.mono(11))
                        .foregroundStyle(GWColor.muted)
                }
            }
            if let bio = membre.bio {
                Text(bio).font(GWFont.body(13)).foregroundStyle(GWColor.muted).lineLimit(2)
            }
            HStack(spacing: 6) {
                ForEach(membre.voies, id: \.self) { voieId in
                    if let bloc = Carte.blocs.first(where: { $0.id == voieId }) {
                        Text(bloc.label)
                            .font(GWFont.mono(10.5))
                            .foregroundStyle(GWColor.couleur(nommee: bloc.couleur))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(GWColor.couleur(nommee: bloc.couleur).opacity(0.12), in: Capsule())
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func avatar(_ membre: Member) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Text(membre.initials)
                .font(GWFont.body(14, weight: .semibold))
                .foregroundStyle(GWColor.onColor)
                .frame(width: 44, height: 44)
                .background(membre.voies.first.map { GWColor.couleur(nommee: $0) } ?? GWColor.accent, in: Circle())
            if membre.online {
                Circle()
                    .fill(GWColor.ok)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().strokeBorder(GWColor.bg, lineWidth: 2))
            }
        }
    }
}
