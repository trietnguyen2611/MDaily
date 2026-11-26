import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Notification Triggers

public extension Notification.Name {
    static let mdailyNewTransaction = Notification.Name("com.mdaily.newTransaction")
    static let mdailyFocusSearch = Notification.Name("com.mdaily.focusSearch")
    static let mdailySwitchTab = Notification.Name("com.mdaily.switchTab")
    static let mdailyToggleAIChat = Notification.Name("com.mdaily.toggleAIChat")
    static let mdailyQuickCapture = Notification.Name("com.mdaily.quickCapture")
}

// MARK: - Adaptive Color Initializers

public extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.darkAqua, .aqua])
            return match == .darkAqua ? NSColor(dark) : NSColor(light)
        })
        #else
        self = light
        #endif
    }
}

// MARK: - Design Tokens (DESIGN.md + Finance Semantics)

public enum MDailyColors {
    // Brand & Interactive Accent (single interactive accent rule)
    public static let actionBlue = Color(light: Color(hex: 0x0066CC), dark: Color(hex: 0x2997FF))
    public static let primary = actionBlue
    public static let focusBlue = Color(hex: 0x0071E3)
    public static let skyLinkBlue = Color(hex: 0x2997FF)

    // Financial Semantics
    public static let incomeGreen = Color(light: Color(hex: 0x1A8F55), dark: Color(hex: 0x30D158))
    public static let ink = Color(light: Color(hex: 0x1D1D1F), dark: Color(hex: 0xFFFFFF))
    public static let expenseInk = ink
    public static let destructiveRed = Color(light: Color(hex: 0xD70015), dark: Color(hex: 0xFF453A))

    // Gallery Surfaces
    public static let canvas = Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x000000))
    public static let parchment = Color(light: Color(hex: 0xF5F5F7), dark: Color(hex: 0x1C1C1E))
    public static let cardSurface = Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1C1C1E))
    public static let secondaryTile = Color(light: Color(hex: 0xF5F5F7), dark: Color(hex: 0x272729))
    public static let pearl = Color(light: Color(hex: 0xFAFAFC), dark: Color(hex: 0x272729))

    // Dark Tiles from DESIGN.md
    public static let tileDark1 = Color(hex: 0x272729)
    public static let tileDark2 = Color(hex: 0x2A2A2C)
    public static let tileDark3 = Color(hex: 0x252527)
    public static let pureBlack = Color(hex: 0x000000)

    // Text & Muted Inks
    public static let inkMuted80 = Color(light: Color(hex: 0x333333), dark: Color(hex: 0xCCCCCC))
    public static let mutedInk = Color(light: Color(hex: 0x7A7A7A), dark: Color(hex: 0x98989D))
    public static let chipTranslucent = Color(
        light: Color(hex: 0xD2D2D7, alpha: 0.64),
        dark: Color.white.opacity(0.16)
    )

    // Hairlines & Borders
    public static let hairline = Color(light: Color(hex: 0xE0E0E0), dark: Color.white.opacity(0.12))
    public static let dividerSoft = Color(light: Color(hex: 0xF0F0F0), dark: Color.white.opacity(0.08))
}

public extension Color {
    static let mdailyCanvas = MDailyColors.canvas
    static let mdailyParchment = MDailyColors.parchment
    static let mdailyCardSurface = MDailyColors.cardSurface
    static let mdailySecondaryTile = MDailyColors.secondaryTile
    static let mdailyPearl = MDailyColors.pearl
    static let mdailyHairline = MDailyColors.hairline
    static let mdailyDividerSoft = MDailyColors.dividerSoft
    static let mdailyActionBlue = MDailyColors.actionBlue
    static let mdailyFocusBlue = MDailyColors.focusBlue
    static let mdailySkyBlue = MDailyColors.skyLinkBlue
    static let mdailyIncomeGreen = MDailyColors.incomeGreen
    static let mdailyInk = MDailyColors.ink
    static let mdailyInkMuted80 = MDailyColors.inkMuted80
    static let mdailyMutedInk = MDailyColors.mutedInk
    static let mdailyDestructiveRed = MDailyColors.destructiveRed
}

public enum MDailySpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 17
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
    public static let section: CGFloat = 80
}

public enum MDailyRadius {
    public static let none: CGFloat = 0
    public static let xs: CGFloat = 5
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 11
    public static let lg: CGFloat = 18
    public static let pill: CGFloat = 9999
}

