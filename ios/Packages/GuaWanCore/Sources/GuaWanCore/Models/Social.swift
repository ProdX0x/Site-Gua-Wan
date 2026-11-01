import Foundation

/// Modèles de soutien pour les écrans qui, sur la maquette web, n'étaient pas
/// reliés à un vrai backend (bandeau « Maquette » dans la topbar) : Annuaire,
/// Lives, Calendrier, Club, Oracle. Les valeurs ci-dessous sont des données de
/// démonstration, pas du contenu éditorial — contrairement aux `Fiche`, elles
/// n'ont pas vocation à être étendues par le client depuis l'app ; elles
/// seront remplacées par un vrai service (voir `Services/`) quand le backend
/// existera.

/// Un profil membre (annuaire, profil, auteur affiché sur une publication).
public struct Member: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let initials: String
    public let city: String?
    /// Identifiants des blocs suivis (`Bloc.id`).
    public let voies: [String]
    public let club: Bool
    public let creator: Bool
    public let online: Bool
    public let bio: String?

    public init(id: String, name: String, initials: String, city: String? = nil, voies: [String] = [],
                club: Bool = false, creator: Bool = false, online: Bool = false, bio: String? = nil) {
        self.id = id
        self.name = name
        self.initials = initials
        self.city = city
        self.voies = voies
        self.club = club
        self.creator = creator
        self.online = online
        self.bio = bio
    }

    public static let createur = Member(
        id: "steve", name: "Stéphane « Steve » Saulnier", initials: "SS",
        city: "Paris, France", voies: ["esprit", "creation", "corps"], club: true, creator: true, online: true,
        bio: "Fondateur de Guà Wàn."
    )
}

/// Un rendez-vous en direct récurrent (voir `PROG`/`calRaw()` dans index.html).
public struct LiveEvent: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let blocId: String?
    public let weekday: Int   // 1 = lundi … 7 = dimanche (Calendar ISO8601-like)
    public let hour: Int
    public let minute: Int
    public let clubOnly: Bool

    public init(id: String, title: String, blocId: String?, weekday: Int, hour: Int, minute: Int, clubOnly: Bool = false) {
        self.id = id
        self.title = title
        self.blocId = blocId
        self.weekday = weekday
        self.hour = hour
        self.minute = minute
        self.clubOnly = clubOnly
    }

    /// Le programme hebdomadaire de démonstration (mardi/mercredi/jeudi/samedi/dimanche).
    public static let programme: [LiveEvent] = [
        LiveEvent(id: "live-corps", title: "L'éveil des sens · Le toucher", blocId: "corps", weekday: 2, hour: 20, minute: 0),
        LiveEvent(id: "cercle-club", title: "Cercle en visio · Ici et Maintenant", blocId: nil, weekday: 3, hour: 19, minute: 0, clubOnly: true),
        LiveEvent(id: "live-esprit", title: "Lecture commentée", blocId: "esprit", weekday: 4, hour: 20, minute: 30),
        LiveEvent(id: "live-creation", title: "Atelier de création", blocId: "creation", weekday: 6, hour: 11, minute: 0),
        LiveEvent(id: "meditation-club", title: "Méditation du dimanche · Ici et Maintenant", blocId: nil, weekday: 7, hour: 9, minute: 30, clubOnly: true),
    ]
}

/// Les deux offres du Club « Ici et Maintenant » (voir `viewClub`/`pricingHTML` dans index.html).
public struct ClubPlan: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let monthlyPrice: Decimal
    public let yearlyPrice: Decimal
    public let features: [String]

    public static let humain = ClubPlan(
        id: "humain", name: "Humain", monthlyPrice: 0, yearlyPrice: 0,
        features: ["Accès à toutes les fiches", "Carte L'Univers", "Oracle (quota limité)"]
    )
    public static let iciEtMaintenant = ClubPlan(
        id: "club", name: "Ici et Maintenant", monthlyPrice: 43, yearlyPrice: 430,
        features: ["Oracle sans quota", "Cercles en visio", "Lives privés", "Parcours & ateliers guidés"]
    )
}

/// Un modèle derrière l'Oracle (voir `MODELS` dans index.html). Le service réel
/// choisit, parmi ceux disponibles, lequel interroger — voir `OracleService`.
public struct OracleModelInfo: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let vendor: String

    public static let tousLesModeles: [OracleModelInfo] = [
        OracleModelInfo(id: "claude", name: "Claude", vendor: "Anthropic"),
        OracleModelInfo(id: "gpt", name: "GPT", vendor: "OpenAI"),
        OracleModelInfo(id: "gemini", name: "Gemini", vendor: "Google"),
        OracleModelInfo(id: "mistral", name: "Mistral", vendor: "Mistral AI"),
        OracleModelInfo(id: "llama", name: "Llama", vendor: "Meta"),
        OracleModelInfo(id: "deepseek", name: "DeepSeek", vendor: "DeepSeek"),
        OracleModelInfo(id: "apple", name: "Intelligence Apple (sur l'appareil)", vendor: "Apple"),
    ]
}

/// Une ville de l'annuaire/carte des Humains.
public struct City: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let country: String
    public let lat: Double
    public let lon: Double
}
