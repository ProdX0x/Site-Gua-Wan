# Polices à ajouter avant de livrer au client

Guà Wàn utilise trois polices Google Fonts (licence SIL Open Font License,
gratuites) :

- **Shippori Mincho** (titres, kanji) — https://fonts.google.com/specimen/Shippori+Mincho
- **Zen Kaku Gothic New** (texte courant) — https://fonts.google.com/specimen/Zen+Kaku+Gothic+New
- **IBM Plex Mono** (kickers, étiquettes) — https://fonts.google.com/specimen/IBM+Plex+Mono

Ce ne sont pas des polices système : leurs fichiers `.ttf`/`.otf` doivent être
téléchargés puis ajoutés au projet Xcode (un par cible, ou dans une cible de
ressources partagée), puis déclarés dans chaque `Info.plist` (clé
`UIAppFonts` sur iOS/tvOS/visionOS ; sur macOS, les polices embarquées dans le
bundle de l'app sont prises en charge automatiquement par `Font.custom` sans
déclaration supplémentaire).

Noms attendus par `GWFont` (`Packages/GuaWanCore/Sources/GuaWanCore/DesignSystem/Typography.swift`) :

| Rôle | Nom de police PostScript attendu |
|---|---|
| Titres | `ShipporiMincho-SemiBold` |
| Texte courant | `ZenKakuGothicNew-Regular` |
| Mono | `IBMPlexMono-Medium` |

Tant que ces fichiers ne sont pas ajoutés, l'app fonctionne normalement :
`Font.custom` retombe sur l'équivalent système le plus proche. C'est
volontaire (ne jamais planter pour une police manquante), mais l'identité
graphique du site n'est vraiment fidèle qu'une fois les polices ajoutées.
