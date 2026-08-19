import SwiftUI

// MARK: - Core Apple System Liquid Glass Modifier
public struct AppleLiquidGlassModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    public var cornerRadius: CGFloat = 24
    public var paddingAmount: CGFloat = 0
    public var isInteractive: Bool = false

    public func body(content: Content) -> some View {
        content
            .padding(paddingAmount)
            .background {
                ZStack {
                    // 1. Base Ultra Thin Optical Glass Material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // 2. Translucent Optical Tint (Light / Dark mode tuned)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            colorScheme == .dark
                                ? Color(white: 0.14).opacity(0.62)
                                : Color.white.opacity(0.65)
                        )

                    // 3. Inner Specular Top Highlight (Refraction edge)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.45 : 0.85), location: 0.0),
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.15 : 0.40), location: 0.4),
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.65
                        )
                }
                // 4. Multi-layered Spatial Depth Shadows
                .shadow(
                    color: colorScheme == .dark
                        ? Color.black.opacity(0.40)
                        : Color(red: 0.1, green: 0.15, blue: 0.3).opacity(0.06),
                    radius: 18,
                    x: 0,
                    y: 8
                )
                .shadow(
                    color: colorScheme == .dark
                        ? Color.black.opacity(0.20)
                        : Color.black.opacity(0.03),
                    radius: 4,
                    x: 0,
                    y: 2
                )
            }
    }
}

// MARK: - Liquid Glass Capsule Pill Modifier
public struct AppleLiquidGlassPillModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    public func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)

                    Capsule(style: .continuous)
                        .fill(
                            colorScheme == .dark
                                ? Color(white: 0.18).opacity(0.70)
                                : Color.white.opacity(0.75)
                        )

                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.45 : 0.85),
                                    Color.white.opacity(colorScheme == .dark ? 0.10 : 0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.65
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

// MARK: - Ambient Aurora Canvas Background
public struct AmbientBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            if colorScheme == .dark {
                // Dark Mode: Deep spatial midnight ambient glow
                Color(red: 0.06, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()

                Circle()
                    .fill(Color.blue.opacity(0.18))
                    .blur(radius: 90)
                    .offset(x: -120, y: -200)

                Circle()
                    .fill(Color.purple.opacity(0.14))
                    .blur(radius: 100)
                    .offset(x: 140, y: 150)

                Circle()
                    .fill(Color.cyan.opacity(0.10))
                    .blur(radius: 80)
                    .offset(x: -80, y: 350)
            } else {
                // Light Mode: Soft airy luminescence
                Color(red: 0.96, green: 0.97, blue: 0.99)
                    .ignoresSafeArea()

                Circle()
                    .fill(Color(red: 0.85, green: 0.92, blue: 1.0).opacity(0.70))
                    .blur(radius: 80)
                    .offset(x: -100, y: -180)

                Circle()
                    .fill(Color(red: 0.93, green: 0.88, blue: 1.0).opacity(0.60))
                    .blur(radius: 90)
                    .offset(x: 130, y: 120)

                Circle()
                    .fill(Color(red: 0.88, green: 0.96, blue: 0.95).opacity(0.60))
                    .blur(radius: 80)
                    .offset(x: -90, y: 320)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Spring Touch Button Style
public struct LiquidGlassSpringButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

// MARK: - View Extensions
public extension View {
    func liquidGlass(cornerRadius: CGFloat = 24, padding: CGFloat = 0) -> some View {
        modifier(AppleLiquidGlassModifier(cornerRadius: cornerRadius, paddingAmount: padding))
    }

    func liquidGlassPill() -> some View {
        modifier(AppleLiquidGlassPillModifier())
    }

    func liquidGlassButton() -> some View {
        buttonStyle(LiquidGlassSpringButtonStyle())
    }
}
