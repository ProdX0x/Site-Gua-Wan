import XCTest
@testable import GuaWanCore

final class SlugTests: XCTestCase {

    func testSlugRemovesAccentsAndSpaces() {
        XCTAssertEqual(TextNormalization.slug("Le Goût"), "le-gout")
        XCTAssertEqual(TextNormalization.slug("Éthique & sens de la vie"), "ethique-sens-de-la-vie")
    }

    func testSlugAllocatorDedupesCollisions() {
        var allocator = SlugAllocator()
        let premier = allocator.allocate(for: "Même titre")
        let second = allocator.allocate(for: "Même titre")
        let troisieme = allocator.allocate(for: "Même titre")

        XCTAssertEqual(premier, "meme-titre")
        XCTAssertEqual(second, "meme-titre-2")
        XCTAssertEqual(troisieme, "meme-titre-3")
    }

    func testWordsIgnoresShortTokens() {
        // La ponctuation sépare les mots, et "l" (un seul caractère, issu de
        // « l'Odorat ») est écarté : seuls les mots de 2 caractères ou plus
        // comptent, comme côté web (`words()` dans univers.js).
        XCTAssertEqual(TextNormalization.words("Le Goût, l'Odorat"), ["le", "gout", "odorat"])
    }
}
