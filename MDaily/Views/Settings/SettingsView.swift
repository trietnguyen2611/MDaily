import SwiftUI

@MainActor
public struct SettingsView: View {
    @ObservedObject public var store: FinanceStore
    @ObservedObject public var syncService: BonjourSyncService
    @ObservedObject public var postureService: DevicePostureService
    public var onOpenChat: () -> Void

    @State private var afmStatus: AFMStatus = AFMService.shared.checkStatus()
    @State private var showSyncSheet: Bool = false
    @State private var showDeleteAllAlert: Bool = false
    @State private var showDeletedNotice: Bool = false

    public init(
        store: FinanceStore,
        syncService: BonjourSyncService,
        postureService: DevicePostureService,
        onOpenChat: @escaping () -> Void
    ) {
        self.store = store
        self.syncService = syncService
        self.postureService = postureService
        self.onOpenChat = onOpenChat
    }

    private var isEnglish: Bool { store.language == .en }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                Text(isEnglish ? "Settings" : "Cài đặt")
                    .font(MDailyTypography.displayMd)
                    .tracking(MDailyTypography.Tracking.displayMd)
                    .foregroundStyle(Color.mdailyInk)

                aiSection
                bonjourSyncSection
                appearanceLanguageCurrencySection
                adaptiveLayoutSection
                dataManagementSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 40)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color.mdailyCanvas.ignoresSafeArea())
        .onAppear {
            afmStatus = AFMService.shared.checkStatus(lang: store.language)
            syncService.attach(store: store)
        }
        .onChange(of: store.language) { _, newLang in
            afmStatus = AFMService.shared.checkStatus(lang: newLang)
        }
        .sheet(isPresented: $showSyncSheet) {
            NavigationStack {
                ScrollView {
                    BonjourSyncView(store: store, syncService: syncService)
                        .padding(20)
                }
                .background(Color.mdailyCanvas.ignoresSafeArea())
                .navigationTitle(isEnglish ? "LAN Sync & Backup" : "Đồng bộ LAN & Sao lưu")
                .platformInlineNavigationTitle()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        MDailyCloseButton(accessibilityLabel: isEnglish ? "Close" : "Đóng") {
                            showSyncSheet = false
                        }
                    }
                }
            }
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
                 ? "This removes all transactions and reminders stored on this device."
                 : "Thao tác này sẽ xoá toàn bộ giao dịch và lịch nhắc định kỳ trên thiết bị này.")
        }
    }

    // MARK: - 1. MDaily AI

    private var aiSection: some View {
        sectionContainer(title: "MDaily AI") {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    sectionIcon("sparkles", color: .mdailyActionBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isEnglish ? "On-Device FoundationModels" : "Mô hình AI trên thiết bị")
                            .font(MDailyTypography.captionStrong)
                            .foregroundStyle(Color.mdailyInk)
                        Text(afmStatus.message)
                            .font(MDailyTypography.finePrint)
                            .foregroundStyle(Color.mdailyMutedInk)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: afmStatus.available ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        Text(afmStatus.available
                             ? (isEnglish ? "Ready" : "Sẵn sàng")
                             : (isEnglish ? "Fallback" : "Cơ bản"))
                            .font(MDailyTypography.finePrint)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(afmStatus.available ? Color.mdailyIncomeGreen : Color.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill((afmStatus.available ? Color.mdailyIncomeGreen : Color.orange).opacity(0.12))
                    )
                }
                .padding(14)

                Divider().overlay(Color.mdailyDividerSoft).padding(.leading, 56)

                HStack(spacing: 12) {
                    sectionIcon("viewfinder", color: .mdailyActionBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isEnglish ? "Auto-Extract Receipts" : "Tự động đọc hoá đơn")
                            .font(MDailyTypography.captionStrong)
                            .foregroundStyle(Color.mdailyInk)
                        Text(isEnglish
                             ? "Use Vision OCR + AI to fill amount & category"
                             : "Dùng Vision OCR + AI điền số tiền & danh mục")
                            .font(MDailyTypography.finePrint)
                            .foregroundStyle(Color.mdailyMutedInk)
                    }
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
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isEnglish ? "AI Financial Assistant" : "Trợ lý AI tài chính")
                            .font(MDailyTypography.captionStrong)
                            .foregroundStyle(Color.mdailyInk)
                        Text(isEnglish
                             ? "Private on-device chat for spending insights"
                             : "Hỏi đáp phân tích thu chi bảo mật trên thiết bị")
                            .font(MDailyTypography.finePrint)
                            .foregroundStyle(Color.mdailyMutedInk)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { store.aiChatEnabled },
                        set: { store.setAiChat($0) }
                    ))
                    .labelsHidden()

                    if store.aiChatEnabled {
                        Button {
                            onOpenChat()
                        } label: {
                            Text(isEnglish ? "Open Chat" : "Mở Chat")
                                .font(MDailyTypography.finePrint)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.mdailyActionBlue))
                        }
                        .buttonStyle(MDailyPressButtonStyle())
                    }
                }
                .padding(14)
            }
        }
    }

    // MARK: - 2. Bonjour LAN Sync & Backup

    private var bonjourSyncSection: some View {
        sectionContainer(title: isEnglish ? "Bonjour LAN Sync & Backup" : "Đồng bộ LAN Bonjour & Sao lưu") {
            VStack(alignment: .leading, spacing: 14) {
                BonjourSyncView(store: store, syncService: syncService)

                Divider().overlay(Color.mdailyDividerSoft)

                Button {
                    showSyncSheet = true
                } label: {
                    HStack {
                        Text(isEnglish ? "Open Dedicated Sync Panel" : "Mở cửa sổ Đồng bộ riêng")
                            .font(MDailyTypography.captionStrong)
                            .foregroundStyle(Color.mdailyActionBlue)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.mdailyActionBlue)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
    }

    // MARK: - 3. Appearance, Language & Currency

    private var appearanceLanguageCurrencySection: some View {
        sectionContainer(title: isEnglish ? "Appearance, Language & Currency" : "Giao diện, Ngôn ngữ & Tiền tệ") {
            VStack(spacing: 0) {
                pickerRow(
                    icon: "circle.lefthalf.filled",
                    title: isEnglish ? "Appearance" : "Chế độ hiển thị",
                    subtitle: isEnglish ? "System, Light, or Dark" : "Hệ thống, Sáng hoặc Tối"
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
                    title: isEnglish ? "Language" : "Ngôn ngữ",
                    subtitle: isEnglish ? "Vietnamese or English" : "Tiếng Việt hoặc English"
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
                    title: isEnglish ? "Currency" : "Đơn vị tiền tệ",
                    subtitle: isEnglish ? "Display format across app" : "Định dạng hiển thị toàn ứng dụng"
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
                    title: isEnglish ? "Default Dashboard View" : "Chế độ xem Tổng quan",
                    subtitle: isEnglish ? "Cards waterfall or compact list" : "Thẻ lưới hoặc danh sách gọn"
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

    // MARK: - 4. Adaptive Layout & Device Preview

    private var adaptiveLayoutSection: some View {
        sectionContainer(title: isEnglish ? "Adaptive Layout & Device Preview" : "Bố cục thích ứng & Xem trước thiết bị") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    sectionIcon("iphone.gen3.radiowaves.left.and.right", color: .mdailyActionBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isEnglish ? "Detected Hardware" : "Phần cứng nhận diện")
                            .font(MDailyTypography.captionStrong)
                            .foregroundStyle(Color.mdailyInk)
                        Text(hardwareBadgeText)
                            .font(MDailyTypography.finePrint)
                            .foregroundStyle(Color.mdailyMutedInk)
                    }
                    Spacer()
                }

                Divider().overlay(Color.mdailyDividerSoft)

                VStack(alignment: .leading, spacing: 8) {
                    Text(isEnglish ? "Layout Profile Override" : "Giả lập bố cục thiết bị")
                        .font(MDailyTypography.finePrint)
                        .foregroundStyle(Color.mdailyMutedInk)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            profileChip(title: isEnglish ? "Auto" : "Tự động", isSelected: postureService.overrideProfile == nil) {
                                postureService.overrideProfile = nil
                            }
                            ForEach(AdaptiveLayoutProfile.allCases) { profile in
                                profileChip(
                                    title: profile.displayName(lang: store.language),
                                    isSelected: postureService.overrideProfile == profile
                                ) {
                                    postureService.overrideProfile = profile
                                }
                            }
                        }
                    }
                }
            }
            .padding(14)
        }
    }

    private var hardwareBadgeText: String {
        let model = postureService.hardwareModelIdentifier
        if postureService.isIPhoneDuoHardware {
            return "\(model) (iPhone Duo)"
        }
        #if os(macOS)
        return "macOS arm64 (\(model))"
        #else
        return model
        #endif
    }

    private func profileChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(MDailyTypography.finePrint)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.white : Color.mdailyInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.mdailyActionBlue : Color.mdailyParchment)
                )
        }
        .buttonStyle(MDailyPressButtonStyle())
    }

    // MARK: - 5. Data Management

    private var dataManagementSection: some View {
        sectionContainer(title: isEnglish ? "Data Management" : "Quản lý dữ liệu") {
            VStack(alignment: .leading, spacing: 10) {
                Button(role: .destructive) {
                    showDeleteAllAlert = true
                } label: {
                    HStack(spacing: 12) {
                        sectionIcon("trash.fill", color: .mdailyDestructiveRed)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isEnglish ? "Clear All Data" : "Xoá toàn bộ dữ liệu")
                                .font(MDailyTypography.captionStrong)
                                .foregroundStyle(Color.mdailyDestructiveRed)
                            Text(isEnglish
                                 ? "Permanently remove all local transactions"
                                 : "Xoá vĩnh viễn toàn bộ giao dịch trên thiết bị")
                                .font(MDailyTypography.finePrint)
                                .foregroundStyle(Color.mdailyMutedInk)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)

                if showDeletedNotice {
                    Text(isEnglish ? "All local data cleared." : "Đã xoá toàn bộ dữ liệu cục bộ.")
                        .font(MDailyTypography.finePrint)
                        .foregroundStyle(Color.mdailyIncomeGreen)
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
                .mdailyCard(cornerRadius: MDailyRadius.lg, background: .mdailyCardSurface)
        }
    }

    private func sectionIcon(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: MDailyRadius.sm, style: .continuous)
                    .fill(color.opacity(0.12))
            )
    }

    private func pickerRow<PickerContent: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder picker: () -> PickerContent
    ) -> some View {
        HStack(spacing: 12) {
            sectionIcon(icon, color: .mdailyActionBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MDailyTypography.captionStrong)
                    .foregroundStyle(Color.mdailyInk)
                Text(subtitle)
                    .font(MDailyTypography.finePrint)
                    .foregroundStyle(Color.mdailyMutedInk)
            }
            Spacer()
            picker()
        }
        .padding(14)
    }
}
