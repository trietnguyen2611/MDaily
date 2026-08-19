import SwiftUI
import PhotosUI

public enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "dashboard"
    case addExpense = "add-expense"
    case reports = "reports"
    case settings = "settings"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .dashboard: return "house.fill"
        case .addExpense: return "plus"
        case .reports: return "chart.pie.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct LiquidGlassDock: View {
    @Binding public var activeTab: AppTab
    public var onQuickPhotoCaptured: (Data) -> Void
    public var isKeyboardActive: Bool = false

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCameraPicker: Bool = false
    @Environment(\.colorScheme) var colorScheme

    public var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Ambient Frosted Glass Scrim
            if !isKeyboardActive {
                LinearGradient(
                    colors: [
                        Color.clear,
                        (colorScheme == .dark ? Color.black : Color.white).opacity(0.65),
                        (colorScheme == .dark ? Color.black : Color.white).opacity(0.92)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .allowsHitTesting(false)
            }

            // 2. Floating Liquid Glass Dock
            if !isKeyboardActive {
                HStack(spacing: 12) {
                    // Main 4-Tab Capsule
                    HStack(spacing: 0) {
                        ForEach(AppTab.allCases) { tab in
                            Button {
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                                    activeTab = tab
                                }
                            } label: {
                                Image(systemName: tab.iconName)
                                    .font(.system(size: 20, weight: activeTab == tab ? .semibold : .regular))
                                    .foregroundColor(activeTab == tab ? Color.white : (colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.55)))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background {
                                        if activeTab == tab {
                                            Capsule(style: .continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.blue, Color(red: 0, green: 0.75, blue: 0.95)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .matchedGeometryEffect(id: "activeTabPill", in: dockNamespace)
                                                .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 3)
                                                .padding(4)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .frame(height: 52)
                        }
                    }
                    .frame(maxWidth: 240, height: 58)
                    .background {
                        Capsule(style: .continuous)
                            .fill(
                                colorScheme == .dark
                                    ? Color(white: 0.16).opacity(0.72)
                                    : Color.white.opacity(0.75)
                            )
                            .background(Capsule().fill(.ultraThinMaterial))
                            .overlay {
                                Capsule(style: .continuous)
                                    .strokeBorder(
                                        Color.white.opacity(colorScheme == .dark ? 0.30 : 0.85),
                                        lineWidth: 0.5
                                    )
                            }
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.10), radius: 20, x: 0, y: 8)
                    }

                    // Standalone Circular Camera Action Button
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack {
                            Circle()
                                .fill(
                                    colorScheme == .dark
                                        ? Color(white: 0.16).opacity(0.72)
                                        : Color.white.opacity(0.75)
                                )
                                .background(Circle().fill(.ultraThinMaterial))
                                .overlay {
                                    Circle()
                                        .strokeBorder(
                                            Color.white.opacity(colorScheme == .dark ? 0.30 : 0.85),
                                            lineWidth: 0.5
                                        )
                                }
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.10), radius: 20, x: 0, y: 8)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Color.blue)
                        }
                        .frame(width: 58, height: 58)
                    }
                    .buttonStyle(.plain)
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        guard let newItem else { return }
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    onQuickPhotoCaptured(data)
                                    activeTab = .addExpense
                                    selectedPhotoItem = nil
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isKeyboardActive)
    }

    @Namespace private var dockNamespace
}
