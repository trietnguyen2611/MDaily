import SwiftUI

public struct LiquidGlassModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    public var cornerRadius: CGFloat = 24
    public var paddingAmount: CGFloat = 0

    public func body(content: Content) -> some View {
        content
            .padding(paddingAmount)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color(white: 0.16).opacity(0.65)
                            : Color.white.opacity(0.70)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.35 : 0.90),
                                        Color.white.opacity(colorScheme == .dark ? 0.10 : 0.35)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(
                        color: colorScheme == .dark
                            ? Color.black.opacity(0.35)
                            : Color.black.opacity(0.06),
                        radius: 16,
                        x: 0,
                        y: 6
                    )
            }
    }
}

public struct LiquidGlassPillModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    public func body(content: Content) -> some View {
        content
            .background {
                Capsule(style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color(white: 0.18).opacity(0.75)
                            : Color.white.opacity(0.80)
                    )
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(
                                Color.white.opacity(colorScheme == .dark ? 0.30 : 0.85),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05),
                        radius: 8,
                        x: 0,
                        y: 3
                    )
            }
    }
}

public extension View {
    func liquidGlass(cornerRadius: CGFloat = 24, padding: CGFloat = 0) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, paddingAmount: padding))
    }

    func liquidGlassPill() -> some View {
        modifier(LiquidGlassPillModifier())
    }
}
