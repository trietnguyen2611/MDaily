import SwiftUI

@MainActor
public struct BonjourSyncView: View {
    @ObservedObject public var store: FinanceStore
    @ObservedObject public var syncService: BonjourSyncService

    @State private var radarPulse: Bool = false

    public init(store: FinanceStore, syncService: BonjourSyncService) {
        self.store = store
        self.syncService = syncService
    }

    private var isEnglish: Bool { store.language == .en }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            radarHeaderRow
            peersList
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
    }

    // MARK: - Compact LAN Status Row

    private var radarHeaderRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(
                        (syncService.isRunning ? Color.mdailyActionBlue : Color.mdailyMutedInk).opacity(0.24),
                        lineWidth: 1.5
                    )
                    .frame(width: 40, height: 40)
                    .scaleEffect(syncService.isRunning && radarPulse ? 1.14 : 0.92)

                Image(systemName: syncService.isSyncing ? "arrow.triangle.2.circlepath" : "bonjour")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(syncService.isRunning ? Color.mdailyActionBlue : Color.mdailyMutedInk)
                    .frame(width: 32, height: 32)
                    .mdailyGlassSurface(in: Circle(), interactive: false)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(syncService.deviceDisplayName)
                        .font(MDailyTypography.captionStrong)
                        .foregroundStyle(Color.mdailyInk)
                        .lineLimit(1)

                    Circle()
                        .fill(syncService.isRunning ? Color.mdailyIncomeGreen : Color.mdailyMutedInk)
                        .frame(width: 7, height: 7)
                }

                Text(compactStatusText)
                    .font(MDailyTypography.finePrint)
                    .foregroundStyle(Color.mdailyMutedInk)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                syncService.refreshPeers()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .mdailyGlassButton(prominent: false)
            .accessibilityLabel(isEnglish ? "Refresh LAN peers" : "Quét lại thiết bị")
        }
        .padding(12)
        .mdailyGlassSurface(in: RoundedRectangle(cornerRadius: MDailyRadius.lg, style: .continuous), interactive: false)
    }

    private var compactStatusText: String {
        if let status = syncService.statusMessage {
            return status
        }
        if let last = syncService.lastSyncedAt {
            return last.formatted(date: .omitted, time: .shortened)
        }
        return syncService.isRunning
            ? (isEnglish ? "Listening on LAN" : "Đang quét mạng LAN")
            : (isEnglish ? "Paused" : "Tạm dừng")
    }

    // MARK: - Nearby Peers

    @ViewBuilder
    private var peersList: some View {
        if syncService.peers.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "wifi")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.mdailyMutedInk)
                Text(isEnglish ? "No nearby devices" : "Chưa thấy thiết bị gần đây")
                    .font(MDailyTypography.finePrint)
                    .foregroundStyle(Color.mdailyMutedInk)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .mdailyGlassSurface(in: RoundedRectangle(cornerRadius: MDailyRadius.md, style: .continuous), interactive: false)
        } else {
            VStack(spacing: 8) {
                ForEach(syncService.peers) { peer in
                    peerRow(peer)
                }
            }
        }
    }

    private func peerRow(_ peer: DiscoveredPeer) -> some View {
        HStack(spacing: 10) {
            Image(systemName: iconName(for: peer.name))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.mdailyActionBlue)
                .frame(width: 32, height: 32)
                .mdailyGlassSurface(in: Circle(), interactive: false)

            Text(peer.name)
                .font(MDailyTypography.captionStrong)
                .foregroundStyle(Color.mdailyInk)
                .lineLimit(1)

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
                    Text(isEnglish ? "Sync" : "Đồng bộ")
                        .font(MDailyTypography.finePrint)
                        .fontWeight(.semibold)
                }
            }
            .mdailyGlassButton(prominent: true)
            .disabled(syncService.isSyncing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .mdailyGlassSurface(in: RoundedRectangle(cornerRadius: MDailyRadius.lg, style: .continuous), interactive: false)
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
}
