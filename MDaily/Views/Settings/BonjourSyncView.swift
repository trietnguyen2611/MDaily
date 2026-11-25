import SwiftUI
import UniformTypeIdentifiers

public struct MDailyJSONBackupDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.json] }
    public var data: Data

    public init(data: Data = Data()) {
        self.data = data
    }

    public init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = fileData
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

@MainActor
public struct BonjourSyncView: View {
    @ObservedObject public var store: FinanceStore
    @ObservedObject public var syncService: BonjourSyncService

    @State private var showExporter: Bool = false
    @State private var showImporter: Bool = false
    @State private var exportDocument: MDailyJSONBackupDocument = MDailyJSONBackupDocument()
    @State private var backupMessage: String? = nil
    @State private var backupIsError: Bool = false
    @State private var radarPulse: Bool = false

    public init(store: FinanceStore, syncService: BonjourSyncService) {
        self.store = store
        self.syncService = syncService
    }

    private var isEnglish: Bool { store.language == .en }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            radarHeaderCard
            peersSection
            jsonBackupSection
        }
        .onAppear {
            syncService.attach(store: store)
            if !syncService.isRunning {
                syncService.start(store: store)
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                radarPulse = true
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: defaultBackupFilename()
        ) { result in
            switch result {
            case .success:
                backupIsError = false
                backupMessage = isEnglish ? "JSON backup exported successfully." : "Đã xuất file sao lưu JSON thành công."
            case .failure(let error):
                backupIsError = true
                backupMessage = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
    }

    // MARK: - Live Radar Header

    private var radarHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(
                        (syncService.isRunning ? Color.mdailyActionBlue : Color.mdailyMutedInk).opacity(0.22),
                        lineWidth: 1.5
                    )
                    .frame(width: 44, height: 44)
                    .scaleEffect(syncService.isRunning && radarPulse ? 1.15 : 0.92)

                Circle()
                    .fill((syncService.isRunning ? Color.mdailyActionBlue : Color.mdailyMutedInk).opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: syncService.isSyncing ? "arrow.triangle.2.circlepath" : "bonjour")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(syncService.isRunning ? Color.mdailyActionBlue : Color.mdailyMutedInk)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(syncService.deviceDisplayName)
                        .font(MDailyTypography.captionStrong)
                        .foregroundStyle(Color.mdailyInk)
                        .lineLimit(1)

                    Text(syncService.isRunning
                         ? (isEnglish ? "Active" : "Đang bật")
                         : (isEnglish ? "Paused" : "Tạm dừng"))
                        .font(MDailyTypography.microLegal)
                        .foregroundStyle(syncService.isRunning ? Color.mdailyIncomeGreen : Color.mdailyMutedInk)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill((syncService.isRunning ? Color.mdailyIncomeGreen : Color.mdailyMutedInk).opacity(0.12))
                        )
                }

                if let status = syncService.statusMessage {
                    Text(status)
                        .font(MDailyTypography.finePrint)
                        .foregroundStyle(Color.mdailyMutedInk)
                        .lineLimit(2)
                } else if let last = syncService.lastSyncedAt {
                    Text("\(isEnglish ? "Last synced" : "Đồng bộ gần nhất"): \(last.formatted(date: .omitted, time: .shortened))")
                        .font(MDailyTypography.finePrint)
                        .foregroundStyle(Color.mdailyMutedInk)
                } else {
                    Text(isEnglish
                         ? "Broadcasting & scanning on local Wi-Fi (_mdaily-sync._tcp)"
                         : "Đang phát & quét thiết bị MDaily trên Wi-Fi/LAN")
                        .font(MDailyTypography.finePrint)
                        .foregroundStyle(Color.mdailyMutedInk)
                }
            }

            Spacer()

            Button {
                syncService.refreshPeers()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.mdailyActionBlue)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.mdailyActionBlue.opacity(0.10)))
            }
            .buttonStyle(MDailyPressButtonStyle())
            .accessibilityLabel(isEnglish ? "Refresh LAN peers" : "Quét lại thiết bị")
        }
        .padding(14)
        .mdailyCard(cornerRadius: MDailyRadius.lg, background: .mdailyCardSurface)
    }

    // MARK: - Discovered Peers

    private var peersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(isEnglish ? "Nearby Devices" : "Thiết bị gần đây (LAN)")
                    .font(MDailyTypography.captionStrong)
                    .foregroundStyle(Color.mdailyMutedInk)
                Spacer()
                Text("\(syncService.peers.count)")
                    .font(MDailyTypography.finePrint)
                    .foregroundStyle(Color.mdailyMutedInk)
            }

            if syncService.peers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "wifi")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(Color.mdailyMutedInk.opacity(0.7))
                    Text(isEnglish
                         ? "No nearby MDaily devices detected yet. Open MDaily on another Mac, iPhone, or iPad on the same Wi-Fi."
                         : "Chưa thấy thiết bị MDaily nào khác. Hãy mở MDaily trên Mac, iPhone hoặc iPad cùng mạng Wi-Fi.")
                        .font(MDailyTypography.finePrint)
                        .foregroundStyle(Color.mdailyMutedInk)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .padding(.horizontal, 12)
                .mdailyCard(cornerRadius: MDailyRadius.lg, background: .mdailyParchment)
            } else {
                VStack(spacing: 8) {
                    ForEach(syncService.peers) { peer in
                        peerRow(peer)
                    }
                }
            }
        }
    }

    private func peerRow(_ peer: DiscoveredPeer) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName(for: peer.name))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.mdailyActionBlue)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.mdailyActionBlue.opacity(0.10)))

            VStack(alignment: .leading, spacing: 2) {
                Text(peer.name)
                    .font(MDailyTypography.captionStrong)
                    .foregroundStyle(Color.mdailyInk)
                    .lineLimit(1)
                Text("\(isEnglish ? "Seen" : "Thấy lúc") \(peer.lastSeen.formatted(date: .omitted, time: .shortened))")
                    .font(MDailyTypography.microLegal)
                    .foregroundStyle(Color.mdailyMutedInk)
            }

            Spacer()

            Button {
                Task {
                    await syncService.sync(with: peer, store: store)
                }
            } label: {
                HStack(spacing: 5) {
                    if syncService.isSyncing {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Text(isEnglish ? "Sync Now" : "Đồng bộ ngay")
                        .font(MDailyTypography.finePrint)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(syncService.isSyncing ? Color.mdailyMutedInk : Color.mdailyActionBlue)
                )
            }
            .buttonStyle(MDailyPressButtonStyle())
            .disabled(syncService.isSyncing)
        }
        .padding(12)
        .mdailyCard(cornerRadius: MDailyRadius.lg, background: .mdailyCardSurface)
    }

    // MARK: - JSON Backup Export / Import

    private var jsonBackupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isEnglish ? "JSON Backup (iCloud Drive / Files)" : "Sao lưu JSON (iCloud Drive / Tệp)")
                .font(MDailyTypography.captionStrong)
                .foregroundStyle(Color.mdailyMutedInk)

            HStack(spacing: 10) {
                Button {
                    do {
                        let data = try store.exportJSONData()
                        exportDocument = MDailyJSONBackupDocument(data: data)
                        showExporter = true
                    } catch {
                        backupIsError = true
                        backupMessage = error.localizedDescription
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .semibold))
                        Text(isEnglish ? "Export JSON" : "Xuất JSON")
                            .font(MDailyTypography.captionStrong)
                    }
                    .foregroundStyle(Color.mdailyActionBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .mdailyCard(cornerRadius: MDailyRadius.md, background: .mdailyCardSurface)
                }
                .buttonStyle(MDailyPressButtonStyle())

                Button {
                    showImporter = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 13, weight: .semibold))
                        Text(isEnglish ? "Import JSON" : "Nhập JSON")
                            .font(MDailyTypography.captionStrong)
                    }
                    .foregroundStyle(Color.mdailyInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .mdailyCard(cornerRadius: MDailyRadius.md, background: .mdailyCardSurface)
                }
                .buttonStyle(MDailyPressButtonStyle())
            }

            if let backupMessage {
                Text(backupMessage)
                    .font(MDailyTypography.finePrint)
                    .foregroundStyle(backupIsError ? Color.mdailyDestructiveRed : Color.mdailyIncomeGreen)
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Helpers

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                let stats = try store.importJSONData(data)
                backupIsError = false
                backupMessage = isEnglish
                    ? "Imported backup: +\(stats.added) added, \(stats.updated) updated."
                    : "Đã nhập sao lưu: +\(stats.added) mới, \(stats.updated) cập nhật."
            } catch {
                backupIsError = true
                backupMessage = error.localizedDescription
            }
        case .failure(let error):
            backupIsError = true
            backupMessage = error.localizedDescription
        }
    }

    private func iconName(for peerName: String) -> String {
        let lower = peerName.lowercased()
        if lower.contains("mac") || lower.contains("book") || lower.contains("imac") {
            return "laptopcomputer"
        } else if lower.contains("ipad") {
            return "ipad"
        } else if lower.contains("iphone") {
            return "iphone"
        }
        return "desktopcomputer"
    }

    private func defaultBackupFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "MDaily-Backup-\(formatter.string(from: Date()))"
    }
}
