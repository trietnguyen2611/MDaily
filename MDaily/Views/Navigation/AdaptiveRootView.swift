import SwiftUI

public struct AdaptiveRootView: View {
    @StateObject private var store = FinanceStore()
    @StateObject private var syncService = BonjourSyncService()
    @ObservedObject private var posture = DevicePostureService.shared

    @State private var activeTab: AppTab = .dashboard
    @State private var searchText: String = ""
    @State private var kindFilter: TransactionKindFilter = .all
    @State private var timeFilterMode: TimeFilterMode = .preset(.all)
    @State private var categoryFilter: String = "all"

    @State private var selectedTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var showAiChat: Bool = false
    @State private var showQuickCapture: Bool = false
    @State private var capturedPhotoData: Data? = nil

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            let profile = posture.resolveProfile(for: geo.size)
            rootShell(for: profile)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.mdailyCanvas)
                .preferredColorScheme(resolvedColorScheme)
                .sheet(item: modalTransactionBinding(for: profile)) { tx in
                    TransactionDetailView(
                        store: store,
                        transaction: tx,
                        startInEditMode: editingTransaction?.id == tx.id,
                        onClose: closeTransactionDetail
                    )
                }
                .sheet(isPresented: modalAiChatBinding(for: profile)) {
                    ChatbotView(store: store, onClose: { showAiChat = false })
                }
                .sheet(isPresented: $showQuickCapture) {
                    QuickCaptureView(
                        store: store,
                        onPhotoCaptured: { data in
                            capturedPhotoData = data
                            showQuickCapture = false
                            activeTab = .addTransaction
                        },
                        onDismiss: {
                            showQuickCapture = false
                        }
                    )
                }
        }
        #if os(macOS)
        .frame(minWidth: 920, minHeight: 640)
        #endif
        .onAppear {
            syncService.start(store: store)
        }
        .onChange(of: store.transactions) { _, updated in
            if let current = selectedTransaction {
                if let refreshed = updated.first(where: { $0.id == current.id }) {
                    selectedTransaction = refreshed
                } else {
                    selectedTransaction = nil
                    editingTransaction = nil
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .mdailyNewTransaction)) { _ in
            capturedPhotoData = nil
            activeTab = .addTransaction
        }
        .onReceive(NotificationCenter.default.publisher(for: .mdailyQuickCapture)) { _ in
            showQuickCapture = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .mdailyFocusSearch)) { _ in
            if activeTab != .dashboard {
                activeTab = .dashboard
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .mdailySwitchTab)) { note in
            if let tab = note.object as? AppTab {
                activeTab = tab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .mdailyToggleAIChat)) { _ in
            guard store.aiChatEnabled else { return }
            if showAiChat {
                showAiChat = false
            } else {
                openAiChat()
            }
        }
    }

    // MARK: - Profile Branching

    @ViewBuilder
    private func rootShell(for profile: AdaptiveLayoutProfile) -> some View {
        switch profile {
        case .iPhoneDuoFolded, .iPhoneDuoUnfolded:
            DuoRightRailShell(
                profile: profile,
                activeTab: $activeTab,
                language: store.language,
                aiChatEnabled: store.aiChatEnabled,
                showAiChat: $showAiChat,
                isInspectorPresented: selectedTransaction != nil || showAiChat,
                onQuickCapture: { showQuickCapture = true },
                onToggleAiChat: toggleAiChat
            ) {
                tabContent(for: profile)
            } inspector: {
                inspectorContent
            }

        case .standardPhone:
            VStack(spacing: 0) {
                standardPhoneHeader
                tabContent(for: profile)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mdailySoftScrollEdges()
            }
            .background(Color.mdailyCanvas.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [Color.clear, Color.mdailyCanvas.opacity(0.88)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 88)
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)

                    PhoneBottomGlassDock(
                        activeTab: $activeTab,
                        language: store.language,
                        onQuickCapture: { showQuickCapture = true }
                    )
                }
            }

        case .pad, .mac:
            splitNavigationShell(for: profile)
        }
    }

    // MARK: - Standard Phone Top Strip

    private var standardPhoneHeader: some View {
        HStack(spacing: 12) {
            Text(tabTitle(for: activeTab))
                .font(MDailyTypography.tagline)
                .foregroundStyle(Color.mdailyInk)

            Spacer()

            if store.aiChatEnabled {
                Button(action: toggleAiChat) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(showAiChat ? Color.white : Color.blue)
                        .frame(width: 36, height: 36)
                        .background {
                            if showAiChat {
                                Circle().fill(Color.blue)
                            }
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(MDailyPressButtonStyle())
                .mdailyGlassSurface(
                    in: Circle(),
                    interactive: true,
                    tint: showAiChat ? Color.blue.opacity(0.3) : Color.blue.opacity(0.14)
                )
                .mdailyNavGlow(isActive: true)
                .accessibilityLabel("MDaily AI")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.mdailyCanvas)
    }

    // MARK: - Pad & Mac Split View

    private func splitNavigationShell(for profile: AdaptiveLayoutProfile) -> some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(AppTab.allCases, selection: sidebarSelectionBinding) { tab in
                Label(tabTitle(for: tab), systemImage: tab.iconName)
                    .tag(tab)
            }
            .navigationSplitViewColumnWidth(205)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            tabContent(for: profile)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .mdailySoftScrollEdges()
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            showQuickCapture = true
                        } label: {
                            Label(
                                store.language == .en ? "Quick Capture" : "Chụp nhanh",
                                systemImage: "camera.fill"
                            )
                        }

                        if store.aiChatEnabled {
                            Button(action: toggleAiChat) {
                                Label("MDaily AI", systemImage: "sparkles")
                            }
                            .tint(showAiChat ? Color.blue : nil)
                        }
                    }
                }
                .inspector(isPresented: inlineInspectorBinding) {
                    inspectorContent
                        .inspectorColumnWidth(min: 320, ideal: 360, max: 440)
                }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var sidebarSelectionBinding: Binding<AppTab?> {
        Binding(
            get: { activeTab },
            set: { newValue in
                if let newValue {
                    activeTab = newValue
                }
            }
        )
    }

    // MARK: - Active Tab Content

    @ViewBuilder
    private func tabContent(for profile: AdaptiveLayoutProfile) -> some View {
        switch activeTab {
        case .dashboard:
            DashboardView(
                store: store,
                transactions: filteredTransactions,
                searchText: $searchText,
                kindFilter: $kindFilter,
                timeFilterMode: $timeFilterMode,
                categoryFilter: $categoryFilter,
                layoutProfile: profile,
                onSelectTransaction: { tx in
                    editingTransaction = nil
                    showAiChat = false
                    selectedTransaction = tx
                },
                onEditTransaction: { tx in
                    editingTransaction = tx
                    showAiChat = false
                    selectedTransaction = tx
                }
            )

        case .addTransaction:
            AddTransactionView(
                store: store,
                initialPhotoData: capturedPhotoData,
                layoutProfile: profile,
                onSave: {
                    capturedPhotoData = nil
                    activeTab = .dashboard
                },
                onCancel: {
                    capturedPhotoData = nil
                    activeTab = .dashboard
                }
            )

        case .reports:
            ReportsView(
                store: store,
                transactions: filteredTransactions,
                timeFilterMode: $timeFilterMode,
                layoutProfile: profile
            )

        case .settings:
            SettingsView(
                store: store,
                syncService: syncService,
                onOpenChat: openAiChat
            )
        }
    }

    @ViewBuilder
    private var inspectorContent: some View {
        if let tx = selectedTransaction {
            TransactionDetailView(
                store: store,
                transaction: tx,
                startInEditMode: editingTransaction?.id == tx.id,
                onClose: closeTransactionDetail
            )
        } else if showAiChat {
            ChatbotView(
                store: store,
                onClose: { showAiChat = false }
            )
        } else {
            EmptyView()
        }
    }

    // MARK: - Filtering & Helpers

    private var filteredTransactions: [Transaction] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedQuery = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        return store.transactions
            .filter { tx in
                switch kindFilter {
                case .all:
                    break
                case .expense:
                    if tx.kind != .expense { return false }
                case .income:
                    if tx.kind != .income { return false }
                }

                if categoryFilter != "all" && tx.categoryId != categoryFilter {
                    return false
                }

                if !timeFilterMode.matches(tx.date) {
                    return false
                }

                if !normalizedQuery.isEmpty {
                    let noteMatch = (tx.note ?? "")
                        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                        .contains(normalizedQuery)
                    let categoryLabel = store.categories
                        .first(where: { $0.id == tx.categoryId })?
                        .localizedLabel(lang: store.language) ?? tx.categoryId
                    let categoryMatch = categoryLabel
                        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                        .contains(normalizedQuery)
                    let amountMatch = String(Int(tx.amount)).contains(normalizedQuery)
                    if !noteMatch && !categoryMatch && !amountMatch {
                        return false
                    }
                }

                return true
            }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date {
                    return lhs.date > rhs.date
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private var resolvedColorScheme: ColorScheme? {
        switch store.appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private var inlineInspectorBinding: Binding<Bool> {
        Binding(
            get: { selectedTransaction != nil || showAiChat },
            set: { isPresented in
                if !isPresented {
                    selectedTransaction = nil
                    editingTransaction = nil
                    showAiChat = false
                }
            }
        )
    }

    private func modalTransactionBinding(for profile: AdaptiveLayoutProfile) -> Binding<Transaction?> {
        Binding(
            get: { profile.supportsInlineInspector ? nil : selectedTransaction },
            set: { newValue in
                if newValue == nil && !profile.supportsInlineInspector {
                    closeTransactionDetail()
                }
            }
        )
    }

    private func modalAiChatBinding(for profile: AdaptiveLayoutProfile) -> Binding<Bool> {
        Binding(
            get: { profile.supportsInlineInspector ? false : showAiChat },
            set: { isPresented in
                if !isPresented && !profile.supportsInlineInspector {
                    showAiChat = false
                }
            }
        )
    }

    private func closeTransactionDetail() {
        selectedTransaction = nil
        editingTransaction = nil
    }

    private func toggleAiChat() {
        if showAiChat {
            showAiChat = false
        } else {
            openAiChat()
        }
    }

    private func openAiChat() {
        guard store.aiChatEnabled else { return }
        selectedTransaction = nil
        editingTransaction = nil
        showAiChat = true
    }

    private func tabTitle(for tab: AppTab) -> String {
        tab.title(lang: store.language)
    }
}
