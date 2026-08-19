import SwiftUI

public struct SettingsView: View {
    @ObservedObject public var store: ExpenseStore

    @State private var afmStatus: AFMStatus = AFMService.shared.checkStatus()
    @State private var showDeleteAllAlert: Bool = false
    @State private var showDeletedNotice: Bool = false

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 1. Apple Intelligence Section
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.t("apple_intelligence"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        // AFM Status
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.t("status"))
                                        .font(.system(size: 16))
                                    Text(afmStatus.message)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                            }

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

                        Divider().padding(.leading, 44)

                        // Auto Extract Toggle
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.t("auto_extract"))
                                        .font(.system(size: 16))
                                    Text(store.t("auto_extract_desc"))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "viewfinder")
                                    .foregroundColor(.blue)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { store.autoExtractEnabled },
                                set: { store.setAutoExtract($0) }
                            ))
                            .labelsHidden()
                        }
                        .padding(16)

                        Divider().padding(.leading, 44)

                        // AI Chat Toggle
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.t("ai_chat"))
                                        .font(.system(size: 16))
                                    Text(store.t("ai_chat_desc"))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "message.badge.filled.fill")
                                    .foregroundColor(.cyan)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { store.aiChatEnabled },
                                set: { store.setAiChat($0) }
                            ))
                            .labelsHidden()
                        }
                        .padding(16)
                    }
                    .liquidGlass(cornerRadius: 24)
                }

                // 2. Appearance & Options
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.t("ui_options"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        // Language Picker
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.t("language"))
                                        .font(.system(size: 16))
                                    Text(store.t("language_desc"))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                            }

                            Spacer()

                            Picker("", selection: Binding(
                                get: { store.language },
                                set: { store.setLanguage($0) }
                            )) {
                                ForEach(Language.allCases) { lang in
                                    Text(lang.title).tag(lang)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(16)

                        Divider().padding(.leading, 44)

                        // Currency Picker
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.t("currency"))
                                        .font(.system(size: 16))
                                    Text(store.t("currency_desc"))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "banknote")
                                    .foregroundColor(.green)
                            }

                            Spacer()

                            Picker("", selection: Binding(
                                get: { store.currency },
                                set: { store.setCurrency($0) }
                            )) {
                                ForEach(Currency.allCases) { curr in
                                    Text(curr.title).tag(curr)
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
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.t("delete_all_data"))
                                        .font(.system(size: 16))
                                    Text(store.t("delete_all_desc"))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }

                            Spacer()

                            Button(store.t("delete_data_btn")) {
                                showDeleteAllAlert = true
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .clipShape(Capsule())
                        }
                        .padding(16)
                    }
                    .liquidGlass(cornerRadius: 24)
                }

                // 4. App Info
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.t("app_info"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("MDaily Mobile")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(store.t("app_version"))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                            }

                            Spacer()

                            Text("SwiftUI")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.blue.opacity(0.12)))
                        }
                        .padding(16)
                    }
                    .liquidGlass(cornerRadius: 24)
                }
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .alert(store.t("delete_confirm_all"), isPresented: $showDeleteAllAlert) {
            Button(store.t("delete"), role: .destructive) {
                store.clearAllData()
                showDeletedNotice = true
            }
            Button(store.t("cancel"), role: .cancel) {}
        }
        .alert("Đã xoá toàn bộ dữ liệu.", isPresented: $showDeletedNotice) {
            Button("OK", role: .cancel) {}
        }
    }
}
