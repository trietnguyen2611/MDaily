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
            ScrollOffsetTracker()

            VStack(spacing: 24) {
                // 1. MDaily AI / Smart Financial AI Section
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.t("apple_intelligence"))
                        .font(.appFont(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        // AI Status
                        HStack {
                            settingsIcon(name: "sparkles", color: .purple)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.t("status"))
                                    .font(.appFont(size: 16, weight: .medium))
                                Text(afmStatus.message)
                                    .font(.appFont(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 6)

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: afmStatus.available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(afmStatus.available ? .green : .orange)
                                Text(afmStatus.available ? store.t("available") : store.t("unavailable"))
                                    .font(.appFont(size: 13, weight: .semibold))
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
                                    .font(.appFont(size: 16, weight: .medium))
                                Text(store.t("auto_extract_desc"))
                                    .font(.appFont(size: 12, weight: .regular))
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
                                    .font(.appFont(size: 16, weight: .medium))
                                Text(store.t("ai_chat_desc"))
                                    .font(.appFont(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 6)

                            Spacer()

                            Button {
                                showAiChatSheet = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(store.t("chat_button"))
                                        .font(.appFont(size: 13, weight: .semibold))
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

                // 2. Language, Appearance & Currency Options
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.t("ui_options"))
                        .font(.appFont(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        // Language Picker
                        HStack {
                            settingsIcon(name: "globe", color: .blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.t("language"))
                                    .font(.appFont(size: 16, weight: .medium))
                                Text(store.t("language_desc"))
                                    .font(.appFont(size: 12, weight: .regular))
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
                            .font(.appFont(size: 15, weight: .medium))
                            .pickerStyle(.menu)
                        }
                        .padding(16)

                        Divider().padding(.leading, 56)

                        // Appearance Mode Picker
                        HStack {
                            settingsIcon(name: "circle.lefthalf.filled", color: .indigo)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.t("appearance"))
                                    .font(.appFont(size: 16, weight: .medium))
                                Text(store.t("appearance_desc"))
                                    .font(.appFont(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 6)

                            Spacer()

                            Picker("", selection: Binding(
                                get: { store.appearanceMode },
                                set: { store.setAppearanceMode($0) }
                            )) {
                                Text(store.t("appearance_system")).tag(AppearanceMode.system)
                                Text(store.t("appearance_light")).tag(AppearanceMode.light)
                                Text(store.t("appearance_dark")).tag(AppearanceMode.dark)
                            }
                            .font(.appFont(size: 15, weight: .medium))
                            .pickerStyle(.menu)
                        }
                        .padding(16)

                        Divider().padding(.leading, 56)

                        // Currency Picker
                        HStack {
                            settingsIcon(name: "banknote.fill", color: .green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.t("currency"))
                                    .font(.appFont(size: 16, weight: .medium))
                                Text(store.t("currency_desc"))
                                    .font(.appFont(size: 12, weight: .regular))
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
                            .font(.appFont(size: 15, weight: .medium))
                            .pickerStyle(.menu)
                        }
                        .padding(16)

                        Divider().padding(.leading, 56)

                        // Camera Layout Mode Picker
                        HStack {
                            settingsIcon(name: "camera.viewfinder", color: .orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.language == .en ? "Camera Interface" : "Giao diện Camera")
                                    .font(.appFont(size: 16, weight: .medium))
                                Text(store.language == .en ? "Choose style for quick capture" : "Chọn giao diện chụp")
                                    .font(.appFont(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 6)

                            Spacer()

                            let isDiAvailable = UIDevice.current.hasDynamicIsland
                            let dynamicIslandLabel: String = {
                                let base = CameraLayoutMode.dynamicIsland.title(lang: store.language)
                                if isDiAvailable {
                                    return base
                                } else {
                                    let status = store.language == .en ? "Unsupported" : "Không hỗ trợ"
                                    return "\(base) (\(status))"
                                }
                            }()

                            Picker("", selection: Binding(
                                get: { store.cameraLayoutMode },
                                set: { store.setCameraLayoutMode($0) }
                            )) {
                                Text(CameraLayoutMode.default.title(lang: store.language))
                                    .tag(CameraLayoutMode.default)
                                
                                Text(dynamicIslandLabel)
                                    .tag(CameraLayoutMode.dynamicIsland)
                                    .disabled(!isDiAvailable)
                            }
                            .font(.appFont(size: 15, weight: .medium))
                            .pickerStyle(.menu)
                            .disabled(!isDiAvailable)
                        }
                        .padding(16)
                    }
                    .liquidGlass(cornerRadius: 24)
                }

                // 3. Data Management
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.t("data_management"))
                        .font(.appFont(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        Button {
                            showDeleteAllAlert = true
                        } label: {
                            HStack {
                                settingsIcon(name: "trash.fill", color: .red)

                                Text(store.t("delete_all_data"))
                                    .font(.appFont(size: 16, weight: .semibold))
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
                    Text(store.t("app_title"))
                        .font(.appFont(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    Text("v2.4")
                        .font(.appFont(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(16)
            .padding(.top, 12)
            .padding(.bottom, 110)
        }
        .coordinateSpace(name: "mdaily_scroll")
        .mask {
            VStack(spacing: 0) {
                // Top Scroll Soft Fade Mask
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 14)

                Rectangle()
                    .fill(Color.black)

                // Bottom Scroll Soft Fade Mask
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0.0),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 36)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .hideKeyboardOnTap()
        .alert(store.t("delete_confirm_all"), isPresented: $showDeleteAllAlert) {
            Button(store.t("delete_all_data"), role: .destructive) {
                store.clearAllData()
                showDeletedNotice = true
            }
            Button(store.t("cancel"), role: .cancel) {}
        } message: {
            Text(store.t("delete_all_confirm_message"))
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
