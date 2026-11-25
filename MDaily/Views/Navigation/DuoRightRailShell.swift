import SwiftUI

public struct DuoRightRailShell<Content: View, Inspector: View>: View {
    public let profile: AdaptiveLayoutProfile
    @Binding public var activeTab: AppTab
    public let language: Language
    public let aiChatEnabled: Bool
    @Binding public var showAiChat: Bool
    public let isInspectorPresented: Bool
    public let onQuickCapture: () -> Void
    public let onToggleAiChat: () -> Void
    @ViewBuilder public let content: () -> Content
    @ViewBuilder public let inspector: () -> Inspector

    public init(
        profile: AdaptiveLayoutProfile,
        activeTab: Binding<AppTab>,
        language: Language,
        aiChatEnabled: Bool,
        showAiChat: Binding<Bool>,
        isInspectorPresented: Bool,
        onQuickCapture: @escaping () -> Void,
        onToggleAiChat: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder inspector: @escaping () -> Inspector
    ) {
        self.profile = profile
        self._activeTab = activeTab
        self.language = language
        self.aiChatEnabled = aiChatEnabled
        self._showAiChat = showAiChat
        self.isInspectorPresented = isInspectorPresented
        self.onQuickCapture = onQuickCapture
        self.onToggleAiChat = onToggleAiChat
        self.content = content
        self.inspector = inspector
    }

    private var leadingSafeMargin: CGFloat {
        // Clear the 8pt left hinge bezel comfortably when folded (466x678pt)
        profile == .iPhoneDuoFolded ? 24 : 20
    }

    public var body: some View {
        HStack(spacing: 0) {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, leadingSafeMargin)

            if profile == .iPhoneDuoUnfolded && isInspectorPresented {
                Rectangle()
                    .fill(Color.mdailyHairline)
                    .frame(width: 1)
                    .ignoresSafeArea(.container, edges: .vertical)

                inspector()
                    .frame(width: 340)
                    .frame(maxHeight: .infinity)
                    .background(Color.mdailyCanvas)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            DuoRightNavigationRail(
                activeTab: $activeTab,
                language: language,
                aiChatEnabled: aiChatEnabled,
                showAiChat: $showAiChat,
                onQuickCapture: onQuickCapture,
                onToggleAiChat: onToggleAiChat
            )
            // Keep clear of 55-59pt right corner radii on iPhone Duo hardware
            .padding(.vertical, 28)
            .padding(.leading, 6)
            .padding(.trailing, 10)
        }
        .background(Color.mdailyCanvas.ignoresSafeArea())
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: isInspectorPresented)
    }
}

public struct DuoRightNavigationRail: View {
    @Binding public var activeTab: AppTab
    public let language: Language
    public let aiChatEnabled: Bool
    @Binding public var showAiChat: Bool
    public let onQuickCapture: () -> Void
    public let onToggleAiChat: () -> Void

    public init(
        activeTab: Binding<AppTab>,
        language: Language,
        aiChatEnabled: Bool,
        showAiChat: Binding<Bool>,
        onQuickCapture: @escaping () -> Void,
        onToggleAiChat: @escaping () -> Void
    ) {
        self._activeTab = activeTab
        self.language = language
        self.aiChatEnabled = aiChatEnabled
        self._showAiChat = showAiChat
        self.onQuickCapture = onQuickCapture
        self.onToggleAiChat = onToggleAiChat
    }

    public var body: some View {
        MDailyGlassContainer(spacing: 8) {
            VStack(spacing: 8) {
                ForEach(AppTab.allCases) { tab in
                    railTabButton(for: tab)
                }

                Rectangle()
                    .fill(Color.mdailyHairline)
                    .frame(width: 28, height: 1)
                    .padding(.vertical, 4)

                railActionButton(
                    systemImage: "camera.fill",
                    label: language == .en ? "Scan" : "Chụp",
                    isActive: false,
                    action: onQuickCapture
                )

                if aiChatEnabled {
                    railActionButton(
                        systemImage: "sparkles",
                        label: "AI",
                        isActive: showAiChat,
                        action: onToggleAiChat
                    )
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .frame(width: 60)
            .mdailyGlassSurface(in: Capsule(style: .continuous), interactive: true)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func railTabButton(for tab: AppTab) -> some View {
        let isSelected = activeTab == tab && !showAiChat
        Button {
            showAiChat = false
            activeTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                Text(shortLabel(for: tab))
                    .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? Color.mdailyActionBlue : Color.mdailyInk)
            .frame(width: 48, height: 48)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Color.mdailyActionBlue.opacity(0.14))
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(MDailyPressButtonStyle())
        .accessibilityLabel(tab.title(lang: language))
    }

    @ViewBuilder
    private func railActionButton(
        systemImage: String,
        label: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: isActive ? .semibold : .medium))
                Text(label)
                    .font(.system(size: 9, weight: isActive ? .semibold : .regular))
                    .lineLimit(1)
            }
            .foregroundStyle(isActive ? Color.white : Color.mdailyActionBlue)
            .frame(width: 48, height: 48)
            .background {
                if isActive {
                    Circle()
                        .fill(Color.mdailyActionBlue)
                } else {
                    Circle()
                        .fill(Color.mdailyActionBlue.opacity(0.10))
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(MDailyPressButtonStyle())
        .accessibilityLabel(label)
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
