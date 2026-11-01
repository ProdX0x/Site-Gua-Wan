import Observation

/// L'état de connexion de la personne qui utilise l'app — minimal, et
/// entièrement local tant qu'aucun vrai backend n'existe : aucune donnée
/// n'est envoyée nulle part (voir `SignupView`). Sert de point d'ancrage pour
/// que `ProfileView`/`SignupView` manipulent un état réel plutôt qu'un état
/// figé en dur dans la vue.
@Observable
@MainActor
public final class SessionStore {
    public private(set) var member: Member?

    public init(member: Member? = nil) {
        self.member = member
    }

    public var estConnecté: Bool { member != nil }

    /// Connexion de démonstration : utilise le créateur comme membre courant,
    /// en l'absence de toute vraie authentification.
    public func connecterInvité() {
        member = .createur
    }

    public func seConnecter(comme membre: Member) {
        member = membre
    }

    public func seDéconnecter() {
        member = nil
    }
}
