import SwiftUI
import GuaWanCore

/// Le calendrier des rendez-vous — reflet simplifié de `viewCal()`/`calRaw()`
/// dans la maquette web : une grille mensuelle, et les rendez-vous récurrents
/// de `LiveEvent.programme` replacés sur chaque jour qui correspond à leur
/// `weekday`.
public struct CalendarView: View {
    @State private var moisAffiché = Date()
    @State private var jourSélectionné = Date()

    private let calendrier: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "fr_FR")
        return cal
    }()
    private let entêtesJours = ["L", "M", "M", "J", "V", "S", "D"]

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                entête
                navigationMois
                grille
                légende
                panneauJour
            }
            .padding(20)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(GWColor.bg)
        .navigationTitle("Calendrier")
    }

    private var entête: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calendrier").font(GWFont.kicker).foregroundStyle(GWColor.muted)
            Text("Les rendez-vous des Humains").font(GWFont.display(26))
            Text("Lives publics et visios du club. Toutes les heures sont à l'heure de Paris.")
                .font(GWFont.body(14))
                .foregroundStyle(GWColor.muted)
        }
    }

    // MARK: Navigation entre mois

    private var navigationMois: some View {
        HStack {
            Button { changerMois(de: -1) } label: { Image(systemName: "chevron.left") }
                .buttonStyle(.ghost)
            Text(libelléMois)
                .font(GWFont.body(17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            Button { changerMois(de: 1) } label: { Image(systemName: "chevron.right") }
                .buttonStyle(.ghost)
        }
    }

    private var libelléMois: String {
        let formatteur = DateFormatter()
        formatteur.locale = Locale(identifier: "fr_FR")
        formatteur.dateFormat = "MMMM yyyy"
        return formatteur.string(from: moisAffiché).capitalized
    }

    private func changerMois(de décalage: Int) {
        if let nouveauMois = calendrier.date(byAdding: .month, value: décalage, to: moisAffiché) {
            moisAffiché = nouveauMois
        }
    }

    // MARK: Grille mensuelle

    private var grille: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
            ForEach(entêtesJours.indices, id: \.self) { i in
                Text(entêtesJours[i])
                    .font(GWFont.mono(11))
                    .foregroundStyle(GWColor.muted)
                    .frame(maxWidth: .infinity)
            }
            ForEach(Array(joursDuMois.enumerated()), id: \.offset) { _, jour in
                if let jour {
                    jourCellule(jour)
                } else {
                    Color.clear.frame(height: 56)
                }
            }
        }
    }

    /// Les cases de la grille : `nil` pour les cases vides avant le 1er du
    /// mois (complétées jusqu'à un multiple de 7 pour garder une grille
    /// régulière).
    private var joursDuMois: [Date?] {
        guard let intervalleMois = calendrier.dateInterval(of: .month, for: moisAffiché),
              let plage = calendrier.range(of: .day, in: .month, for: moisAffiché) else { return [] }
        let premierJour = intervalleMois.start
        let têteVide = isoWeekday(de: premierJour) - 1
        var jours: [Date?] = Array(repeating: nil, count: têteVide)
        for n in plage {
            if let jour = calendrier.date(byAdding: .day, value: n - 1, to: premierJour) {
                jours.append(jour)
            }
        }
        while jours.count % 7 != 0 { jours.append(nil) }
        return jours
    }

    /// Jour de semaine « à la française » : 1 = lundi … 7 = dimanche, comme
    /// `LiveEvent.weekday` (`Calendar.component(.weekday)` donne 1 = dimanche).
    private func isoWeekday(de date: Date) -> Int {
        let brut = calendrier.component(.weekday, from: date)
        return ((brut + 5) % 7) + 1
    }

    private func évènements(le jour: Date) -> [LiveEvent] {
        let jourISO = isoWeekday(de: jour)
        return LiveEvent.programme.filter { $0.weekday == jourISO }
    }

    private func jourCellule(_ jour: Date) -> some View {
        let évènementsDuJour = évènements(le: jour)
        let estAujourdhui = calendrier.isDateInToday(jour)
        let estSélectionné = calendrier.isDate(jour, inSameDayAs: jourSélectionné)
        return Button {
            jourSélectionné = jour
        } label: {
            VStack(spacing: 4) {
                Text("\(calendrier.component(.day, from: jour))")
                    .font(GWFont.body(13, weight: estAujourdhui ? .bold : .regular))
                HStack(spacing: 2) {
                    ForEach(évènementsDuJour) { évènement in
                        Circle().fill(couleur(pour: évènement)).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                estSélectionné ? GWColor.accent.opacity(0.15) : Color.clear,
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(estAujourdhui ? GWColor.accent : .clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func couleur(pour évènement: LiveEvent) -> Color {
        if évènement.clubOnly { return GWColor.gold }
        if let blocId = évènement.blocId, let bloc = Carte.blocs.first(where: { $0.id == blocId }) {
            return GWColor.couleur(nommee: bloc.couleur)
        }
        return GWColor.accent
    }

    // MARK: Légende

    private var légende: some View {
        HStack(spacing: 14) {
            ForEach(Carte.blocs) { bloc in
                HStack(spacing: 5) {
                    Circle().fill(GWColor.couleur(nommee: bloc.couleur)).frame(width: 7, height: 7)
                    Text(bloc.label).font(GWFont.mono(10.5)).foregroundStyle(GWColor.muted)
                }
            }
            HStack(spacing: 5) {
                Circle().fill(GWColor.gold).frame(width: 7, height: 7)
                Text("Club").font(GWFont.mono(10.5)).foregroundStyle(GWColor.muted)
            }
        }
    }

    // MARK: Jour sélectionné

    private var panneauJour: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(libelléJourSélectionné).font(GWFont.body(15, weight: .semibold))
            let évènementsJour = évènements(le: jourSélectionné)
            if évènementsJour.isEmpty {
                Text("Rien de prévu ce jour-là.")
                    .font(GWFont.body(14))
                    .foregroundStyle(GWColor.muted)
            } else {
                ForEach(évènementsJour) { évènement in
                    HStack(spacing: 10) {
                        Circle().fill(couleur(pour: évènement)).frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(évènement.title).font(GWFont.body(14, weight: .medium))
                            Text(heureTexte(évènement)).font(GWFont.mono(11)).foregroundStyle(GWColor.muted)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var libelléJourSélectionné: String {
        let formatteur = DateFormatter()
        formatteur.locale = Locale(identifier: "fr_FR")
        formatteur.dateFormat = "EEEE d MMMM"
        return formatteur.string(from: jourSélectionné).capitalized
    }

    private func heureTexte(_ évènement: LiveEvent) -> String {
        String(format: "%02dh%02d", évènement.hour, évènement.minute)
    }
}
