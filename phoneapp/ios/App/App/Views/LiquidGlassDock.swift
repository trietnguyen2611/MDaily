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
        case .dashboard: return "house.fill"
        case .addExpense: return "plus"
        case .reports: return "chart.pie.fill"
        case .settings: return "gearshape.fill"
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
                .padding(.bottom, 12)
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

    // MARK: - 4-Tab Main Capsule
    private var capsuleTabs: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .frame(width: 276, height: 62)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule(style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.35))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.45 : 0.85), location: 0.0),
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35), location: 0.5),
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.04 : 0.10), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )
                }
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.10),
                    radius: 20,
                    x: 0,
                    y: 8
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.04),
                    radius: 6,
                    x: 0,
                    y: 2
                )
        }
    }

    @ViewBuilder
    private func tabButton(for tab: AppTab) -> some View {
        let isSelected: Bool = activeTab == tab
        let iconColor: Color = isSelected
            ? Color.white
            : (colorScheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.50))

        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                activeTab = tab
            }
        } label: {
            Image(systemName: tab.iconName)
                .font(.system(size: 21, weight: isSelected ? .bold : .regular))
                .foregroundColor(iconColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color(red: 0, green: 0.68, blue: 0.96)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                Capsule(style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.40), lineWidth: 0.65)
                            }
                            .matchedGeometryEffect(id: "activeTabPill", in: dockNamespace)
                            .shadow(color: Color.blue.opacity(0.40), radius: 8, x: 0, y: 3)
                            .padding(4)
                    }
                }
        }
        .buttonStyle(.plain)
        .frame(height: 54)
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
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.35))
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(colorScheme == .dark ? 0.45 : 0.85), location: 0.0),
                                        .init(color: Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35), location: 0.5),
                                        .init(color: Color.white.opacity(colorScheme == .dark ? 0.04 : 0.10), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.75
                            )
                    }
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.10),
                        radius: 20,
                        x: 0,
                        y: 8
                    )
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.04),
                        radius: 6,
                        x: 0,
                        y: 2
                    )

                Image(systemName: "camera.fill")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundColor(Color.blue)
            }
            .frame(width: 62, height: 62)
        }
        .liquidGlassButton()
    }
}
