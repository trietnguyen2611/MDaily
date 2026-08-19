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

                    // 2. Subtle Optical Sheen (Preserves blur without muddy opacity)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            colorScheme == .dark
                                ? Color.white.opacity(0.04)
                                : Color.white.opacity(0.32)
                        )

                    // 3. Specular Refractive Highlight Edge
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.45 : 0.85), location: 0.0),
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35), location: 0.4),
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.04 : 0.12), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )
                }
                // 4. Multi-layered Spatial Depth Shadows
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08),
                    radius: 18,
                    x: 0,
                    y: 8
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.03),
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
                                ? Color.white.opacity(0.05)
                                : Color.white.opacity(0.35)
                        )

                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.45 : 0.85), location: 0.0),
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35), location: 0.4),
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.04 : 0.12), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )
                }
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.06),
                    radius: 10,
                    x: 0,
                    y: 4
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
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.82 : 1.0)
            .animation(.spring(response: 0.26, dampingFraction: 0.70), value: configuration.isPressed)
    }
}

// MARK: - Redesigned Clean Close Button (No Background)
public struct LiquidGlassCloseButton: View {
    public var size: CGFloat = 32
    public var color: Color = .secondary
    public var action: () -> Void

    public init(size: CGFloat = 32, color: Color = .secondary, action: @escaping () -> Void) {
        self.size = size
        self.color = color
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: max(14, size * 0.48), weight: .semibold))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .contentShape(Rectangle())
        }
        .buttonStyle(LiquidGlassSpringButtonStyle())
    }
}

// MARK: - Custom Liquid Glass Delete Modal
public struct LiquidGlassDeleteModal: View {
    public var title: String
    public var message: String
    public var confirmTitle: String
    public var cancelTitle: String
    public var onConfirm: () -> Void
    public var onCancel: () -> Void

    public init(
        title: String = "Xoá chi tiêu?",
        message: String = "Khoản chi này sẽ bị xoá vĩnh viễn và không thể khôi phục.",
        confirmTitle: String = "Xoá",
        cancelTitle: String = "Huỷ",
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.40)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 54, height: 54)
                    Image(systemName: "trash.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                }
                .padding(.top, 4)

                VStack(spacing: 6) {
                    Text(title)
                        .font(.appFont(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    Text(message)
                        .font(.appFont(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }

                HStack(spacing: 10) {
                    Button(cancelTitle) {
                        onCancel()
                    }
                    .font(.appFont(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .liquidGlassButton()

                    Button(confirmTitle) {
                        onConfirm()
                    }
                    .font(.appFont(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color(red: 0.9, green: 0.1, blue: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.red.opacity(0.35), radius: 6, x: 0, y: 2)
                    .liquidGlassButton()
                }
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: 310)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.40), lineWidth: 0.75)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 24, x: 0, y: 10)
            }
            .transition(.scale(scale: 0.92).combined(with: .opacity))
        }
    }
}

// MARK: - View Extensions & Keyboard Helpers
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

    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Unified Typography System (SF Pro Rounded)
public extension Font {
    static func appFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static var appLargeTitle: Font { .system(size: 28, weight: .bold, design: .rounded) }
    static var appTitle: Font { .system(size: 22, weight: .bold, design: .rounded) }
    static var appHeadline: Font { .system(size: 18, weight: .bold, design: .rounded) }
    static var appSubheadline: Font { .system(size: 15, weight: .semibold, design: .rounded) }
    static var appBody: Font { .system(size: 14, weight: .medium, design: .rounded) }
    static var appFootnote: Font { .system(size: 12, weight: .regular, design: .rounded) }
    static var appCaption: Font { .system(size: 11, weight: .regular, design: .rounded) }
}
