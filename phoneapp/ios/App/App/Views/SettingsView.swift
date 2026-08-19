import SwiftUI

@MainActor
public struct SettingsView: View {
    @ObservedObject public var store: ExpenseStore

    @State private var afmStatus: AFMStatus = AFMService.shared.checkStatus()
    @State private var showDeleteAllAlert: Bool = false
    @State private var showDeletedNotice: Bool = false
    @State private var showAiChatSheet: Bool = false

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 1. Apple Intelligence / Smart Financial AI Section
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.t("apple_intelligence"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        // AI Status
                        HStack {
                            settingsIcon(name: "sparkles", color: .purple)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.t("status"))
                                    .font(.system(size: 16, weight: .medium))
                                Text(afmStatus.message)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 6)

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: afmStatus.available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(afmStatus.available ? .green : .orange)
                                Text(afmStatus.available ? store.t("available") : store.t("unavailable"))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(afmStatus.available ? .green : .orange)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(
                                    afmStatus.available ? Color.green.opacity(0.12) : Color.orange.opacity(0.12)
                                )
                            )
                        }
                        .padding(16)

                        Divider().padding(.leading, 56)

                        // Auto Extract Toggle
                        HStack {
                            settingsIcon(name: "viewfinder", color: .blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.t("auto_extract"))
                                    .font(.system(size: 16, weight: .medium))
                                Text(store.t("auto_extract_desc"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 6)

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { store.autoExtractEnabled },
                                set: { store.setAutoExtract($0) }
                            ))
                            .labelsHidden()
                        }
                        .padding(16)

                        Divider().padding(.leading, 56)

                        // AI Chat Toggle & Open Button
                        HStack {
                            settingsIcon(name: "bubble.left.and.bubble.right.fill", color: .cyan)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.t("ai_chat"))
                                    .font(.system(size: 16, weight: .medium))
                                Text(store.t("ai_chat_desc"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 6)

                            Spacer()

                            Button {
                                showAiChatSheet = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Trò chuyện")
                                        .font(.system(size: 13, weight: .semibold))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .liquidGlassPill()
                            }
                        }
                        .padding(16)
                    }
                    .liquidGlass(cornerRadius: 24)
                }

                // 2. Language & Currency Options
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.t("ui_options"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        // Language Picker
                        HStack {
                            settingsIcon(name: "globe", color: .blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.t("language"))
                                    .font(.system(size: 16, weight: .medium))
                                Text(store.t("language_desc"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 6)

                            Spacer()

                            Picker("", selection: Binding(
                                get: { store.language },
                                set: { store.setLanguage($0) }
                            )) {
                                Text(Language.vi.displayName).tag(Language.vi)
                                Text(Language.en.displayName).tag(Language.en)
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(16)

                        Divider().padding(.leading, 56)

                        // Currency Picker
                        HStack {
                            settingsIcon(name: "banknote.fill", color: .green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.t("currency"))
                                    .font(.system(size: 16, weight: .medium))
                                Text(store.t("currency_desc"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 6)

                            Spacer()

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
                        .padding(16)
                    }
                    .liquidGlass(cornerRadius: 24)
                }

                // 3. Data Management
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.t("data_management"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        Button {
                            showDeleteAllAlert = true
                        } label: {
                            HStack {
                                settingsIcon(name: "trash.fill", color: .red)

                                Text(store.t("delete_all_data"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red)
                                    .padding(.leading, 6)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                        }
                        .buttonStyle(.plain)
                    }
                    .liquidGlass(cornerRadius: 24)
                }

                // 4. App Info Card
                VStack(spacing: 6) {
                    Text("MDaily — Quản Lý Chi Tiêu Liquid Glass")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Phiên bản 2.0 • Pure Native SwiftUI (iOS 26 / 27)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .confirmationDialog(
            store.t("delete_all_confirm"),
            isPresented: $showDeleteAllAlert,
            titleVisibility: .visible
        ) {
            Button(store.t("delete_all_data"), role: .destructive) {
                store.clearAllData()
                showDeletedNotice = true
            }
            Button(store.t("cancel"), role: .cancel) {}
        }
        .alert(store.t("data_cleared"), isPresented: $showDeletedNotice) {
            Button(store.t("done"), role: .cancel) {}
        }
        .sheet(isPresented: $showAiChatSheet) {
            ChatbotSheet(
                store: store,
                onClose: { showAiChatSheet = false }
            )
        }
    }

    // MARK: - Icon Tile Helper
    @ViewBuilder
    private func settingsIcon(name: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .shadow(color: color.opacity(0.35), radius: 4, x: 0, y: 2)

            Image(systemName: name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
