import SwiftUI
import GuaWanCore
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// La page détaillée d'une fiche de contenu — port de `openCard()` dans
/// `maquette/univers/univers.js` : en-tête (mission, repère, titre, résumé),
/// « L'essentiel », « Pourquoi c'est un plaisir », citation mise en exergue,
/// corps dépliable, « À essayer », trois tuiles résumé, vidéos/sources en
/// chips, pied avec fil d'Ariane et copie du lien.
///
/// Conçue pour s'adapter à son conteneur plutôt qu'à une plateforme : elle se
/// présente aussi bien dans un `.sheet` (iPhone/iPad), poussée dans une
/// `NavigationStack`/`NavigationSplitView` (Mac) qu'en grande fenêtre
/// (visionOS) — pas de largeur figée, juste une largeur de lecture
/// confortable centrée (comme `.sheet{width:min(600px,100%)}` côté web).
public struct FicheDetailView: View {
    public let fiche: Fiche

    @State private var articleOuvert = false

    public init(fiche: Fiche) {
        self.fiche = fiche
    }

    private var bloc: Bloc? { blocDeLaFiche(fiche) }
    private var salon: Salon? { bloc?.tousLesSalons.first { $0.nom == fiche.salon } }
    private var couleurBloc: Color { GWColor.couleur(nommee: bloc?.couleur ?? "racine") }

    private var minutesLecture: Int { fiche.readingMinutes }
    /// Même seuil que `openCard()` : 1 point jusqu'à 3 min, 2 jusqu'à 6, 3 au-delà.
    private var pointsLecture: Int { minutesLecture <= 3 ? 1 : (minutesLecture <= 6 ? 2 : 3) }

    private var couleurMission: Color { fiche.tag == .eduquer ? GWColor.gold : GWColor.esprit }

    /// La citation débarrassée de ses guillemets d'origine : on les repose
    /// nous-mêmes autour, avec une espace fine insécable (même rendu que
    /// `quote.replace(/^[«"\s]+|[»"\s]+$/g, "")` côté web).
    private var citationNettoyee: String? {
        guard let texte = fiche.citation?.texte else { return nil }
        let nettoyee = texte.trimmingCharacters(in: CharacterSet(charactersIn: "«»\"\u{00A0} \n\t"))
        return nettoyee.isEmpty ? nil : nettoyee
    }

    private var filDAriane: String? {
        guard let bloc else { return nil }
        return "\(bloc.label) › \(fiche.salon)"
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                entete

                if let cles = fiche.cles, !cles.isEmpty {
                    essentiel(cles)
                }
                if let plaisir = fiche.plaisir, !plaisir.isEmpty {
                    pourquoiPlaisir(plaisir)
                }
                if let citation = fiche.citation, let texte = citationNettoyee {
                    citationView(citation, texte: texte)
                }

                lireArticle

                if !fiche.pratique.isEmpty {
                    aEssayer
                }

                tuiles

                if let videos = fiche.videos, !videos.isEmpty {
                    aRegarder(videos)
                }
                if !fiche.sources.isEmpty {
                    sources
                }

                pied
            }
            .padding(24)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(GWColor.surface)
        .navigationTitle(fiche.shortTitle)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - En-tête

