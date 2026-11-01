import SwiftUI
import GuaWanCore

/// L'Oracle : une conversation avec une IA au choix, avec comparaison
/// possible de deux réponses côte à côte — reflet de `viewOracle()` et des
/// fonctions `render*`/`sendOracle` dans la maquette web. L'envoi passe par
/// `OracleService` (voir `OracleServiceFactory`), jamais par une simulation
/// câblée dans la vue.
public struct OracleView: View {
    private enum Rôle { case utilisateur, ia }

    private struct Message: Identifiable {
        let id = UUID()
        let rôle: Rôle
        var texte: String
        var modèle: OracleModelInfo?
        var texteAlt: String?
        var modèleAlt: OracleModelInfo?
    }

    private let suggestions = [
        "Qu'est-ce que le wabi-sabi ?",
        "Comment commencer à méditer sans rien de spécial ?",
        "D'où vient l'idée d'impermanence ?",
        "Pourquoi l'ensō n'est jamais totalement fermé ?",
    ]
    private let quotaMax = 30

    @State private var messages: [Message] = []
    @State private var saisie = ""
    @State private var modèleSélectionné = OracleModelInfo.tousLesModeles[0]
    @State private var comparerDeuxIA = false
    @State private var enTrainDécrire = false
    @State private var quotaRestant = 30
    @State private var erreurQuota: String?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            entête
            Divider().overlay(GWColor.line)
            journal
            Divider().overlay(GWColor.line)
            compositeur
            Text("Les réponses peuvent se tromper ; vérifiez les informations importantes.")
                .font(GWFont.mono(10.5))
                .foregroundStyle(GWColor.faint)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
        }
        .background(GWColor.bg)
        .navigationTitle("L'Oracle")
    }

    // MARK: En-tête

    private var entête: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Une question. Toutes les intelligences.")
                .font(GWFont.titreSheet)
            Text("Choisissez l'IA qui vous répond, ou comparez deux réponses côte à côte.")
                .font(GWFont.body(14))
                .foregroundStyle(GWColor.muted)
            HStack {
                Picker("Modèle", selection: $modèleSélectionné) {
                    ForEach(OracleModelInfo.tousLesModeles) { modèle in
                        Text("\(modèle.name) · \(modèle.vendor)").tag(modèle)
                    }
                }
                Spacer()
                Toggle("Comparer deux IA", isOn: $comparerDeuxIA)
                    .font(GWFont.body(13))
                    .fixedSize()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(quotaRestant) messages restants aujourd'hui sur \(quotaMax)")
                    .font(GWFont.mono(11))
                    .foregroundStyle(GWColor.muted)
                ProgressView(value: Double(quotaRestant), total: Double(quotaMax))
                    .tint(GWColor.gold)
                NavigationLink("Quota élevé avec Ici et Maintenant →") { ClubView() }
                    .font(GWFont.mono(11))
                    .foregroundStyle(GWColor.gold)
            }
        }
        .padding(16)
    }

    // MARK: Journal

    private var journal: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if messages.isEmpty && !enTrainDécrire {
                        videVue
                    } else {
                        ForEach(messages) { message in
                            bulle(message).id(message.id)
                        }
                        if enTrainDécrire {
                            réponseIA(modèle: modèleSélectionné, texte: "…").id("typing")
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: messages.count) {
                if let dernier = messages.last {
                    withAnimation { proxy.scrollTo(dernier.id, anchor: .bottom) }
                }
            }
        }
    }

    private var videVue: some View {
        VStack(spacing: 18) {
            Enso(seDessine: true).frame(width: 90, height: 90)
            Text("Que voulez-vous explorer ?").font(GWFont.titreSheet)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) { Task { await envoyer(texte: suggestion) } }
                        .buttonStyle(ChipButtonStyle(actif: false))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    @ViewBuilder
    private func bulle(_ message: Message) -> some View {
        switch message.rôle {
        case .utilisateur:
            HStack {
                Spacer(minLength: 40)
                Text(message.texte)
                    .font(GWFont.body(15))
                    .foregroundStyle(GWColor.onColor)
                    .padding(12)
                    .background(GWColor.accent, in: RoundedRectangle(cornerRadius: 14))
            }
        case .ia:
            if comparerDeuxIA, let texteAlt = message.texteAlt {
                HStack(alignment: .top, spacing: 12) {
                    réponseIA(modèle: message.modèle, texte: message.texte)
                    réponseIA(modèle: message.modèleAlt, texte: texteAlt)
                }
            } else {
                HStack {
                    réponseIA(modèle: message.modèle, texte: message.texte)
                    Spacer(minLength: 40)
                }
            }
        }
    }

    private func réponseIA(modèle: OracleModelInfo?, texte: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let modèle {
                HStack(spacing: 4) {
                    Circle().fill(GWColor.gold).frame(width: 6, height: 6)
                    Text(modèle.name).font(GWFont.mono(11)).foregroundStyle(GWColor.muted)
                }
            }
            Text(texte).font(GWFont.body(15))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Compositeur

    private var compositeur: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let erreurQuota {
                Text(erreurQuota).font(GWFont.body(12)).foregroundStyle(GWColor.accent)
            }
            HStack(spacing: 10) {
                TextField("Écrivez à l'Oracle…", text: $saisie)
                Button {
                    let texte = saisie
                    Task { await envoyer(texte: texte) }
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.primary)
                .disabled(saisie.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || enTrainDécrire)
            }
        }
        .padding(16)
    }

    // MARK: Envoi

    private func envoyer(texte: String) async {
        let question = texte.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        guard quotaRestant > 0 else {
            erreurQuota = "Quota du jour atteint. Il se recharge demain, ou passez à Ici et Maintenant."
            return
        }
        erreurQuota = nil
        saisie = ""
        messages.append(Message(rôle: .utilisateur, texte: question))
        quotaRestant -= 1
        enTrainDécrire = true

        let modèle = modèleSélectionné
        let autreModèle = comparerDeuxIA ? OracleModelInfo.tousLesModeles.first { $0.id != modèle.id } : nil

        let réponse: String
        do {
            réponse = try await OracleServiceFactory.service(for: modèle).répondre(à: question, modèle: modèle)
        } catch {
            réponse = "Désolé, une erreur est survenue. Réessayez."
        }

        var réponseAlt: String?
        if let autreModèle {
            réponseAlt = try? await OracleServiceFactory.service(for: autreModèle).répondre(à: question, modèle: autreModèle)
        }

        messages.append(Message(
            rôle: .ia, texte: réponse, modèle: modèle,
            texteAlt: réponseAlt, modèleAlt: réponseAlt != nil ? autreModèle : nil
        ))
        enTrainDécrire = false
    }
}
