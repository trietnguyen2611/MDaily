import SwiftUI
import PhotosUI

public enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case dashboard = "dashboard"
    case addExpense = "add-expense"
    case reports = "reports"
    case settings = "settings"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .dashboard: return "house"
        case .addExpense: return "plus"
        case .reports: return "chart.pie"
        case .settings: return "gearshape"
        }
    }
}

@MainActor
public struct LiquidGlassDock: View {
    @Binding public var activeTab: AppTab
    public var onQuickPhotoCaptured: (Data) -> Void
    public var isKeyboardActive: Bool = false

    @State private var showCameraPicker: Bool = false
    @State private var showLibraryPicker: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var dockNamespace

    private let selectionFeedback = UISelectionFeedbackGenerator()

    public init(
        activeTab: Binding<AppTab>,
        onQuickPhotoCaptured: @escaping (Data) -> Void,
        isKeyboardActive: Bool = false
    ) {
        self._activeTab = activeTab
        self.onQuickPhotoCaptured = onQuickPhotoCaptured
        self.isKeyboardActive = isKeyboardActive
    }

    public var body: some View {
        Group {
            if !isKeyboardActive {
                HStack(spacing: 12) {
                    capsuleTabs
                    cameraButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 2)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: isKeyboardActive)
        .fullScreenCover(isPresented: $showCameraPicker) {
            ImagePickerView(sourceType: .camera) { image in
                if let data = image.jpegData(compressionQuality: 0.85) {
                    onQuickPhotoCaptured(data)
                    activeTab = .addExpense
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showLibraryPicker) {
            ImagePickerView(sourceType: .photoLibrary) { image in
                if let data = image.jpegData(compressionQuality: 0.85) {
                    onQuickPhotoCaptured(data)
                    activeTab = .addExpense
                }
            }
        }
    }

    // MARK: - 4-Tab Main Capsule with Liquid Glass & Drag/Slide Support
    private var capsuleTabs: some View {
        let tabs = AppTab.allCases
        let capsuleWidth: CGFloat = 276
        let tabWidth: CGFloat = capsuleWidth / CGFloat(tabs.count)

        return HStack(spacing: 0) {
            ForEach(tabs) { tab in
                tabButton(for: tab)
            }
        }
        .frame(width: capsuleWidth, height: 60)
        .background {
            capsuleGlassBackground
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let x = value.location.x
                    let index = min(max(0, Int(x / tabWidth)), tabs.count - 1)
                    let targetTab = tabs[index]
                    if targetTab != activeTab {
                        selectionFeedback.selectionChanged()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                            activeTab = targetTab
                        }
                    }
                }
        )
    }

    /// Glass background for the dock capsule — uses native .glassEffect on iOS 26+, falls back to custom material
    @ViewBuilder
    private var capsuleGlassBackground: some View {
        let capsuleShape = Capsule(style: .continuous)

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            // iOS 26+: Use native Apple Liquid Glass
            capsuleShape
                .fill(.clear)
                .glassEffect(.regular.interactive(), in: .capsule)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.10),
                    radius: 20,
                    x: 0,
                    y: 8
                )
        } else {
            fallbackGlassBackground
        }
        #else
        fallbackGlassBackground
        #endif
    }

    /// Fallback glass background for pre-iOS 26
    private var fallbackGlassBackground: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
            Capsule(style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.35))
            Capsule(style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(colorScheme == .dark ? 0.35 : 0.85), location: 0.0),
                            .init(color: Color.white.opacity(colorScheme == .dark ? 0.10 : 0.35), location: 0.5),
                            .init(color: Color.white.opacity(colorScheme == .dark ? 0.04 : 0.10), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.10),
            radius: 20,
            x: 0,
            y: 8
        )
    }

    @ViewBuilder
    private func tabButton(for tab: AppTab) -> some View {
        let isSelected: Bool = activeTab == tab
        let iconColor: Color = isSelected
            ? Color.white
            : (colorScheme == .dark ? Color.white.opacity(0.60) : Color.black.opacity(0.50))

        Image(systemName: tab.iconName)
            .font(.system(size: 20, weight: isSelected ? .bold : .regular))
            .foregroundColor(iconColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.16, green: 0.72, blue: 0.54), Color(red: 0.08, green: 0.48, blue: 0.68)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.40), lineWidth: 0.65)
                        }
                        .matchedGeometryEffect(id: "activeTabPill", in: dockNamespace)
                        .shadow(color: Color(red: 0.16, green: 0.72, blue: 0.54).opacity(0.40), radius: 8, x: 0, y: 3)
                        .padding(4)
                }
            }
            .frame(height: 52)
    }

    // MARK: - Standalone Camera Button (Direct Camera Trigger)
    private var cameraButton: some View {
        Button {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                showCameraPicker = true
            } else {
                showLibraryPicker = true
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.16, green: 0.72, blue: 0.54), Color(red: 0.08, green: 0.48, blue: 0.68)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.40), lineWidth: 0.75)
                    }
                    .shadow(
                        color: Color(red: 0.16, green: 0.72, blue: 0.54).opacity(0.40),
                        radius: 12,
                        x: 0,
                        y: 5
                    )

                Image(systemName: "camera")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 60)
        }
        .liquidGlassButton()
    }
}
