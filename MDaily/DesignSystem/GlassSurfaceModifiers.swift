import SwiftUI

// MARK: - OS 26+ Native Liquid Glass Surface Modifiers

public struct MDailyGlassSurfaceModifier<S: Shape>: ViewModifier {
    public let shape: S
    public let interactive: Bool
    public let tint: Color?

    public init(shape: S, interactive: Bool = true, tint: Color? = nil) {
        self.shape = shape
        self.interactive = interactive
        self.tint = tint
    }

    public func body(content: Content) -> some View {
        #if os(visionOS)
        content
            .background(.ultraThinMaterial, in: shape)
            .overlay(shape.stroke(Color.mdailyHairline, lineWidth: 1))
        #else
        if #available(macOS 26.0, iOS 26.0, *) {
            content
                .glassEffect(resolvedGlass, in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(Color.mdailyHairline, lineWidth: 1))
        }
        #endif
    }

    #if !os(visionOS)
    @available(macOS 26.0, iOS 26.0, *)
    private var resolvedGlass: Glass {
        var glass = Glass.regular
        if let tint {
            glass = glass.tint(tint)
        }
        if interactive {
            glass = glass.interactive()
        }
        return glass
    }
    #endif
}

public struct MDailyGlassContainer<Content: View>: View {
    public let spacing: CGFloat?
    @ViewBuilder public let content: () -> Content

    public init(spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    public var body: some View {
        #if os(visionOS)
        content()
        #else
        if #available(macOS 26.0, iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
        #endif
    }
}

public extension View {
    func mdailyGlassSurface<S: Shape>(
        in shape: S = Capsule(),
        interactive: Bool = true,
        tint: Color? = nil
    ) -> some View {
        modifier(MDailyGlassSurfaceModifier(shape: shape, interactive: interactive, tint: tint))
    }

    func mdailyGlassPill(interactive: Bool = true, tint: Color? = nil) -> some View {
        mdailyGlassSurface(in: Capsule(style: .continuous), interactive: interactive, tint: tint)
    }

    func mdailyGlassToolbar(cornerRadius: CGFloat = 22, interactive: Bool = true) -> some View {
        mdailyGlassSurface(
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
            interactive: interactive,
            tint: nil
        )
    }
}
