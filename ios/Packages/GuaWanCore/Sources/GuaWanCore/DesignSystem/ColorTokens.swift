import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Les couleurs de Guà Wàn : reflet exact des jetons CSS déjà en place côté
/// web (`univers.css` / `index.html`) — papier washi, encre sumi, rouge shu,
/// or kin, et une couleur par bloc. Clair et sombre sont tous deux portés ;
/// aucun jeton n'a été « réinventé » pour le natif.
///
/// Remarque corrigée au passage : le site principal nomme la couleur du
/// groupe Sexualité `--c-sex`, L'Univers la nomme `--c-sexe` — deux noms pour
/// la même teinte. Ici il n'y en a qu'un : `GWColor.sexe`.
public enum GWColor {

    // MARK: Fond et texte

    public static let bg = dynamic(light: (0xF3, 0xEE, 0xE4), dark: (0x12, 0x11, 0x10))       // washi
    public static let surface = dynamic(light: (0xFB, 0xF8, 0xF2), dark: (0x1A, 0x19, 0x17))  // kinari
    public static let sunken = dynamic(light: (0xEC, 0xE5, 0xD8), dark: (0x24, 0x22, 0x1F))
    public static let fg = dynamic(light: (0x1C, 0x1A, 0x17), dark: (0xEC, 0xE5, 0xD8))        // sumi
    public static let muted = dynamic(light: (0x6A, 0x64, 0x5A), dark: (0xA3, 0x9B, 0x8E))     // usuzumi
    public static let faint = dynamic(light: (0x9C, 0x94, 0x88), dark: (0x6F, 0x68, 0x5E))
    public static let line = dynamic(light: (0x1C, 0x1A, 0x17), dark: (0xEC, 0xE5, 0xD8), alpha: 0.12)
    public static let lineStrong = dynamic(light: (0x1C, 0x1A, 0x17), dark: (0xEC, 0xE5, 0xD8), alpha: 0.24)
    /// Fond constant des lecteurs vidéo/live (identique clair et sombre).
    public static let screen = Color(red: 0x0F / 255, green: 0x0E / 255, blue: 0x0C / 255)
    public static let ok = dynamic(light: (0x3E, 0x7B, 0x4F), dark: (0x3E, 0x7B, 0x4F))

    // MARK: Accents

    public static let accent = dynamic(light: (0xB8, 0x3E, 0x26), dark: (0xE3, 0x61, 0x3F))   // shu
    public static let gold = dynamic(light: (0x8A, 0x6A, 0x36), dark: (0xD4, 0xB0, 0x74))      // kin
    /// La couleur à utiliser pour du texte/une icône posée sur un aplat `accent`/`gold`/bloc.
    public static let onColor = dynamic(light: (0xFB, 0xF8, 0xF2), dark: (0x14, 0x13, 0x11))

    // MARK: Couleurs de bloc

    public static let racine = accent
    public static let esprit = dynamic(light: (0x34, 0x50, 0x7A), dark: (0x8A, 0xA6, 0xD6))     // ai
    public static let creation = dynamic(light: (0xA0, 0x65, 0x1F), dark: (0xE2, 0xA7, 0x5A))   // kohaku
    public static let corps = dynamic(light: (0xB0, 0x5F, 0x63), dark: (0xE5, 0xA6, 0xA6))       // sakura
    public static let sexe = dynamic(light: (0x8E, 0x2C, 0x3A), dark: (0xD0, 0x6A, 0x7C))        // beni

    /// La couleur associée au nom de jeton tel qu'il apparaît dans `Bloc.couleur`/`Groupe.couleur`
    /// (`"racine"`, `"esprit"`, `"creation"`, `"corps"`, `"sexe"`). Retombe sur `fg` si inconnu,
    /// pour qu'un futur jeton oublié ne fasse jamais planter l'affichage.
    public static func couleur(nommee nom: String) -> Color {
        switch nom {
        case "racine": racine
        case "esprit": esprit
        case "creation": creation
        case "corps": corps
        case "sexe", "sex": sexe
        default: fg
        }
    }

    // MARK: - Implémentation

    private typealias RGB = (UInt8, UInt8, UInt8)

    private static func dynamic(light: RGB, dark: RGB, alpha: Double = 1) -> Color {
        #if os(macOS)
        Color(NSColor(name: nil, dynamicProvider: { appearance in
            let best = appearance.bestMatch(from: [.aqua, .darkAqua])
            let rgb = best == .darkAqua ? dark : light
            return NSColor(red: CGFloat(rgb.0) / 255, green: CGFloat(rgb.1) / 255, blue: CGFloat(rgb.2) / 255, alpha: alpha)
        }))
        #else
        Color(UIColor(dynamicProvider: { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat(rgb.0) / 255, green: CGFloat(rgb.1) / 255, blue: CGFloat(rgb.2) / 255, alpha: alpha)
        }))
        #endif
    }
}
