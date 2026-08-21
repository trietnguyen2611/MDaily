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
                // Dark Mode: Pure pitch black OLED canvas
                Color.black
                    .ignoresSafeArea()
            } else {
                // Light Mode: Clean iOS System Grouped Background Canvas
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
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
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .brightness(configuration.isPressed ? -0.03 : 0.0)
            .animation(.spring(response: 0.30, dampingFraction: 0.78, blendDuration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred(intensity: 0.5)
                }
            }
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

// MARK: - Scroll Offset Tracking System
public struct ScrollOffsetPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat = 0
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct ScrollOffsetTracker: View {
    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: -proxy.frame(in: .named("mdaily_scroll")).origin.y
                )
        }
        .frame(height: 0)
    }
}

// MARK: - Auto-Scrolling / Edge-Fading Horizontal Text (Marquee)
public struct FadingHorizontalText: View {
    let text: String
    let font: Font
    let color: Color
    let textShadow: Bool

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isAnimating: Bool = false

    public init(
        _ text: String,
        font: Font = .system(size: 13, weight: .regular, design: .rounded),
        color: Color = .white,
        textShadow: Bool = false
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.textShadow = textShadow
    }

    public var body: some View {
        GeometryReader { geo in
            let overflow = textWidth > (geo.size.width + 1)

            ZStack(alignment: .leading) {
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .shadow(color: textShadow ? Color.black.opacity(0.5) : Color.clear, radius: 3, x: 0, y: 1)
                    .background(
                        GeometryReader { textGeo in
                            Color.clear.preference(key: TextWidthPreferenceKey.self, value: textGeo.size.width)
                        }
                    )
                    .offset(x: scrollOffset)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
            .clipped()
            .mask {
                if overflow {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(scrollOffset < -4 ? 0.15 : 1.0), location: 0.0),
                            .init(color: .black, location: 0.08),
                            .init(color: .black, location: 0.88),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    Rectangle().fill(Color.black)
                }
            }
            .onPreferenceChange(TextWidthPreferenceKey.self) { width in
                textWidth = width
                containerWidth = geo.size.width
                startMarqueeAnimationIfNeeded()
            }
        }
        .frame(height: 18)
    }

    private func startMarqueeAnimationIfNeeded() {
        guard textWidth > containerWidth, containerWidth > 0, !isAnimating else { return }
        isAnimating = true
        let diff = textWidth - containerWidth + 24
        let duration = Double(diff) / 16.0

        withAnimation(
            Animation.easeInOut(duration: max(2.5, duration))
                .delay(1.5)
                .repeatForever(autoreverses: true)
        ) {
            scrollOffset = -diff
        }
    }
}

public struct TextWidthPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat = 0
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
