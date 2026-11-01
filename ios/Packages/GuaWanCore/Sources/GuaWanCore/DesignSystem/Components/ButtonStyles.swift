import SwiftUI

/// Styles de bouton partagés — reflets de `.pill`, `.btn-primary`, `.btn-ghost`,
/// `.btn-gold` et `.chip` dans `univers.css`/`index.html`.

public struct PillButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GWFont.body(14.5, weight: .medium))
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(.thinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(GWColor.lineStrong, lineWidth: 1))
            .foregroundStyle(GWColor.fg)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

public struct PrimaryButtonStyle: ButtonStyle {
    public var tint: Color
    public init(tint: Color = GWColor.accent) { self.tint = tint }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GWFont.body(15, weight: .medium))
            .padding(.horizontal, 20)
            .frame(height: 44)
            .background(tint, in: Capsule())
            .foregroundStyle(GWColor.onColor)
            .shadow(color: tint.opacity(0.5), radius: configuration.isPressed ? 6 : 14, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

public struct GoldButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GWFont.body(15, weight: .medium))
            .padding(.horizontal, 22)
            .frame(height: 44)
            .background(GWColor.gold, in: Capsule())
            .foregroundStyle(GWColor.onColor)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

public struct GhostButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GWFont.body(15, weight: .medium))
            .padding(.horizontal, 18)
            .frame(height: 44)
            .overlay(Capsule().strokeBorder(GWColor.lineStrong, lineWidth: 1))
            .foregroundStyle(GWColor.fg)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Un « chip » filtrant/sélectionnable (ex. les salons dans le fil d'un bloc).
public struct ChipButtonStyle: ButtonStyle {
    public var actif: Bool
    public var teinte: Color
    public init(actif: Bool, teinte: Color = GWColor.accent) {
        self.actif = actif
        self.teinte = teinte
    }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GWFont.body(14))
            .padding(.horizontal, 14)
            .frame(minHeight: 38)
            .background(actif ? teinte.opacity(0.14) : Color.clear, in: Capsule())
            .overlay(Capsule().strokeBorder(actif ? teinte.opacity(0.7) : GWColor.lineStrong, lineWidth: 1))
            .foregroundStyle(actif ? teinte : GWColor.fg)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

public extension ButtonStyle where Self == PillButtonStyle {
    static var pill: PillButtonStyle { PillButtonStyle() }
}
public extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
public extension ButtonStyle where Self == GhostButtonStyle {
    static var ghost: GhostButtonStyle { GhostButtonStyle() }
}
public extension ButtonStyle where Self == GoldButtonStyle {
    static var gold: GoldButtonStyle { GoldButtonStyle() }
}