    private var entete: some View {
        HStack(alignment: .top, spacing: 18) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [couleurBloc, couleurBloc.opacity(0.62)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: iconeFiche)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(GWColor.onColor)
                }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    missionBadge
                    if let repere = fiche.repere, !repere.isEmpty {
                        Text(repere)
                            .font(GWFont.mono(11))
                            .foregroundStyle(GWColor.muted)
                    }
                }
                Text(fiche.title)
                    .font(GWFont.titreFiche)
                    .foregroundStyle(GWColor.fg)
                Text(fiche.excerpt)
                    .font(GWFont.body(15.5))
                    .foregroundStyle(GWColor.muted)
            }
        }
    }

    private var iconeFiche: String {
        sfSymbol(pour: salon?.icon ?? bloc?.icon ?? "")
    }

    private var missionBadge: some View {
        Text(fiche.tag.rawValue.uppercased())
            .font(GWFont.mono(10.5))
            .tracking(1.2)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .overlay(Capsule().strokeBorder(couleurMission, lineWidth: 1))
            .foregroundStyle(couleurMission)
    }

    // MARK: - L'essentiel / Pourquoi c'est un plaisir / Citation

    private func kicker(_ texte: String) -> some View {
        Text(texte.uppercased())
            .font(GWFont.kicker)
            .tracking(1.6)
            .foregroundStyle(GWColor.muted)
    }

    private func essentiel(_ cles: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            kicker("L'essentiel")
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(cles.enumerated()), id: \.offset) { _, cle in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Circle()
                            .fill(couleurBloc)
                            .frame(width: 7, height: 7)
                            .alignmentGuide(.firstTextBaseline) { d in d.height * 0.75 }
                        Text(cle)
                            .font(GWFont.body(15.5))
                            .foregroundStyle(GWColor.fg)
                    }
                }
            }
        }
    }

    private func pourquoiPlaisir(_ plaisir: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            kicker("Pourquoi c'est un plaisir")
            Text(plaisir)
                .font(GWFont.body(15.5))
                .foregroundStyle(GWColor.fg)
        }
    }

    private func citationView(_ citation: Citation, texte: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("«\u{00A0}\(texte)\u{00A0}»")
                .font(GWFont.citation)
                .foregroundStyle(GWColor.fg)
            HStack(spacing: 4) {
                Text(citation.auteur)
                if let source = citation.source, !source.isEmpty {
                    Text(", \(source)").italic()
                }
            }
            .font(GWFont.body(13))
            .foregroundStyle(GWColor.muted)
        }
        .padding(.leading, 18)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(GWColor.gold)
                .frame(width: 2)
        }
    }

    // MARK: - Lire l'article

    private var lireArticle: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    articleOuvert.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Text("Lire l'article · \(minutesLecture) min")
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(articleOuvert ? 180 : 0))
                }
            }
            .buttonStyle(PrimaryButtonStyle(tint: couleurBloc))
            .accessibilityHint(articleOuvert ? "Replie l'article" : "Déplie l'article")

            if articleOuvert {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(fiche.body.enumerated()), id: \.offset) { _, paragraphe in
                        Text(paragraphe)
                            .font(GWFont.body(16))
                            .foregroundStyle(GWColor.fg)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - À essayer

    private var aEssayer: some View {
        VStack(alignment: .leading, spacing: 12) {
            kicker("À essayer")
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(fiche.pratique.enumerated()), id: \.offset) { index, etape in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("\(index + 1)")
                            .font(GWFont.mono(12, weight: .semibold))
                            .foregroundStyle(GWColor.onColor)
                            .frame(width: 24, height: 24)
                            .background(couleurBloc, in: Circle())
                            .alignmentGuide(.firstTextBaseline) { d in d.height * 0.78 }
                        Text(etape)
                            .font(GWFont.body(15.5))
                            .foregroundStyle(GWColor.fg)
                    }
                }
            }
        }
    }

    // MARK: - Tuiles résumé

    private var tuiles: some View {
        HStack(spacing: 10) {
            tuile(
                icone: fiche.tag == .eduquer ? "graduationcap.fill" : "newspaper.fill",
                etiquette: "Mission", valeur: fiche.tag.rawValue
            )
            tuileLecture
            tuile(
                icone: "checklist", etiquette: "À essayer",
                valeur: "\(fiche.pratique.count) étape\(fiche.pratique.count > 1 ? "s" : "")"
            )
        }
    }

    private var tuileLecture: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                ForEach(1...3, id: \.self) { i in
                    Circle()
                        .strokeBorder(couleurBloc, lineWidth: 1.5)
                        .overlay {
                            if i <= pointsLecture {
                                Circle().fill(couleurBloc).padding(1.5)
                            }
                        }
                        .frame(width: 9, height: 9)
                }
            }
            .frame(height: 20)
            Text("Lecture").font(GWFont.body(14, weight: .medium)).foregroundStyle(GWColor.fg)
            Text("\(minutesLecture) min")
                .font(GWFont.mono(10.5)).tracking(1).foregroundStyle(GWColor.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(GWColor.lineStrong))
    }

    private func tuile(icone: String, etiquette: String, valeur: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icone)
                .font(.system(size: 18))
                .foregroundStyle(couleurBloc)
                .frame(height: 20)
            Text(etiquette).font(GWFont.body(14, weight: .medium)).foregroundStyle(GWColor.fg)
            Text(valeur)
                .font(GWFont.mono(10.5)).tracking(1).foregroundStyle(GWColor.muted)
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(GWColor.lineStrong))
    }

    // MARK: - À regarder / Sources

    private func videoChipLabel(_ video: ArticleVideo) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "play.fill").imageScale(.small)
            (Text(video.title) + Text("  ·  \(video.channel)").foregroundColor(GWColor.muted))
                .lineLimit(1)
        }
    }

    private func aRegarder(_ videos: [ArticleVideo]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            kicker("À regarder")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(videos.enumerated()), id: \.offset) { index, video in
                        if let url = URL(string: video.url) {
                            if index == 0 {
                                Link(destination: url) { videoChipLabel(video) }
                                    .buttonStyle(PrimaryButtonStyle(tint: couleurBloc))
                            } else {
                                Link(destination: url) { videoChipLabel(video) }
                                    .buttonStyle(ChipButtonStyle(actif: false, teinte: couleurBloc))
                            }
                        }
                    }
                }
            }
        }
    }

    private var sources: some View {
        VStack(alignment: .leading, spacing: 12) {
            kicker("Sources")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(fiche.sources.enumerated()), id: \.offset) { _, source in
                        if let url = URL(string: source.url) {
                            Link(destination: url) {
                                HStack(spacing: 8) {
                                    Text(source.ref)
                                    Image(systemName: "arrow.up.right").imageScale(.small)
                                }
                            }
                            .buttonStyle(ChipButtonStyle(actif: false, teinte: couleurBloc))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pied de page

    private var pied: some View {
        VStack(alignment: .leading, spacing: 14) {
            Rectangle().fill(GWColor.line).frame(height: 1)
            HStack {
                if let filDAriane {
                    Text(filDAriane)
                        .font(GWFont.mono(11))
                        .foregroundStyle(GWColor.muted)
                }
                Spacer()
                Button(action: copierLeLien) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                        Text("Copier le lien")
                    }
                }
                .buttonStyle(.ghost)
            }
        }
    }

    /// Pour l'instant on copie seulement l'identifiant de la fiche : il n'y a
    /// pas encore de système de liens profonds universels côté app.
    /// TODO : copier un vrai lien (ex. `https://guawan.app/fiche/<id>` ou un
    /// schéma `guawan://`) une fois ce système en place.
    private func copierLeLien() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(fiche.id, forType: .string)
        #else
        UIPasteboard.general.string = fiche.id
        #endif
    }
}

