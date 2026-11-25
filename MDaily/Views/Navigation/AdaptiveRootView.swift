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
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

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
            }
            .background(Color.mdailyCanvas.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                PhoneBottomGlassDock(
                    activeTab: $activeTab,
                    language: store.language,
                    onQuickCapture: { showQuickCapture = true }
                )
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
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                        Text("MDaily AI")
                            .font(MDailyTypography.captionStrong)
                    }
                    .foregroundStyle(Color.mdailyActionBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .mdailyGlassPill(interactive: true)
                }
                .buttonStyle(MDailyPressButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.mdailyCanvas)
    }

    // MARK: - Pad & Mac Split View

    private func splitNavigationShell(for profile: AdaptiveLayoutProfile) -> some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
                #if os(macOS)
                .navigationSplitViewColumnWidth(min: 210, ideal: 235, max: 280)
                #endif
        } detail: {
            tabContent(for: profile)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.mdailyCanvas)
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
                            .tint(showAiChat ? Color.mdailyActionBlue : nil)
                        }
                    }
                }
                .inspector(isPresented: inlineInspectorBinding) {
                    inspectorContent
                        .inspectorColumnWidth(min: 320, ideal: 360, max: 440)
                }
        }
    }

    private var sidebarContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Brand header
            HStack(spacing: 10) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text("MDaily")
                        .font(MDailyTypography.bodyStrong)
                        .foregroundStyle(Color.mdailyInk)
                    Text(store.language == .en ? "Personal Finance" : "Quản lý Thu Chi")
                        .font(MDailyTypography.finePrint)
                        .foregroundStyle(Color.mdailyMutedInk)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 16)

            // Main Tabs
            VStack(spacing: 4) {
                ForEach(AppTab.allCases) { tab in
                    sidebarTabButton(tab)
                }
            }
            .padding(.horizontal, 10)

            Rectangle()
                .fill(Color.mdailyHairline)
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

            // Quick Actions
            VStack(spacing: 6) {
                Button {
                    showQuickCapture = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .frame(width: 20)
                        Text(store.language == .en ? "Quick Capture" : "Chụp hóa đơn")
                        Spacer()
                    }
                    .font(MDailyTypography.captionStrong)
                    .foregroundStyle(Color.mdailyActionBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.mdailyActionBlue.opacity(0.08))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(MDailyPressButtonStyle())

                if store.aiChatEnabled {
                    Button(action: toggleAiChat) {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .frame(width: 20)
                            Text("MDaily AI")
                            Spacer()
                        }
                        .font(MDailyTypography.captionStrong)
                        .foregroundStyle(showAiChat ? Color.white : Color.mdailyActionBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(showAiChat ? Color.mdailyActionBlue : Color.mdailyActionBlue.opacity(0.08))
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(MDailyPressButtonStyle())
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            // LAN Sync Status Badge
            Button {
                activeTab = .settings
            } label: {
                lanSyncStatusBadge
            }
            .buttonStyle(MDailyPressButtonStyle())
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
        .background(Color.mdailyParchment)
    }

    private func sidebarTabButton(_ tab: AppTab) -> some View {
        let isSelected = activeTab == tab
        return Button {
            activeTab = tab
        } label: {
            HStack(spacing: 10) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .frame(width: 20)
                Text(tabTitle(for: tab))
                    .font(isSelected ? MDailyTypography.bodyStrong : MDailyTypography.body)
                    .tracking(MDailyTypography.Tracking.body)
                Spacer()
            }
            .foregroundStyle(isSelected ? Color.mdailyActionBlue : Color.mdailyInk)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.mdailyActionBlue.opacity(0.12))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(MDailyPressButtonStyle())
    }

    private var lanSyncStatusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(syncIndicatorColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(store.language == .en ? "LAN Sync" : "Đồng bộ LAN")
                    .font(MDailyTypography.captionStrong)
                    .foregroundStyle(Color.mdailyInk)

                Text(lanSyncSubtitle)
                    .font(MDailyTypography.finePrint)
                    .foregroundStyle(Color.mdailyMutedInk)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.mdailyMutedInk)
        }
        .padding(10)
        .mdailyCard(cornerRadius: 12, background: .mdailyCardSurface)
    }

    private var syncIndicatorColor: Color {
        if syncService.isSyncing {
            return .mdailyActionBlue
        } else if !syncService.peers.isEmpty {
            return .mdailyIncomeGreen
        } else {
            return .mdailyMutedInk.opacity(0.6)
        }
    }

    private var lanSyncSubtitle: String {
        if syncService.isSyncing {
            return store.language == .en ? "Syncing..." : "Đang đồng bộ..."
        }
        let count = syncService.peers.count
        if count == 0 {
            return store.language == .en ? "Listening on LAN" : "Đang chờ thiết bị"
        } else if count == 1 {
            return store.language == .en ? "1 device nearby" : "1 thiết bị gần đây"
        } else {
            return store.language == .en ? "\(count) devices nearby" : "\(count) thiết bị gần đây"
        }
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
                postureService: posture,
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
