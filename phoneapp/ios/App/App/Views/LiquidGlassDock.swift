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

    @State private var showPhotoSourceDialog: Bool = false
    @State private var showCameraPicker: Bool = false
    @State private var showLibraryPicker: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?

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
        ZStack(alignment: .bottom) {
            // 1. Ambient Frosted Glass Scrim under content
            if !isKeyboardActive {
                dockScrim
                dockContent
            }
        }
        .animation(.spring(response: 0.40, dampingFraction: 0.82), value: isKeyboardActive)
        .confirmationDialog("Chọn ảnh hoá đơn / chi tiêu", isPresented: $showPhotoSourceDialog, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Chụp ảnh từ Máy ảnh") {
                    showCameraPicker = true
                }
            }
            Button("Chọn từ Thư viện ảnh") {
                showLibraryPicker = true
            }
            Button("Huỷ", role: .cancel) {}
        }
        .sheet(isPresented: $showCameraPicker) {
            ImagePickerView(sourceType: .camera) { image in
                if let data = image.jpegData(compressionQuality: 0.85) {
                    onQuickPhotoCaptured(data)
                    activeTab = .addExpense
                }
            }
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

    // MARK: - Subviews
    private var dockScrim: some View {
        let baseColor: Color = colorScheme == .dark ? Color.black : Color.white
        return LinearGradient(
            stops: [
                .init(color: Color.clear, location: 0.0),
                .init(color: baseColor.opacity(0.45), location: 0.35),
                .init(color: baseColor.opacity(0.85), location: 0.70),
                .init(color: baseColor.opacity(0.96), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 110)
        .allowsHitTesting(false)
    }

    private var dockContent: some View {
        HStack(spacing: 12) {
            capsuleTabs
            cameraButton
        }
        .padding(.bottom, 6)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - 4-Tab Main Capsule
    private var capsuleTabs: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .frame(width: 240, height: 56)
        .background {
            Capsule(style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? Color(white: 0.15).opacity(0.70)
                        : Color.white.opacity(0.72)
                )
                .background(Capsule().fill(.ultraThinMaterial))
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.40 : 0.88),
                                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.38 : 0.08),
                    radius: 22,
                    x: 0,
                    y: 8
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
            withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
                activeTab = tab
            }
        } label: {
            Image(systemName: tab.iconName)
                .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                .foregroundColor(iconColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color(red: 0, green: 0.72, blue: 0.96)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                Capsule(style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
                            }
                            .matchedGeometryEffect(id: "activeTabPill", in: dockNamespace)
                            .shadow(color: Color.blue.opacity(0.38), radius: 8, x: 0, y: 3)
                            .padding(4)
                    }
                }
        }
        .buttonStyle(.plain)
        .frame(height: 50)
    }

    // MARK: - Standalone Camera Button
    private var cameraButton: some View {
        Button {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                showPhotoSourceDialog = true
            } else {
                // Directly open photo library on simulator / device without camera
                showLibraryPicker = true
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        colorScheme == .dark
                            ? Color(white: 0.15).opacity(0.70)
                            : Color.white.opacity(0.72)
                    )
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.40 : 0.88),
                                        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.38 : 0.08),
                        radius: 22,
                        x: 0,
                        y: 8
                    )

                Image(systemName: "camera.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(Color.blue)
            }
            .frame(width: 56, height: 56)
        }
        .liquidGlassButton()
    }
}