// MARK: - Rattachement à la taxonomie

/// Retrouve le bloc (L'Esprit / La Création / Le Corps) auquel appartient le
/// salon de cette fiche, en cherchant dans `Carte.blocs` — la fiche elle-même
/// ne connaît que le nom de son salon (`Fiche.salon`), pas sa place dans
/// l'arbre.
private func blocDeLaFiche(_ fiche: Fiche) -> Bloc? {
    Carte.blocs.first { bloc in
        bloc.tousLesSalons.contains { $0.nom == fiche.salon }
    }
}

/// Associe la clé d'icône interne de la maquette (voir les `icon:` de
/// `Carte.swift`) au SF Symbol natif le plus proche. Ce n'est pas un ajout au
/// design system partagé (`GuaWanCore` n'est pas modifié) : la table vit ici
/// et sert aussi les autres vues de fiches/fils du même module d'app
/// (`FicheCardView`, `BlocFeedView`).
func sfSymbol(pour icone: String) -> String {
    switch icone {
    case "esprit": return "brain.head.profile"
    case "creation": return "paintpalette.fill"
    case "corps": return "figure.walk"
    case "philo": return "book.closed.fill"
    case "spiritualites": return "hands.sparkles.fill"
    case "textes": return "scroll.fill"
    case "meditation": return "figure.mind.and.body"
    case "mythes": return "moon.stars.fill"
    case "ethique": return "scalemass.fill"
    case "sciences": return "atom"
    case "cosmos": return "sparkles"
    case "arts": return "paintpalette"
    case "musique": return "music.note"
    case "ecriture": return "pencil.line"
    case "cinema": return "film.fill"
    case "ia": return "cpu"
    case "sensualite": return "hand.draw.fill"
    case "verrou": return "lock.fill"
    case "gout": return "fork.knife"
    case "odorat": return "wind"
    case "toucher": return "hand.tap.fill"
    case "ouie": return "ear.fill"
    case "vue": return "eye.fill"
    case "audela": return "wand.and.stars"
    case "mouvement": return "figure.run"
    case "soin": return "heart.fill"
    default: return "sparkles"
    }
}
