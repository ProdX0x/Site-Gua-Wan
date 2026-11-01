import SwiftUI
import GuaWanCore

/// Inscription en quatre étapes — reflet de `viewSignup()`/`suStep()` dans la
/// maquette web. Aucun compte n'est réellement créé : tout reste local, via
/// `SessionStore`, en attendant un vrai backend d'authentification.
public struct SignupView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var étape = 1
    @State private var email = ""
    @State private var motDePasse = ""
    @State private var voiesChoisies: Set<String> = []
    @State private var prénom = ""
    @State private var charteAcceptée = false
    @State private var erreur: String?
    @State private var inscriptionTerminée = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if inscriptionTerminée {
                    bienvenue
                } else {
                    indicateurÉtapes
                    étapeActuelle
                    if let erreur {
                        Text(erreur)
                            .font(GWFont.body(13))
                            .foregroundStyle(GWColor.accent)
                    }
                    navigationÉtapes
                    Text("Aucune information n'est envoyée ni enregistrée : cette inscription reste une démonstration, en attendant le vrai backend.")
                        .font(GWFont.mono(11))
                        .foregroundStyle(GWColor.muted)
                }
            }
            .padding(24)
            .frame(maxWidth: 520, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(GWColor.bg)
        .navigationTitle("Rejoindre les Humains")
    }

    // MARK: Indicateur de progression

    private var indicateurÉtapes: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { n in
                    Capsule()
                        .fill(n <= étape ? GWColor.accent : GWColor.line)
                        .frame(height: 4)
                }
            }
            Text("Étape \(étape) sur 4 · \(libelléÉtape(étape))")
                .font(GWFont.mono(11))
                .foregroundStyle(GWColor.muted)
        }
    }

    private func libelléÉtape(_ n: Int) -> String {
        ["Compte", "Vos voies", "Votre profil", "La charte"][n - 1]
    }

    // MARK: Étapes

    @ViewBuilder
    private var étapeActuelle: some View {
        switch étape {
        case 1: étapeCompte
        case 2: étapeVoies
        case 3: étapeProfil
        default: étapeCharte
        }
    }

    private var étapeCompte: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Créez votre compte").font(GWFont.titreSheet)
            TextField("vous@exemple.fr", text: $email)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                #endif
                .champTexte()
            SecureField("8 caractères minimum", text: $motDePasse)
                .champTexte()
        }
    }

    private var étapeVoies: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choisissez vos voies").font(GWFont.titreSheet)
            Text("Une, deux ou les trois. Vous pourrez changer à tout moment.")
                .font(GWFont.body(14))
                .foregroundStyle(GWColor.muted)
            ForEach(Carte.blocs) { bloc in
                Button {
                    toggleVoie(bloc.id)
                } label: {
                    HStack {
                        Text(bloc.kanji).font(GWFont.display(22)).foregroundStyle(GWColor.couleur(nommee: bloc.couleur))
                        Text(bloc.label).font(GWFont.body(16, weight: .medium))
                        Spacer()
                        if voiesChoisies.contains(bloc.id) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(GWColor.accent)
                        } else {
                            Image(systemName: "circle").foregroundStyle(GWColor.faint)
                        }
                    }
                    .padding(14)
                    .background(GWColor.surface, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            Text("La catégorie Sexualité (18+) ouvrira plus tard, avec sa propre vérification d'âge.")
                .font(GWFont.mono(11))
                .foregroundStyle(GWColor.muted)
        }
    }

    private var étapeProfil: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Votre profil").font(GWFont.titreSheet)
            Text("Ce que les autres Humains verront de vous. Tout reste modifiable.")
                .font(GWFont.body(14))
                .foregroundStyle(GWColor.muted)
            TextField("Votre prénom", text: $prénom)
                .champTexte()
            HStack(spacing: 14) {
                Text(initiales(de: prénom))
                    .font(GWFont.body(16, weight: .semibold))
                    .foregroundStyle(GWColor.onColor)
                    .frame(width: 48, height: 48)
                    .background(voiesChoisies.first.map { GWColor.couleur(nommee: $0) } ?? GWColor.accent, in: Circle())
                Text("Aperçu de votre avatar : vos initiales, faute de photo pour l'instant.")
                    .font(GWFont.mono(11))
                    .foregroundStyle(GWColor.muted)
            }
        }
    }

    private var étapeCharte: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("La charte des Humains").font(GWFont.titreSheet)
            VStack(alignment: .leading, spacing: 8) {
                règle("Chaque univers se respecte, sans exception.")
                règle("L'esprit critique est bienvenu, avec bienveillance.")
                règle("Ce qui informe cite ses sources.")
                règle("Pas de promotion sans accord préalable.")
            }
            Toggle(isOn: $charteAcceptée) {
                Text("J'accepte la charte des Humains et les conditions d'utilisation.")
                    .font(GWFont.body(14))
            }
        }
    }

    private func règle(_ texte: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("·").foregroundStyle(GWColor.muted)
            Text(texte).font(GWFont.body(14))
        }
    }

    // MARK: Bienvenue

    private var bienvenue: some View {
        VStack(spacing: 18) {
            Enso(seDessine: true)
                .frame(width: 110, height: 110)
            Text("Compte créé").font(GWFont.kicker).foregroundStyle(GWColor.muted)
            Text("Bienvenue, \(prénom.isEmpty ? "Humain" : prénom).")
                .font(GWFont.display(26))
            Text("Votre univers vient de rejoindre les autres. Présentez-vous, ou posez votre première question à l'Oracle.")
                .font(GWFont.body(15))
                .foregroundStyle(GWColor.muted)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button("Découvrir Guà Wàn") { dismiss() }
                    .buttonStyle(.primary)
                NavigationLink("Interroger l'Oracle") { OracleView() }
                    .buttonStyle(.ghost)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    // MARK: Navigation entre étapes

    private var navigationÉtapes: some View {
        HStack {
            if étape > 1 {
                Button("Retour") {
                    erreur = nil
                    étape -= 1
                }
                .buttonStyle(.ghost)
            }
            Spacer()
            Button(étape == 4 ? "Créer mon compte" : "Continuer") {
                continuer()
            }
            .buttonStyle(.primary)
        }
    }

    // MARK: Logique

    private func toggleVoie(_ id: String) {
        if voiesChoisies.contains(id) {
            voiesChoisies.remove(id)
        } else {
            voiesChoisies.insert(id)
        }
    }

    private func continuer() {
        guard valider() else { return }
        erreur = nil
        if étape < 4 {
            étape += 1
        } else {
            terminerInscription()
        }
    }

    private func valider() -> Bool {
        switch étape {
        case 1:
            guard email.contains("@"), email.contains(".") else {
                erreur = "Cette adresse e-mail ne semble pas valide."
                return false
            }
            guard motDePasse.count >= 8 else {
                erreur = "Le mot de passe doit faire au moins 8 caractères."
                return false
            }
        case 2:
            guard !voiesChoisies.isEmpty else {
                erreur = "Choisissez au moins une voie."
                return false
            }
        case 3:
            guard !prénom.trimmingCharacters(in: .whitespaces).isEmpty else {
                erreur = "Indiquez votre prénom."
                return false
            }
        default:
            guard charteAcceptée else {
                erreur = "Acceptez la charte pour créer votre compte."
                return false
            }
        }
        return true
    }

    private func terminerInscription() {
        let membre = Member(
            id: UUID().uuidString,
            name: prénom,
            initials: initiales(de: prénom),
            city: nil,
            voies: Array(voiesChoisies),
            club: false,
            creator: false,
            online: true,
            bio: nil
        )
        session.seConnecter(comme: membre)
        inscriptionTerminée = true
    }

    private func initiales(de nom: String) -> String {
        let mots = nom.trimmingCharacters(in: .whitespaces).split(separator: " ")
        let lettres = mots.prefix(2).compactMap(\.first).map(String.init)
        let résultat = lettres.joined().uppercased()
        return résultat.isEmpty ? "?" : résultat
    }
}

private extension View {
    /// `RoundedBorderTextFieldStyle` n'existe pas sur tvOS : on y retombe sur
    /// le style par défaut plutôt que de faire échouer la compilation de cette
    /// cible.
    @ViewBuilder
    func champTexte() -> some View {
        #if os(tvOS)
        self
        #else
        self.textFieldStyle(.roundedBorder)
        #endif
    }
}
