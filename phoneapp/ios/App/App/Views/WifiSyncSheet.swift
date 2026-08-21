import SwiftUI
import PhotosUI

public enum SyncTab: String, CaseIterable, Identifiable {
    case scan = "scan"
    case manual = "manual"

    public var id: String { rawValue }
}

@MainActor
public struct WifiSyncSheet: View {
    @ObservedObject public var store: ExpenseStore
    @ObservedObject public var syncService = WifiSyncService.shared
    public var onClose: () -> Void

    @State private var selectedTab: SyncTab = .scan
    @State private var inputIp: String = ""
    @State private var inputPort: String = "18321"
    @State private var inputToken: String = ""
    @State private var isConnecting: Bool = false
    @State private var statusMsg: String?
    @State private var errorMsg: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var laserOffset: CGFloat = -100

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(spacing: 6) {
                        Image(systemName: "wifi")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding(.top, 6)

                        Text(store.t("wifi_sync"))
                            .font(.appFont(size: 20, weight: .bold))

                        Text(store.t("wifi_sync_desc"))
                            .font(.appFont(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    if let paired = syncService.pairedServer {
                        // Paired Device Card
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "laptopcomputer")
                                    .font(.system(size: 28))
                                    .foregroundColor(.green)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(paired.name ?? "MDaily Desktop")
                                        .font(.appFont(size: 16, weight: .semibold))
                                    Text("\(paired.ip):\(paired.port)")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button(store.t("disconnect")) {
                                    syncService.disconnect()
                                }
                                .font(.appFont(size: 13, weight: .medium))
                                .foregroundColor(.red)
                            }
                            .padding(16)
                            .liquidGlass(cornerRadius: 18)

                            // Actions
                            VStack(spacing: 10) {
                                Button {
                                    Task {
                                        await executeMerge(paired)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text(store.t("sync_two_way"))
                                            .font(.appFont(size: 15, weight: .semibold))
                                        Spacer()
                                        if syncService.isSyncing {
                                            ProgressView()
                                        }
                                    }
                                    .padding(16)
                                    .foregroundColor(.white)
                                    .background(Color.blue)
                                    .cornerRadius(16)
                                }
                                .disabled(syncService.isSyncing)
                            }
                        }
                        .padding(.horizontal, 16)
                    } else {
                        // Mode Picker: Scan QR vs Manual
                        Picker("Mode", selection: $selectedTab) {
                            Label(store.t("scan_qr"), systemImage: "qrcode.viewfinder")
                                .tag(SyncTab.scan)
                            Label(store.t("manual_ip_input"), systemImage: "keyboard")
                                .tag(SyncTab.manual)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)

                        if selectedTab == .scan {
                            // Camera QR Scanner Viewport
                            VStack(spacing: 14) {
                                ZStack {
                                    QRCodeScannerView(onCodeScanned: { scannedText in
                                        handleScannedPayload(scannedText)
                                    }, onError: { err in
                                        errorMsg = err
                                    })
                                    .frame(width: 260, height: 260)
                                    .cornerRadius(24)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color.blue.opacity(0.6), lineWidth: 3)
                                    )

                                    // Viewfinder Aim Box & Laser
                                    ZStack {
                                        // Corner brackets
                                        VStack {
                                            HStack {
                                                Image(systemName: "viewfinder")
                                                    .font(.system(size: 220, weight: .ultraLight))
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }

                                        // Scanning laser
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.clear, .blue, .clear],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: 220, height: 3)
                                            .shadow(color: .blue, radius: 4)
                                            .offset(y: laserOffset)
                                            .onAppear {
                                                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                                                    laserOffset = 100
                                                }
                                            }
                                    }
                                }
                                .frame(width: 260, height: 260)
                                .shadow(color: .black.opacity(0.3), radius: 10, y: 4)

                                Text(store.t("scan_qr_desc"))
                                    .font(.appFont(size: 13, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)

                                // Choose from Photos button
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "photo.on.rectangle")
                                            .font(.system(size: 15))
                                        Text(store.t("choose_from_library"))
                                            .font(.appFont(size: 14, weight: .medium))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                                }
                                .onChange(of: selectedPhotoItem) { _, newItem in
                                    Task {
                                        if let item = newItem,
                                           let data = try? await item.loadTransferable(type: Data.self),
                                           let image = UIImage(data: data),
                                           let qrCode = QRCodeImageDetector.detect(from: image) {
                                            handleScannedPayload(qrCode)
                                        } else if newItem != nil {
                                            errorMsg = "Không tìm thấy mã QR trong ảnh đã chọn"
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        } else {
                            // Manual Connect Form
                            VStack(alignment: .leading, spacing: 14) {
                                VStack(spacing: 12) {
                                    TextField(store.t("ip_address") + " (ví dụ: 192.168.1.15)", text: $inputIp)
                                        .keyboardType(.decimalPad)
                                        .padding(12)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .cornerRadius(12)

                                    HStack(spacing: 10) {
                                        TextField(store.t("port"), text: $inputPort)
                                            .keyboardType(.numberPad)
                                            .padding(12)
                                            .background(Color(.secondarySystemGroupedBackground))
                                            .cornerRadius(12)

                                        TextField(store.t("token"), text: $inputToken)
                                            .textInputAutocapitalization(.characters)
                                            .padding(12)
                                            .background(Color(.secondarySystemGroupedBackground))
                                            .cornerRadius(12)
                                    }

                                    Button {
                                        Task {
                                            await connectManual()
                                        }
                                    } label: {
                                        HStack {
                                            if isConnecting {
                                                ProgressView()
                                                    .padding(.trailing, 4)
                                            }
                                            Text(store.t("sync_now"))
                                                .font(.appFont(size: 15, weight: .semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(14)
                                        .foregroundColor(.white)
                                        .background(Color.blue)
                                        .cornerRadius(14)
                                    }
                                    .disabled(isConnecting || inputIp.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                                .padding(16)
                                .liquidGlass(cornerRadius: 20)
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    if let msg = statusMsg {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(msg)
                                .font(.appFont(size: 13, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 16)
                    }

                    if let err = errorMsg {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(err)
                                .font(.appFont(size: 13, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle(store.t("wifi_sync"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(store.t("done")) {
                        onClose()
                    }
                }
            }
        }
    }

    private func handleScannedPayload(_ qrText: String) {
        var ip = ""
        var port = 18321
        var token = ""
        var name = "MDaily Desktop"

        if let data = qrText.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            ip = (json["ip"] as? String) ?? ""
            port = (json["port"] as? Int) ?? 18321
            token = (json["token"] as? String) ?? ""
            name = (json["name"] as? String) ?? "MDaily Desktop"
        } else if qrText.starts(with: "http://") || qrText.starts(with: "mdaily://") {
            let clean = qrText.replacingOccurrences(of: "mdaily://", with: "http://")
            if let url = URL(string: clean), let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                ip = components.host ?? ""
                port = Int(components.queryItems?.first(where: { $0.name == "port" })?.value ?? "18321") ?? 18321
                token = components.queryItems?.first(where: { $0.name == "token" })?.value ?? ""
                name = components.queryItems?.first(where: { $0.name == "name" })?.value ?? "MDaily Desktop"
            }
        }

        guard !ip.isEmpty else {
            errorMsg = "Mã QR không hợp lệ"
            return
        }

        let payload = SyncServerPayload(
            app: "MDaily",
            v: "2.4",
            ip: ip,
            port: port,
            token: token,
            name: name
        )

        syncService.saveServer(payload)
        statusMsg = "Đã nhận diện: \(name)"

        Task {
            await executeMerge(payload)
        }
    }

    private func connectManual() async {
        isConnecting = true
        errorMsg = nil
        statusMsg = nil

        let cleanIp = inputIp.trimmingCharacters(in: .whitespaces)
        let cleanPort = Int(inputPort.trimmingCharacters(in: .whitespaces)) ?? 18321
        let cleanToken = inputToken.trimmingCharacters(in: .whitespaces).uppercased()

        do {
            let name = try await syncService.ping(ip: cleanIp, port: cleanPort)
            let payload = SyncServerPayload(
                app: "MDaily",
                v: "2.4",
                ip: cleanIp,
                port: cleanPort,
                token: cleanToken,
                name: name
            )
            syncService.saveServer(payload)
            statusMsg = "Đã kết nối với \(name)"
            try await syncService.performMerge(store: store, ip: cleanIp, port: cleanPort, token: cleanToken)
        } catch {
            errorMsg = store.t("sync_error")
        }
        isConnecting = false
    }

    private func executeMerge(_ server: SyncServerPayload) async {
        errorMsg = nil
        statusMsg = nil
        do {
            try await syncService.performMerge(store: store, ip: server.ip, port: server.port, token: server.token)
            statusMsg = store.t("sync_success")
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}
