import SwiftUI

public struct PhoneBottomGlassDock: View {
    @Binding public var activeTab: AppTab
    public let language: Language
    public let onQuickCapture: () -> Void

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

                Button(action: onQuickCapture) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.mdailyActionBlue)
                        .frame(width: 52, height: 52)
                        .contentShape(Circle())
                }
                .buttonStyle(MDailyPressButtonStyle())
                .mdailyGlassSurface(in: Circle(), interactive: true)
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
            activeTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                Text(shortLabel(for: tab))
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? Color.mdailyActionBlue : Color.mdailyInk)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .padding(.horizontal, 6)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Color.mdailyActionBlue.opacity(0.14))
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(MDailyPressButtonStyle())
    }

    private func shortLabel(for tab: AppTab) -> String {
        switch tab {
        case .dashboard: return language == .en ? "Home" : "Tổng quan"
        case .addTransaction: return language == .en ? "Add" : "Ghi"
        case .reports: return language == .en ? "Reports" : "Báo cáo"
        case .settings: return language == .en ? "Settings" : "Cài đặt"
        }
    }
}
