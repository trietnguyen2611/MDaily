import SwiftUI

@MainActor
public struct SettingsView: View {
    @ObservedObject public var store: FinanceStore
    @ObservedObject public var syncService: BonjourSyncService
    public var onOpenChat: () -> Void

    @State private var afmStatus: AFMStatus = AFMService.shared.checkStatus()
    @State private var showDeleteAllAlert: Bool = false
    @State private var showDeletedNotice: Bool = false

    public init(
        store: FinanceStore,
        syncService: BonjourSyncService,
        onOpenChat: @escaping () -> Void
    ) {
        self.store = store
        self.syncService = syncService
        self.onOpenChat = onOpenChat
    }

    private var isEnglish: Bool { store.language == .en }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text(isEnglish ? "Settings" : "Cài đặt")
                    .font(MDailyTypography.displayMd)
                    .tracking(MDailyTypography.Tracking.displayMd)
                    .foregroundStyle(Color.mdailyInk)

                aiSection
                bonjourSyncSection
                preferencesSection
                dataManagementSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 40)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .mdailySoftScrollEdges()
        .background(Color.mdailyCanvas.ignoresSafeArea())
        .onAppear {
            afmStatus = AFMService.shared.checkStatus(lang: store.language)
            syncService.attach(store: store)
        }
        .onChange(of: store.language) { _, newLang in
            afmStatus = AFMService.shared.checkStatus(lang: newLang)
        }
        .alert(
            isEnglish ? "Clear all data?" : "Xoá toàn bộ dữ liệu?",
            isPresented: $showDeleteAllAlert
        ) {
            Button(isEnglish ? "Delete All" : "Xoá tất cả", role: .destructive) {
                store.clearAllData()
                showDeletedNotice = true
            }
            Button(isEnglish ? "Cancel" : "Huỷ", role: .cancel) {}
        } message: {
            Text(isEnglish
                 ? "This removes all transactions on this device."
                 : "Xoá toàn bộ giao dịch trên thiết bị này.")
        }
    }

    // MARK: - 1. MDaily AI

    private var aiSection: some View {
        sectionContainer(title: "MDaily AI") {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    sectionIcon("sparkles", color: .mdailyActionBlue)
                    Text("FoundationModels")
                        .font(MDailyTypography.captionStrong)
                        .foregroundStyle(Color.mdailyInk)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: afmStatus.available ? "checkmark.circle.fill" : "circle.dashed")
                        Text(afmStatus.available
                             ? (isEnglish ? "Ready" : "Sẵn sàng")
                             : (isEnglish ? "Fallback" : "Cục bộ"))
                            .font(MDailyTypography.finePrint)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(afmStatus.available ? Color.mdailyIncomeGreen : Color.mdailyMutedInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .mdailyGlassPill(interactive: false)
                }
                .padding(14)

                Divider().overlay(Color.mdailyDividerSoft).padding(.leading, 56)

                HStack(spacing: 12) {
                    sectionIcon("viewfinder", color: .mdailyActionBlue)
                    Text(isEnglish ? "Auto-Extract Receipts" : "Tự động đọc hoá đơn")
                        .font(MDailyTypography.captionStrong)
                        .foregroundStyle(Color.mdailyInk)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { store.autoExtractEnabled },
                        set: { store.setAutoExtract($0) }
                    ))
                    .labelsHidden()
                }
                .padding(14)

                Divider().overlay(Color.mdailyDividerSoft).padding(.leading, 56)

                HStack(spacing: 12) {
                    sectionIcon("bubble.left.and.bubble.right.fill", color: .mdailyActionBlue)
                    Text(isEnglish ? "AI Assistant" : "Trợ lý AI")
                        .font(MDailyTypography.captionStrong)
                        .foregroundStyle(Color.mdailyInk)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { store.aiChatEnabled },
                        set: { store.setAiChat($0) }
                    ))
                    .labelsHidden()

                    if store.aiChatEnabled {
                        Button(isEnglish ? "Chat" : "Mở Chat") {
                            onOpenChat()
                        }
                        .font(MDailyTypography.finePrint)
                        .fontWeight(.semibold)
                        .mdailyGlassButton(prominent: true)
                    }
                }
                .padding(14)
            }
        }
    }

    // MARK: - 2. Bonjour LAN Sync

    private var bonjourSyncSection: some View {
        sectionContainer(title: isEnglish ? "Bonjour LAN Sync" : "Đồng bộ LAN Bonjour") {
            BonjourSyncView(store: store, syncService: syncService)
                .padding(12)
        }
    }

    // MARK: - 3. Appearance, Language & Currency

    private var preferencesSection: some View {
        sectionContainer(title: isEnglish ? "Preferences" : "Tuỳ chọn") {
            VStack(spacing: 0) {
                pickerRow(
                    icon: "circle.lefthalf.filled",
                    title: isEnglish ? "Appearance" : "Giao diện"
                ) {
                    Picker("", selection: Binding(
                        get: { store.appearanceMode },
                        set: { store.setAppearanceMode($0) }
                    )) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.title(lang: store.language)).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Divider().overlay(Color.mdailyDividerSoft).padding(.leading, 56)

                pickerRow(
                    icon: "globe",
                    title: isEnglish ? "Language" : "Ngôn ngữ"
                ) {
                    Picker("", selection: Binding(
                        get: { store.language },
                        set: { store.setLanguage($0) }
                    )) {
                        Text(Language.vi.displayName).tag(Language.vi)
                        Text(Language.en.displayName).tag(Language.en)
                    }
                    .pickerStyle(.menu)
                }

                Divider().overlay(Color.mdailyDividerSoft).padding(.leading, 56)

                pickerRow(
                    icon: "banknote",
                    title: isEnglish ? "Currency" : "Tiền tệ"
                ) {
                    Picker("", selection: Binding(
                        get: { store.currency },
                        set: { store.setCurrency($0) }
                    )) {
                        ForEach(Currency.allCases, id: \.self) { curr in
                            Text(curr.displayName).tag(curr)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Divider().overlay(Color.mdailyDividerSoft).padding(.leading, 56)

                pickerRow(
                    icon: "rectangle.grid.2x2",
                    title: isEnglish ? "Dashboard View" : "Kiểu hiển thị"
                ) {
                    Picker("", selection: Binding(
                        get: { store.dashboardViewMode },
                        set: { store.setDashboardViewMode($0) }
                    )) {
                        Text(isEnglish ? "Cards" : "Thẻ").tag(DashboardViewMode.waterfall)
                        Text(isEnglish ? "List" : "Danh sách").tag(DashboardViewMode.list)
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    // MARK: - 4. Data Management

    private var dataManagementSection: some View {
        sectionContainer(title: isEnglish ? "Data" : "Dữ liệu") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    sectionIcon("trash.fill", color: .mdailyDestructiveRed)
                    Text(isEnglish ? "Clear All Data" : "Xoá toàn bộ dữ liệu")
                        .font(MDailyTypography.captionStrong)
                        .foregroundStyle(Color.mdailyDestructiveRed)
                    Spacer()
                    Button(isEnglish ? "Clear" : "Xoá", role: .destructive) {
                        showDeleteAllAlert = true
                    }
                    .font(MDailyTypography.finePrint)
                    .fontWeight(.semibold)
                    .mdailyGlassButton(prominent: false)
                }

                if showDeletedNotice {
                    Text(isEnglish ? "Cleared" : "Đã xoá")
                        .font(MDailyTypography.finePrint)
                        .foregroundStyle(Color.mdailyIncomeGreen)
                        .padding(.leading, 44)
                }
            }
            .padding(14)
        }
    }

    // MARK: - Helpers

    private func sectionContainer<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(MDailyTypography.captionStrong)
                .foregroundStyle(Color.mdailyMutedInk)
                .padding(.horizontal, 4)

            content()
                .mdailyCard(cornerRadius: MDailyRadius.lg)
        }
    }

    private func sectionIcon(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 32, height: 32)
            .mdailyGlassSurface(
                in: RoundedRectangle(cornerRadius: MDailyRadius.sm, style: .continuous),
                interactive: false
            )
    }

    private func pickerRow<PickerContent: View>(
        icon: String,
        title: String,
        @ViewBuilder picker: () -> PickerContent
    ) -> some View {
        HStack(spacing: 12) {
            sectionIcon(icon, color: .mdailyActionBlue)
            Text(title)
                .font(MDailyTypography.captionStrong)
                .foregroundStyle(Color.mdailyInk)
            Spacer()
            picker()
        }
        .padding(14)
    }
}
