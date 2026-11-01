import SwiftUI
import GuaWanCore

/// Le champ de recherche de L'Univers et ses résultats tolérants — reflet de
/// `.search`/`.search-results` dans univers.css et de `showResults()` dans
/// univers.js.
struct UniversSearchBar: View {
    let store: UniversStore
    @Binding var text: String
    var onSelect: (UniversNode) -> Void

    @FocusState private var estActif: Bool

    private var resultats: [UniversNode] { store.search(text) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            champ
            if estActif, !text.trimmingCharacters(in: .whitespaces).isEmpty {
                resultsPanel
            }
        }
    }

    private var champ: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(GWColor.muted)
            TextField("Chercher une fiche, un salon, un mot…", text: $text)
                .focused($estActif)
                .textFieldStyle(.plain)
                .submitLabel(.search)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(GWColor.muted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(GWColor.line, lineWidth: 1))
    }

    @ViewBuilder
    private var resultsPanel: some View {
        if resultats.isEmpty {
            Text("Rien de ce côté-là. Essayez un autre mot, ou explorez la carte.")
                .font(GWFont.body(14))
                .foregroundStyle(GWColor.muted)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(GWColor.line, lineWidth: 1))
        } else {
            VStack(spacing: 2) {
                ForEach(resultats) { noeud in
                    Button {
                        choisir(noeud)
                    } label: {
                        resultRow(noeud)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(GWColor.line, lineWidth: 1))
        }
    }

    private func resultRow(_ noeud: UniversNode) -> some View {
        let couleur = GWColor.couleur(nommee: noeud.couleur)
        return HStack(spacing: 12) {
            Image(systemName: UniversIcon.symbolName(for: noeud))
                .frame(width: 30, height: 30)
                .background(couleur.opacity(0.14), in: Circle())
                .foregroundStyle(couleur)
            VStack(alignment: .leading, spacing: 2) {
                Text(noeud.label)
                    .font(GWFont.body(15, weight: .medium))
                    .foregroundStyle(GWColor.fg)
                let chemin = noeud.ancetres.map(\.label).joined(separator: " › ")
                Text(chemin.isEmpty ? "Guà Wàn" : chemin)
                    .font(GWFont.mono(11))
                    .foregroundStyle(GWColor.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .contentShape(Rectangle())
    }

    private func choisir(_ noeud: UniversNode) {
        onSelect(noeud)
        text = ""
        estActif = false
    }
}
