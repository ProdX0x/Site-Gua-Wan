import SwiftUI
import GuaWanCore

/// La feuille de filtre région/mission — reflet de `openFilter()` dans
/// univers.js : un onglet par filtre, la liste de ses valeurs avec le nombre
/// de fiches concernées, triée par popularité puis ordre alphabétique.
struct UniversFilterSheet: View {
    let store: UniversStore
    @Environment(\.dismiss) private var dismiss
    @State private var filtreActifId: String

    init(store: UniversStore, filtreInitialId: String? = nil) {
        self.store = store
        _filtreActifId = State(initialValue: filtreInitialId ?? Carte.filtres.first?.id ?? "region")
    }

    private var filtre: Filtre? { Carte.filtres.first { $0.id == filtreActifId } }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                if Carte.filtres.count > 1 {
                    Picker("Filtre", selection: $filtreActifId) {
                        ForEach(Carte.filtres) { f in
                            Text(f.court).tag(f.id)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

                if let filtre {
                    Text(filtre.intro)
                        .font(GWFont.body(14))
                        .foregroundStyle(GWColor.muted)
                        .padding(.horizontal)
                }

                List(store.compteurs(pourFiltre: filtreActifId)) { valeur in
                    Button {
                        store.applyFilter(filtreActifId, valeur: valeur.valeur)
                        dismiss()
                    } label: {
                        HStack {
                            Text(valeur.valeur)
                                .font(GWFont.body(15))
                                .foregroundStyle(GWColor.fg)
                            Spacer()
                            Text("\(valeur.compte)")
                                .font(GWFont.mono(11))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 2)
                                .background(GWColor.accent.opacity(0.12), in: Capsule())
                                .foregroundStyle(GWColor.accent)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
            .navigationTitle(filtre?.titre ?? "Filtrer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
