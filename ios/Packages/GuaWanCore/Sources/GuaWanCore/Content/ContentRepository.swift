import Foundation

/// Le résultat d'un chargement de contenu : les fiches valides, et les
/// éventuels problèmes rencontrés fiche par fiche (une fiche malformée
/// n'empêche jamais les autres de se charger — voir le commentaire sur
/// `BundledJSONContentRepository`).
public struct ContentLoadResult: Sendable {
    public let fiches: [Fiche]
    public let problems: [String]

    public init(fiches: [Fiche], problems: [String] = []) {
        self.fiches = fiches
        self.problems = problems
    }
}

/// La source des fiches de contenu. Abstraite exprès : aujourd'hui les fiches
/// sont embarquées dans le bundle de l'app (`BundledJSONContentRepository`),
/// mais le jour où le client veut les gérer depuis un back-office distant, il
/// suffit d'écrire un nouveau type conforme à ce protocole (ex. qui appelle
/// une API) — rien dans le reste de l'app (stores, vues) n'a besoin de changer.
public protocol ContentRepository: Sendable {
    func loadFiches() async throws -> ContentLoadResult
}

public enum ContentRepositoryError: Error, LocalizedError {
    case resourceDirectoryMissing

    public var errorDescription: String? {
        switch self {
        case .resourceDirectoryMissing:
            "Le dossier de ressources « Content » est introuvable dans le bundle de GuaWanCore."
        }
    }
}

/// Charge les fiches depuis les fichiers JSON embarqués dans le bundle du
/// package (`Resources/Content/*.json`, synchronisés depuis `docs/articles/`
/// par `ios/sync-content.sh`).
///
/// Chaque fichier correspond à un tableau de fiches, au même format que côté
/// site web. Contrairement au pipeline Python (`integrer-articles.py`), qui
/// arrête tout le build à la première fiche invalide, le chargement ici est
/// **tolérant fiche par fiche** : une fiche malformée est écartée et signalée
/// dans `ContentLoadResult.problems`, mais n'empêche pas les autres fiches —
/// y compris les autres fiches du même fichier — de s'afficher. C'est
/// important pour un client qui ajoute du contenu sans repasser par une CI :
/// une erreur de frappe sur une nouvelle fiche ne doit jamais casser l'app
/// pour les ~125 fiches déjà en place.
public struct BundledJSONContentRepository: ContentRepository {
    private let bundle: Bundle
    private let subdirectory: String

    public init(bundle: Bundle = .module, subdirectory: String = "Content") {
        self.bundle = bundle
        self.subdirectory = subdirectory
    }

    public func loadFiches() async throws -> ContentLoadResult {
        guard let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: subdirectory) else {
            throw ContentRepositoryError.resourceDirectoryMissing
        }

        var allocator = SlugAllocator()
        var fiches: [Fiche] = []
        var problems: [String] = []

        for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            do {
                let data = try Data(contentsOf: url)
                let (decoded, fileProblems) = try Self.decodeLeniently(data: data, fileName: url.lastPathComponent)
                problems.append(contentsOf: fileProblems)
                for fiche in decoded {
                    var fiche = fiche
                    fiche.id = allocator.allocate(for: fiche.title)
                    fiches.append(fiche)
                }
            } catch {
                problems.append("\(url.lastPathComponent) : fichier illisible (\(error.localizedDescription))")
            }
        }

        return ContentLoadResult(fiches: fiches, problems: problems)
    }

    /// Décode un tableau JSON de fiches en isolant les erreurs par élément,
    /// plutôt qu'en laissant une seule fiche invalide faire échouer tout
    /// le fichier (ce que ferait un simple `decoder.decode([Fiche].self, …)`).
    private static func decodeLeniently(data: Data, fileName: String) throws -> (fiches: [Fiche], problems: [String]) {
        guard let rawArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return ([], ["\(fileName) : le fichier doit contenir un tableau d'objets JSON"])
        }
        let decoder = JSONDecoder()
        var fiches: [Fiche] = []
        var problems: [String] = []
        for (index, object) in rawArray.enumerated() {
            do {
                let objectData = try JSONSerialization.data(withJSONObject: object)
                fiches.append(try decoder.decode(Fiche.self, from: objectData))
            } catch {
                let titre = (object["title"] as? String).map { " « \($0) »" } ?? ""
                problems.append("\(fileName) n°\(index + 1)\(titre) : \(error.localizedDescription)")
            }
        }
        return (fiches, problems)
    }
}
