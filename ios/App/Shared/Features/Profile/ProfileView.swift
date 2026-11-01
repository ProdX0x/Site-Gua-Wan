import SwiftUI
import GuaWanCore

/// Le profil d'un membre — reflet de `viewProfil()` dans la maquette web,
/// simplifié : pas d'onglets « Publications »/« Activité » tant qu'il n'y a
/// pas de vraies publications par membre, seulement ce que `Member` porte
/// déjà. Suivre/ne plus suivre reste un état purement local.
public struct ProfileView: View {
    let member: Member
    @Environment(SessionStore.self) private var session
    @State private var suivi = false

    public init(member: Member) {
        self.member = member
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                entête
                actions
                voies
                biographie
            }
            .padding(20)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(GWColor.bg)
        .navigationTitle(member.name)
    }

    private var estMoi: Bool { session.member?.id == member.id }

    // MARK: En-tête

    private var entête: some View {
        HStack(alignment: .top, spacing: 16) {
            avatar
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(member.name).font(GWFont.titreSheet)
                    if member.club {
                        Text("今")
                            .font(GWFont.body(11, weight: .semibold))
                            .foregroundStyle(GWColor.onColor)
                            .padding(5)
                            .background(GWColor.gold, in: Circle())
                    }
                }
                if member.creator {
                    Text("Créateur de Guà Wàn").font(GWFont.mono(11)).foregroundStyle(GWColor.accent)
                }
                if let city = member.city {
                    Label(city, systemImage: "mappin.and.ellipse")
                        .font(GWFont.mono(11))
                        .foregroundStyle(GWColor.muted)
                }
                if member.online {
                    Label("En ligne", systemImage: "circle.fill")
                        .font(GWFont.mono(11))
                        .foregroundStyle(GWColor.ok)
                }
            }
            Spacer()
        }
    }

    private var avatar: some View {
        Text(member.initials)
            .font(GWFont.display(22))
            .foregroundStyle(GWColor.onColor)
            .frame(width: 72, height: 72)
            .background(member.voies.first.map { GWColor.couleur(nommee: $0) } ?? GWColor.accent, in: Circle())
    }

    // MARK: Actions

    @ViewBuilder
    private var actions: some View {
        if estMoi {
            Text("C'est votre profil.")
                .font(GWFont.mono(11))
                .foregroundStyle(GWColor.muted)
        } else if suivi {
            Button("Suivi ✓") { suivi = false }
                .buttonStyle(.ghost)
        } else {
            Button("Suivre") { suivi = true }
                .buttonStyle(.primary)
        }
    }

    // MARK: Voies suivies

    private var voies: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Voies suivies").font(GWFont.body(14, weight: .semibold)).foregroundStyle(GWColor.muted)
            if member.voies.isEmpty {
                Text("Aucune voie suivie pour l'instant.")
                    .font(GWFont.body(13))
                    .foregroundStyle(GWColor.faint)
            } else {
                HStack(spacing: 8) {
                    ForEach(member.voies, id: \.self) { voieId in
                        if let bloc = Carte.blocs.first(where: { $0.id == voieId }) {
                            HStack(spacing: 4) {
                                Text(bloc.kanji)
                                Text(bloc.label)
                            }
                            .font(GWFont.mono(11))
                            .foregroundStyle(GWColor.couleur(nommee: bloc.couleur))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(GWColor.couleur(nommee: bloc.couleur).opacity(0.12), in: Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: Bio

    private var biographie: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("À propos").font(GWFont.body(14, weight: .semibold)).foregroundStyle(GWColor.muted)
            Text(member.bio ?? "Cette personne n'a pas encore écrit de bio.")
                .font(GWFont.body(15))
                .foregroundStyle(member.bio == nil ? GWColor.faint : GWColor.fg)
        }
    }
}