public enum MDailyTypography {
    public static let heroDisplay = Font.system(size: 56, weight: .semibold, design: .default)
    public static let displayLg = Font.system(size: 40, weight: .semibold, design: .default)
    public static let displayMd = Font.system(size: 34, weight: .semibold, design: .default)
    public static let lead = Font.system(size: 28, weight: .regular, design: .default)
    public static let leadAiry = Font.system(size: 24, weight: .light, design: .default)
    public static let tagline = Font.system(size: 21, weight: .semibold, design: .default)
    public static let bodyStrong = Font.system(size: 17, weight: .semibold, design: .default)
    public static let body = Font.system(size: 17, weight: .regular, design: .default)
    public static let captionStrong = Font.system(size: 14, weight: .semibold, design: .default)
    public static let caption = Font.system(size: 14, weight: .regular, design: .default)
    public static let finePrint = Font.system(size: 12, weight: .regular, design: .default)
    public static let microLegal = Font.system(size: 10, weight: .regular, design: .default)

    public enum Tracking {
        public static let heroDisplay: CGFloat = -0.28
        public static let displayMd: CGFloat = -0.374
        public static let body: CGFloat = -0.374
        public static let caption: CGFloat = -0.224
        public static let finePrint: CGFloat = -0.12
        public static let microLegal: CGFloat = -0.08
    }
}

// MARK: - Cross-Platform Image Helper

public extension Image {
    init?(platformImageData data: Data) {
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return nil }
        self.init(uiImage: uiImage)
        #elseif canImport(AppKit)
        guard let nsImage = NSImage(data: data) else { return nil }
        self.init(nsImage: nsImage)
        #else
        return nil
        #endif
    }
}

// MARK: - Cross-Platform View Modifiers

public extension View {
    @ViewBuilder
    func platformNumericKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    @ViewBuilder
    func platformInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func platformLargeNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
    }

    func mdailyCard(
        cornerRadius: CGFloat = MDailyRadius.lg,
        background: Color = .mdailyCardSurface
    ) -> some View {
        modifier(MDailyCardModifier(cornerRadius: cornerRadius, background: background))
    }

    func mdailyPressScale() -> some View {
        modifier(MDailyPressScaleModifier())
    }
}

// MARK: - Card & Press Modifiers

public struct MDailyCardModifier: ViewModifier {
    public let cornerRadius: CGFloat
    public let background: Color

    public init(
        cornerRadius: CGFloat = MDailyRadius.lg,
        background: Color = .mdailyCardSurface
    ) {
        self.cornerRadius = cornerRadius
        self.background = background
    }

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        #if os(visionOS)
        content
            .background(.ultraThinMaterial, in: shape)
            .overlay(shape.strokeBorder(Color.mdailyHairline, lineWidth: 1))
        #else
        if #available(macOS 26.0, iOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.strokeBorder(Color.mdailyHairline, lineWidth: 1))
        }
        #endif
    }
}

public struct MDailyPressButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

public struct MDailyPressScaleModifier: ViewModifier {
    @State private var isPressed = false

    public init() {}

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed { isPressed = true }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

public struct MDailyPrimaryPillButtonStyle: ButtonStyle {
    public var isDisabled: Bool

    public init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MDailyTypography.body)
            .tracking(MDailyTypography.Tracking.body)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 11)
            .background(
                Capsule(style: .continuous)
                    .fill(isDisabled ? Color.mdailyMutedInk.opacity(0.4) : Color.mdailyActionBlue)
            )
            .scaleEffect(configuration.isPressed && !isDisabled ? 0.95 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

public struct MDailySecondaryPillButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MDailyTypography.body)
            .tracking(MDailyTypography.Tracking.body)
            .foregroundStyle(Color.mdailyActionBlue)
            .padding(.horizontal, 22)
            .padding(.vertical, 11)
            .background(
                Capsule(style: .continuous)
                    .strokeBorder(Color.mdailyActionBlue, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

// MARK: - Shared Close Button

public struct MDailyCloseButton: View {
    public let action: () -> Void
    public var accessibilityLabel: String

    public init(accessibilityLabel: String = "Close", action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.mdailyInk)
                .frame(width: 28, height: 28)
        }
        .buttonBorderShape(.circle)
        .mdailyGlassButton(prominent: false)
        .accessibilityLabel(accessibilityLabel)
    }
}
