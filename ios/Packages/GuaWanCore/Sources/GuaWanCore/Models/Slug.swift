import Foundation

/// Normalisation de texte partagée par le calcul des identifiants de fiches
/// et par la recherche. Porte les mêmes règles que `norm()`/`slug()` dans
/// `scripts/construire-univers.py` et que `norm()` dans `univers.js`.
public enum TextNormalization {

    /// Minuscule, sans accents (décomposition NFD puis suppression des marques diacritiques).
    public static func fold(_ text: String) -> String {
        let decomposed = text.lowercased().decomposedStringWithCanonicalMapping
        return String(decomposed.unicodeScalars.filter { !$0.properties.isDiacritic })
    }

    /// Identifiant URL-safe : lettres/chiffres séparés par des tirets, 60 caractères max.
    public static func slug(_ text: String) -> String {
        let folded = fold(text)
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
        var result = ""
        var lastWasDash = false
        for scalar in folded.unicodeScalars {
            if allowed.contains(scalar) {
                result.unicodeScalars.append(scalar)
                lastWasDash = false
            } else if !lastWasDash && !result.isEmpty {
                result.append("-")
                lastWasDash = true
            }
        }
        while result.hasSuffix("-") { result.removeLast() }
        if result.count > 60 {
            result = String(result.prefix(60))
            while result.hasSuffix("-") { result.removeLast() }
        }
        return result
    }

    /// Mots significatifs d'un texte (sans accents, minuscules, ≥ 2 caractères).
    public static func words(_ text: String) -> [String] {
        fold(text)
            .split { !($0.isLetter || $0.isNumber) }
            .map(String.init)
            .filter { $0.count > 1 }
    }
}

/// Attribue à chaque fiche un identifiant stable et unique, même si deux
/// titres se ressemblent — même logique que `card()` dans
/// `construire-univers.py` (slug du titre, puis suffixe `-2`, `-3`… en cas
/// de collision).
public struct SlugAllocator {
    private var used: Set<String> = []

    public init() {}

    public mutating func allocate(for title: String) -> String {
        let base = TextNormalization.slug(title)
        var candidate = base
        var n = 2
        while used.contains(candidate) {
            candidate = "\(base)-\(n)"
            n += 1
        }
        used.insert(candidate)
        return candidate
    }
}
