import SwiftUI
import GuaWanCore

/// Les lives — reflet de `viewLives()` dans la maquette web : un lecteur
/// simulé (aucun flux vidéo réel), le programme de la semaine et un rappel.
public struct LivesView: View {
    @State private var enDirectSimulé = false
    @State private var rappelActivé = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                entête
                lecteur
                programme
                avertissement
            }
            .padding(20)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(GWColor.bg)
        .navigationTitle("Les Lives")
    }

    private var entête: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Les Lives").font(GWFont.kicker).foregroundStyle(GWColor.muted)
            Text("En direct, chaque semaine.").font(GWFont.display(28))
            Text("Trois rendez-vous publics pour informer et éduquer, et des lives privés pour le club.")
                .font(GWFont.body(14))
                .foregroundStyle(GWColor.muted)
        }
    }

    // MARK: Lecteur simulé

    private var lecteur: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20).fill(GWColor.screen)
                Enso(seDessine: true, couleurTrait: GWColor.surface.opacity(0.5), couleurPoint: nil, largeurTrait: 6)
                    .padding(50)
                insigne
                VStack {
                    Spacer()
                    HStack {
                        Text(enDirectSimulé ? "Le flux vidéo s'affichera ici" : "Mardi · 20:00 · heure de Paris")
                            .font(GWFont.mono(12))
                            .foregroundStyle(GWColor.surface.opacity(0.85))
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("L'éveil des sens · Le toucher").font(GWFont.body(16, weight: .semibold))
                    Text("Le Corps · Éduquer · avec Stéphane « Steve » Saulnier")
                        .font(GWFont.body(13))
                        .foregroundStyle(GWColor.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    if !enDirectSimulé {
                        if rappelActivé {
                            Button("Rappel activé") { rappelActivé = false }.buttonStyle(.ghost)
                        } else {
                            Button("Me le rappeler") { rappelActivé = true }.buttonStyle(.primary)
                        }
                    }
                    Button(enDirectSimulé ? "Arrêter la simulation" : "Simuler le direct") {
                        enDirectSimulé.toggle()
                    }
                    .buttonStyle(.ghost)
                }
            }
        }
    }

    private var insigne: some View {
        Group {
            if enDirectSimulé {
                Label("En direct", systemImage: "dot.radiowaves.left.and.right")
                    .font(GWFont.mono(11, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(GWColor.accent, in: Capsule())
            } else {
                Text("Prochain live")
                    .font(GWFont.mono(11, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.45), in: Capsule())
            }
        }
        .padding(14)
    }

    // MARK: Programme de la semaine

    private var programme: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Le programme").font(GWFont.titreSheet)
                Spacer()
                Text("Chaque semaine").font(GWFont.mono(11)).foregroundStyle(GWColor.muted)
            }
            ForEach(LiveEvent.programme) { évènement in
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(nomJour(évènement.weekday)).font(GWFont.body(13, weight: .semibold))
                            Text(heureTexte(évènement)).font(GWFont.mono(11)).foregroundStyle(GWColor.muted)
                        }
                        .frame(width: 72, alignment: .leading)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(évènement.title).font(GWFont.body(15, weight: .medium))
                                if évènement.clubOnly {
                                    Text("今")
                                        .font(GWFont.body(10, weight: .semibold))
                                        .foregroundStyle(GWColor.onColor)
                                        .padding(4)
                                        .background(GWColor.gold, in: Circle())
                                }
                            }
                            if let blocId = évènement.blocId, let bloc = Carte.blocs.first(where: { $0.id == blocId }) {
                                Text(bloc.label)
                                    .font(GWFont.mono(11))
                                    .foregroundStyle(GWColor.couleur(nommee: bloc.couleur))
                            } else {
                                Text("Visio · Ici et Maintenant")
                                    .font(GWFont.mono(11))
                                    .foregroundStyle(GWColor.gold)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    Divider().overlay(GWColor.line)
                }
            }
        }
    }

    private func nomJour(_ weekday: Int) -> String {
        let noms = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
        guard (1...7).contains(weekday) else { return "" }
        return noms[weekday - 1]
    }

    private func heureTexte(_ évènement: LiveEvent) -> String {
        String(format: "%02dh%02d", évènement.hour, évènement.minute)
    }

    private var avertissement: some View {
        Text("Maquette : le flux vidéo, le chat en direct et les rappels par notification seront branchés avec le vrai site.")
            .font(GWFont.mono(10.5))
            .foregroundStyle(GWColor.faint)
    }
}
