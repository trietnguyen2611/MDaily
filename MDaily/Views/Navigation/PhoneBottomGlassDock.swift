import SwiftUI

public struct PhoneBottomGlassDock: View {
    @Binding public var activeTab: AppTab
    public let language: Language
    public let onQuickCapture: () -> Void

    @Namespace private var dockNamespace

    public init(
        activeTab: Binding<AppTab>,
        language: Language,
        onQuickCapture: @escaping () -> Void
    ) {
        self._activeTab = activeTab
        self.language = language
        self.onQuickCapture = onQuickCapture
    }

    public var body: some View {
        MDailyGlassContainer(spacing: 12) {
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(AppTab.allCases) { tab in
                        dockTabButton(for: tab)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .mdailyGlassSurface(in: Capsule(style: .continuous), interactive: true)
                .shadow(color: Color.black.opacity(0.10), radius: 14, x: 0, y: 4)

                Button(action: onQuickCapture) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.blue)
                        .frame(width: 54, height: 54)
                        .contentShape(Circle())
                }
                .buttonStyle(MDailyPressButtonStyle())
                .mdailyGlassSurface(in: Circle(), interactive: true, tint: Color.blue.opacity(0.18))
                .mdailyNavGlow(isActive: true)
                .accessibilityLabel(language == .en ? "Quick Receipt Capture" : "Chụp hóa đơn nhanh")
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func dockTabButton(for tab: AppTab) -> some View {
        let isSelected = activeTab == tab
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                activeTab = tab
            }
        } label: {
            Image(systemName: tab.iconName)
                .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.blue : Color.mdailyInk)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(Color.blue.opacity(0.18))
                            .matchedGeometryEffect(id: "phoneActiveTab", in: dockNamespace)
                    }
                }
                .mdailyNavGlow(isActive: isSelected)
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(MDailyPressButtonStyle())
        .accessibilityLabel(tab.title(lang: language))
    }
}
