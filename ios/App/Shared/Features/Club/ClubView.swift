import SwiftUI
import GuaWanCore

/// Le club « Ici et Maintenant » — reflet de `viewClub()`/`pricingHTML()`
/// dans la maquette web. Aucun paiement n'est réellement déclenché : StoreKit
/// viendra dans une itération ultérieure, ce que l'app dit explicitement
/// plutôt que de simuler une transaction.
public struct ClubView: View {
    @State private var annuel = false
    @State private var afficherMessagePaiement = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                hero
                fonctionnalités
                tarifs
                faq
            }
            .padding(20)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(GWColor.bg)
        .navigationTitle("Ici et Maintenant")
        .alert("À venir", isPresented: $afficherMessagePaiement) {
            Button("Compris", role: .cancel) {}
        } message: {
            Text("Le paiement sécurisé sera branché ici (via StoreKit), dans une itération ultérieure. Aucune transaction n'a eu lieu.")
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("今").font(GWFont.display(40)).foregroundStyle(GWColor.gold)
            Text("Le club de Guà Wàn").font(GWFont.kicker).foregroundStyle(GWColor.muted)
            Text("Ici et Maintenant").font(GWFont.display(32))
            Text("Pour les Humains qui veulent aller plus loin : des parcours, des cercles en visio, des lives privés et un salon où l'on prend le temps.")
                .font(GWFont.body(15))
                .foregroundStyle(GWColor.muted)
            Button("Rejoindre pour \(prixLabel)") { afficherMessagePaiement = true }
                .buttonStyle(.gold)
            Text("Sans engagement · résiliable en un clic")
                .font(GWFont.mono(11))
                .foregroundStyle(GWColor.muted)
        }
    }

    // MARK: Fonctionnalités

    private var fonctionnalités: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitre("Ce que le club vous ouvre")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14)], spacing: 14) {
                ForEach(ClubPlan.iciEtMaintenant.features, id: \.self) { fonctionnalité in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(GWColor.gold)
                        Text(fonctionnalité).font(GWFont.body(14))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    // MARK: Tarifs

    private var tarifs: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitre("Gratuit ou club")
                Spacer()
                HStack(spacing: 8) {
                    Button("Mensuel") { annuel = false }
                        .buttonStyle(ChipButtonStyle(actif: !annuel))
                    Button("Annuel") { annuel = true }
                        .buttonStyle(ChipButtonStyle(actif: annuel))
                }
            }
            VStack(alignment: .leading, spacing: 16) {
                planCarte(
                    titre: "Humain", prix: "0 €", sousTitre: "pour toujours",
                    features: ClubPlan.humain.features, miseEnAvant: false
                )
                planCarte(
                    titre: "Ici et Maintenant", prix: prixLabel,
                    sousTitre: annuel ? "par an · deux mois offerts" : "par mois",
                    features: ClubPlan.iciEtMaintenant.features, miseEnAvant: true
                )
            }
        }
    }

    private var prixLabel: String {
        formaté(annuel ? ClubPlan.iciEtMaintenant.yearlyPrice : ClubPlan.iciEtMaintenant.monthlyPrice)
    }

    private func formaté(_ prix: Decimal) -> String {
        let formatteur = NumberFormatter()
        formatteur.numberStyle = .currency
        formatteur.currencyCode = "EUR"
        formatteur.locale = Locale(identifier: "fr_FR")
        formatteur.maximumFractionDigits = 0
        return formatteur.string(from: prix as NSDecimalNumber) ?? "\(prix) €"
    }

    private func planCarte(titre: String, prix: String, sousTitre: String, features: [String], miseEnAvant: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titre).font(GWFont.body(17, weight: .semibold))
            (Text(prix).font(GWFont.display(24)) + Text("  " + sousTitre).font(GWFont.mono(11)))
                .foregroundStyle(miseEnAvant ? GWColor.gold : GWColor.fg)
            ForEach(features, id: \.self) { feature in
                HStack(alignment: .top, spacing: 6) {
                    Text("·").foregroundStyle(GWColor.muted)
                    Text(feature).font(GWFont.body(13))
                }
            }
            if miseEnAvant {
                Button("Rejoindre Ici et Maintenant") { afficherMessagePaiement = true }
                    .buttonStyle(.gold)
            } else {
                NavigationLink("Créer mon compte") { SignupView() }
                    .buttonStyle(.ghost)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(miseEnAvant ? GWColor.gold.opacity(0.08) : GWColor.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(miseEnAvant ? GWColor.gold.opacity(0.4) : GWColor.line)
        )
    }

    // MARK: FAQ

    private var faq: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitre("Questions fréquentes")
            question("Puis-je arrêter quand je veux ?",
                      "Oui. L'abonnement mensuel est sans engagement et se résilie en un clic depuis votre profil.")
            question("Faut-il des connaissances particulières ?",
                      "Non. Les parcours partent des bases, dans chaque voie, et avancent pas à pas.")
            question("Que reste-t-il gratuit ?",
                      "Les salons des trois voies, les actus, les lives publics, l'annuaire et l'Oracle avec un quota quotidien.")
            question("Le club donne-t-il accès à la catégorie Sexualité ?",
                      "Non. Cette catégorie, en préparation, aura son propre accès, réservé aux adultes dont l'âge est vérifié.")
        }
    }

    private func question(_ titre: String, _ réponse: String) -> some View {
        QuestionRepliable(titre: titre, réponse: réponse)
    }

    // MARK: Aides

    private func sectionTitre(_ titre: String) -> some View {
        Text(titre).font(GWFont.titreSheet)
    }
}

/// Une question/réponse repliable — rôle équivalent à `DisclosureGroup`, mais
/// écrite à la main : `DisclosureGroup` n'existe pas sur tvOS, et cette vue
/// doit compiler sur les quatre plateformes.
private struct QuestionRepliable: View {
    let titre: String
    let réponse: String
    @State private var ouverte = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                ouverte.toggle()
            } label: {
                HStack {
                    Text(titre)
                        .font(GWFont.body(15, weight: .medium))
                        .foregroundStyle(GWColor.fg)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: ouverte ? "chevron.up" : "chevron.down")
                        .foregroundStyle(GWColor.muted)
                }
            }
            .buttonStyle(.plain)
            if ouverte {
                Text(réponse)
                    .font(GWFont.body(14))
                    .foregroundStyle(GWColor.muted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}
