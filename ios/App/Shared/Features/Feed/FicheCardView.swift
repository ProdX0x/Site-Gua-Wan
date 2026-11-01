import SwiftUI
import GuaWanCore

/// Une carte résumée pour une fiche, posée dans le fil d'un bloc
/// (`BlocFeedView`) — l'équivalent compact de `postHTML(p)` côté site
/// principal : puce de couleur, titre court, extrait tronqué, étiquette de
/// mission, temps de lecture.
///
/// Vue purement présentationnelle : elle ne gère ni navigation ni ouverture
/// de fiche elle-même (son initialiseur ne prend que la fiche à afficher).
/// C'est à l'appelant de la rendre cliquable — `BlocFeedView` l'enveloppe
/// dans un bouton qui ouvre `FicheDetailView` en `.sheet`.
public struct FicheCardView: View {
    public let fiche: Fiche

    public init(fiche: Fiche) {
        self.fiche = fiche
    }

    private var bloc: Bloc? {
        Carte.blocs.first { bloc in bloc.tousLesSalons.contains { $0.nom == fiche.salon } }
    }
    private var salon: Salon? { bloc?.tousLesSalons.first { $0.nom == fiche.salon } }
    private var couleurBloc: Color { GWColor.couleur(nommee: bloc?.couleur ?? "racine") }
    private var couleurMission: Color { fiche.tag == .eduquer ? GWColor.gold : GWColor.esprit }

    public var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(couleurBloc.opacity(0.14))
                Image(systemName: sfSymbol(pour: salon?.icon ?? bloc?.icon ?? ""))
                    .font(.system(size: 15))
                    .foregroundStyle(couleurBloc)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(fiche.tag.rawValue.uppercased())
                        .font(GWFont.mono(9.5))
                        .tracking(1)
                        .foregroundStyle(couleurMission)
                    Spacer(minLength: 8)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("\(fiche.readingMinutes) min")
                    }
                    .font(GWFont.mono(10))
                    .foregroundStyle(GWColor.faint)
                }

                Text(fiche.shortTitle)
                    .font(GWFont.body(16.5, weight: .semibold))
                    .foregroundStyle(GWColor.fg)
                    .lineLimit(2)

                Text(fiche.excerpt)
                    .font(GWFont.body(14))
                    .foregroundStyle(GWColor.muted)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(16)
        .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(GWColor.line, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
