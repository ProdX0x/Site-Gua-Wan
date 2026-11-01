import SwiftUI

/// Les trois familles de polices de Guà Wàn (voir `--f-display`/`--f-body`/`--f-mono`
/// dans univers.css) : Shippori Mincho pour les titres, Zen Kaku Gothic New pour le
/// texte courant, IBM Plex Mono pour les kickers/étiquettes.
///
/// ⚠️ À faire avant de livrer au client : ces trois polices viennent de Google
/// Fonts et ne sont pas des polices système — leurs fichiers ne sont pas
/// embarqués ici (ce n'est pas du code, ce sont des binaires sous licence,
/// à télécharger puis glisser dans le projet Xcode : voir le fichier
/// `ios/Fonts/README.md`). En leur absence, `Font.custom` retombe
/// silencieusement sur l'équivalent système le plus proche — l'app reste
/// utilisable, juste moins fidèle à l'identité graphique du site.
public enum GWFont {

    public static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .custom("ShipporiMincho-SemiBold", size: size, relativeTo: .title)
            .weight(weight)
    }

    public static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("ZenKakuGothicNew-Regular", size: size, relativeTo: .body)
            .weight(weight)
    }

    public static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .custom("IBMPlexMono-Medium", size: size, relativeTo: .caption)
            .weight(weight)
    }

    // Styles sémantiques réutilisés tels quels par les vues.
    public static let titreFiche = display(26)
    public static let titreSheet = display(28)
    public static let kicker = mono(11.5, weight: .medium)
    public static let citation = display(19)
    public static let kanjiBloc = display(34)
}
