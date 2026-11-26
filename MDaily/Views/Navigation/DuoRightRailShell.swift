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
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, leadingSafeMargin)
                    .mdailySoftScrollEdges()

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
            }
            .padding(.trailing, 76)

            // Soft ambient trailing edge fade behind the floating glass rail
            LinearGradient(
                colors: [Color.clear, Color.mdailyCanvas.opacity(0.88)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 96)
            .ignoresSafeArea(.container, edges: .vertical)
            .allowsHitTesting(false)

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

    @Namespace private var railNamespace

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
        MDailyGlassContainer(spacing: 10) {
            VStack(spacing: 10) {
                ForEach(AppTab.allCases) { tab in
                    railTabButton(for: tab)
                }

                Rectangle()
                    .fill(Color.mdailyHairline)
                    .frame(width: 24, height: 1)
                    .padding(.vertical, 2)

                railActionButton(
                    systemImage: "camera.fill",
                    accessibilityLabel: language == .en ? "Quick Capture" : "Chụp hóa đơn",
                    isActive: true,
                    action: onQuickCapture
                )

                if aiChatEnabled {
                    railActionButton(
                        systemImage: "sparkles",
                        accessibilityLabel: "MDaily AI",
                        isActive: true,
                        isHighlighted: showAiChat,
                        action: onToggleAiChat
                    )
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .frame(width: 56)
            .mdailyGlassSurface(in: Capsule(style: .continuous), interactive: true)
            .shadow(color: Color.black.opacity(0.10), radius: 14, x: 0, y: 4)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func railTabButton(for tab: AppTab) -> some View {
        let isSelected = activeTab == tab && !showAiChat
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                showAiChat = false
                activeTab = tab
            }
        } label: {
            Image(systemName: tab.iconName)
                .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.blue : Color.mdailyInk)
                .frame(width: 44, height: 44)
                .background {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(Color.blue.opacity(0.18))
                            .matchedGeometryEffect(id: "duoActiveTab", in: railNamespace)
                    }
                }
                .mdailyNavGlow(isActive: isSelected)
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(MDailyPressButtonStyle())
        .accessibilityLabel(tab.title(lang: language))
    }

    @ViewBuilder
    private func railActionButton(
        systemImage: String,
        accessibilityLabel: String,
        isActive: Bool,
        isHighlighted: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isHighlighted ? Color.white : Color.blue)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(isHighlighted ? Color.blue : Color.blue.opacity(0.16))
                }
                .mdailyNavGlow(isActive: isActive)
                .contentShape(Circle())
        }
        .buttonStyle(MDailyPressButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}
