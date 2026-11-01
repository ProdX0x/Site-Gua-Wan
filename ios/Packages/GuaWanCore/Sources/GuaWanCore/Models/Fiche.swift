import Foundation

/// Une source citée en bas de fiche.
public struct Source: Codable, Hashable, Sendable {
    public let ref: String
    public let url: String

    public init(ref: String, url: String) {
        self.ref = ref
        self.url = url
    }
}

/// Une vidéo proposée dans « À regarder ».
public struct ArticleVideo: Codable, Hashable, Sendable {
    public let title: String
    public let channel: String
    public let url: String
    public let lang: String?

    public init(title: String, channel: String, url: String, lang: String? = nil) {
        self.title = title
        self.channel = channel
        self.url = url
        self.lang = lang
    }
}

/// Une citation mise en avant dans la fiche.
public struct Citation: Codable, Hashable, Sendable {
    public let texte: String
    public let auteur: String
    public let source: String?

    public init(texte: String, auteur: String, source: String? = nil) {
        self.texte = texte
        self.auteur = auteur
        self.source = source
    }
}

/// Le repère géographique d'une fiche (bloc ESPRIT uniquement).
public struct Lieu: Codable, Hashable, Sendable {
    public let nom: String
    public let lat: Double
    public let lon: Double

    public init(nom: String, lat: Double, lon: Double) {
        self.nom = nom
        self.lat = lat
        self.lon = lon
    }
}

/// Les deux missions éditoriales de Guà Wàn.
public enum Mission: String, Codable, Sendable, CaseIterable, Identifiable {
    case informer = "Informer"
    case eduquer = "Éduquer"

    public var id: String { rawValue }
}

/// Type de média illustrant une fiche (indicatif ; aucun fichier n'est embarqué pour l'instant).
public enum MediaKind: String, Sendable, CaseIterable {
    case image, video, doc
}

/// Une fiche de contenu : l'unité éditoriale de base de Guà Wàn.
///
/// Reflète exactement le schéma JSON déjà en place côté site web
/// (voir `scripts/integrer-articles.py`, dictionnaires `BLOCS["CORPS"]`
/// et `BLOCS["ESPRIT"]`) — les deux blocs partagent ce même type Swift,
/// les champs propres à un seul des deux schémas restant optionnels :
/// `cles` (ESPRIT) vs. `plaisir` (CORPS), `repere`/`lieu`/`citation`/`videos`
/// (ESPRIT seulement), `media` (CORPS seulement).
///
/// `id` n'existe pas dans le JSON source : il est calculé par
/// `ContentRepository` au chargement (même règle de slug + dédoublonnage
/// que `construire-univers.py`), afin que deux fiches ne partagent jamais
/// le même identifiant même si leurs titres se ressemblent.
public struct Fiche: Codable, Identifiable, Hashable, Sendable {
    public var id: String

    public let salon: String
    public let title: String
    public let excerpt: String
    public let tag: Mission
    public let repere: String?
    public let lieu: Lieu?
    public let body: [String]
    public let cles: [String]?
    public let plaisir: String?
    public let citation: Citation?
    public let pratique: [String]
    public let sources: [Source]
    public let videos: [ArticleVideo]?
    public let media: String?
    public let auteur: String?

    enum CodingKeys: String, CodingKey {
        case salon, title, excerpt, tag, repere, lieu, body, cles, plaisir, citation, pratique, sources, videos, media, auteur
    }

    public init(
        id: String = "",
        salon: String, title: String, excerpt: String, tag: Mission,
        repere: String? = nil, lieu: Lieu? = nil, body: [String],
        cles: [String]? = nil, plaisir: String? = nil, citation: Citation? = nil,
        pratique: [String], sources: [Source], videos: [ArticleVideo]? = nil,
        media: String? = nil, auteur: String? = nil
    ) {
        self.id = id
        self.salon = salon
        self.title = title
        self.excerpt = excerpt
        self.tag = tag
        self.repere = repere
        self.lieu = lieu
        self.body = body
        self.cles = cles
        self.plaisir = plaisir
        self.citation = citation
        self.pratique = pratique
        self.sources = sources
        self.videos = videos
        self.media = media
        self.auteur = auteur
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = ""
        salon = try c.decode(String.self, forKey: .salon)
        title = try c.decode(String.self, forKey: .title)
        excerpt = try c.decode(String.self, forKey: .excerpt)
        tag = try c.decode(Mission.self, forKey: .tag)
        repere = try c.decodeIfPresent(String.self, forKey: .repere)
        lieu = try c.decodeIfPresent(Lieu.self, forKey: .lieu)
        body = try c.decode([String].self, forKey: .body)
        cles = try c.decodeIfPresent([String].self, forKey: .cles)
        plaisir = try c.decodeIfPresent(String.self, forKey: .plaisir)
        citation = try c.decodeIfPresent(Citation.self, forKey: .citation)
        pratique = try c.decode([String].self, forKey: .pratique)
        sources = try c.decode([Source].self, forKey: .sources)
        videos = try c.decodeIfPresent([ArticleVideo].self, forKey: .videos)
        media = try c.decodeIfPresent(String.self, forKey: .media)
        auteur = try c.decodeIfPresent(String.self, forKey: .auteur)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(salon, forKey: .salon)
        try c.encode(title, forKey: .title)
        try c.encode(excerpt, forKey: .excerpt)
        try c.encode(tag, forKey: .tag)
        try c.encodeIfPresent(repere, forKey: .repere)
        try c.encodeIfPresent(lieu, forKey: .lieu)
        try c.encode(body, forKey: .body)
        try c.encodeIfPresent(cles, forKey: .cles)
        try c.encodeIfPresent(plaisir, forKey: .plaisir)
        try c.encodeIfPresent(citation, forKey: .citation)
        try c.encode(pratique, forKey: .pratique)
        try c.encode(sources, forKey: .sources)
        try c.encodeIfPresent(videos, forKey: .videos)
        try c.encodeIfPresent(media, forKey: .media)
        try c.encodeIfPresent(auteur, forKey: .auteur)
    }

    /// Icône de média, si reconnue (une valeur inattendue ne fait pas
    /// échouer le chargement de la fiche, juste de cet indicateur).
    public var mediaKind: MediaKind? { media.flatMap(MediaKind.init(rawValue:)) }

    /// Titre court : ce qui précède « : », ou la question qui termine le titre.
    /// Porte exactement la même règle que `short()` dans construire-univers.py.
    public var shortTitle: String {
        guard title.count > 4 else { return title }
        if let colonRange = title.range(of: " : "), title.distance(from: title.startIndex, to: colonRange.lowerBound) >= 4 {
            return String(title[title.startIndex..<colonRange.lowerBound])
        }
        if title.hasSuffix("?"), let qIndex = title.lastIndex(of: "?") {
            let before = title[title.startIndex..<qIndex]
            if let spaceIndex = before.lastIndex(of: " ") {
                let head = title[title.startIndex..<spaceIndex]
                if head.count >= 4 { return String(head) }
            }
        }
        return title
    }

    /// Nombre approximatif de minutes de lecture, sur la même base que
    /// `openCard()` dans univers.js (≈ 200 mots/minute).
    public var readingMinutes: Int {
        let words = body.joined(separator: " ").split(separator: " ").count
        return max(1, Int((Double(words) / 200.0).rounded()))
    }
}
