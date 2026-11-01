import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Un fournisseur de réponses pour l'Oracle. Abstrait exprès : aujourd'hui
/// seuls `MockOracleService` et `AppleIntelligenceOracleService` existent,
/// mais brancher un vrai fournisseur (Anthropic, OpenAI…) revient à écrire
/// un nouveau type conforme à ce protocole — voir `OracleServiceFactory`.
public protocol OracleService: Sendable {
    func répondre(à question: String, modèle: OracleModelInfo) async throws -> String
}

/// Simule une réponse d'IA : utilisé pour tous les modèles tant qu'aucun
/// vrai fournisseur n'est branché (voir `OracleServiceFactory`).
public struct MockOracleService: OracleService {
    public init() {}

    public func répondre(à question: String, modèle: OracleModelInfo) async throws -> String {
        try await Task.sleep(for: .seconds(1))
        let variantes = [
            "Réponse simulée de \(modèle.name). Sur le vrai site, l'Oracle transmettra votre question à \(modèle.name) (\(modèle.vendor)) et affichera sa réponse ici, au fil de l'écriture.",
            "\(modèle.name) n'est pas encore branché : voici une réponse de démonstration à « \(question.isEmpty ? "votre question" : question) ». Le ton et les sources viendront du guide choisi.",
            "Ceci est un aperçu de ce que \(modèle.name) pourrait répondre. Aucune requête n'a quitté votre appareil : le vrai service arrivera avec le backend.",
        ]
        return variantes.randomElement() ?? variantes[0]
    }
}

/// Tente de répondre avec l'Intelligence Apple, sur l'appareil, via le
/// framework Foundation Models — annoncé par Apple en 2025 pour exécuter un
/// modèle de langage embarqué sans envoyer la question à un serveur.
///
/// ⚠️ À vérifier dans Xcode avec le SDK réellement installé, impossible à
/// compiler depuis cet environnement :
/// - la disponibilité exacte (`@available`) de `FoundationModels` ;
/// - le nom précis du type de session (`LanguageModelSession` ou équivalent)
///   et de sa méthode de réponse (`respond(to:)` ou équivalent) ;
/// - la gestion des erreurs propres au framework (modèle indisponible,
///   contenu refusé, appareil non compatible…).
/// En l'absence du framework (import impossible) ou si l'appareil ne
/// supporte pas l'Intelligence Apple, on retombe silencieusement sur
/// `MockOracleService` plutôt que de planter l'app.
public struct AppleIntelligenceOracleService: OracleService {
    public init() {}

    public func répondre(à question: String, modèle: OracleModelInfo) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26, macOS 26, tvOS 26, visionOS 26, *) {
            do {
                return try await répondreAvecFoundationModels(question)
            } catch {
                // Modèle indisponible sur cet appareil, ou API encore différente
                // de ce qui est écrit ici : on retombe sur la simulation plutôt
                // que de faire échouer la conversation.
                return try await MockOracleService().répondre(à: question, modèle: modèle)
            }
        } else {
            return try await MockOracleService().répondre(à: question, modèle: modèle)
        }
        #else
        return try await MockOracleService().répondre(à: question, modèle: modèle)
        #endif
    }

    #if canImport(FoundationModels)
    @available(iOS 26, macOS 26, tvOS 26, visionOS 26, *)
    private func répondreAvecFoundationModels(_ question: String) async throws -> String {
        // ⚠️ Signature indicative : `LanguageModelSession` et `respond(to:)` sont
        // les noms documentés par Apple au lancement du framework, mais doivent
        // être confirmés dans Xcode (autocomplétion + documentation du SDK
        // installé) avant toute mise en production — aucune compilation n'a pu
        // valider ces lignes dans cet environnement.
        let session = LanguageModelSession()
        let réponse = try await session.respond(to: question)
        return réponse.content
    }
    #endif
}

/// Choisit le service à interroger pour un modèle donné.
///
/// Point d'extension : le jour où un vrai fournisseur (Anthropic, OpenAI,
/// Google…) est branché, chaque identifiant de `OracleModelInfo.tousLesModeles`
/// gagne son propre `case` ici plutôt que de continuer à retomber sur
/// `MockOracleService`.
public enum OracleServiceFactory {
    public static func service(for modèle: OracleModelInfo) -> OracleService {
        switch modèle.id {
        case "apple": AppleIntelligenceOracleService()
        default: MockOracleService()
        }
    }
}
