import UIKit

/// Couleurs « plates » pour RealityKit, propres à visionOS.
///
/// RealityKit veut des couleurs concrètes (`UIColor`), pas un `Color`
/// dynamique clair/sombre — et l'espace immersif n'a de toute façon pas de
/// mode sombre séparé. Ceci n'est qu'un miroir restreint, à cette seule fin,
/// des valeurs « claires » déjà définies dans `GWColor` (`ColorTokens.swift`,
/// non modifié) : mêmes jetons, même rendu RGB, juste un type différent.
enum UniversImmersiveColor {
    static func couleur(nommee nom: String) -> UIColor {
        switch nom {
        case "racine": rgb(0xB8, 0x3E, 0x26)
        case "esprit": rgb(0x34, 0x50, 0x7A)
        case "creation": rgb(0xA0, 0x65, 0x1F)
        case "corps": rgb(0xB0, 0x5F, 0x63)
        case "sexe", "sex": rgb(0x8E, 0x2C, 0x3A)
        default: rgb(0x1C, 0x1A, 0x17) // GWColor.fg (clair)
        }
    }

    private static func rgb(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> UIColor {
        UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}
