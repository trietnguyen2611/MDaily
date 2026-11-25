import Foundation
@preconcurrency import Network
import Combine
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public struct DiscoveredPeer: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let endpoint: NWEndpoint
    public var lastSeen: Date

    public init(id: String, name: String, endpoint: NWEndpoint, lastSeen: Date = Date()) {
        self.id = id
        self.name = name
        self.endpoint = endpoint
        self.lastSeen = lastSeen
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: DiscoveredPeer, rhs: DiscoveredPeer) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}

public enum BonjourSyncError: LocalizedError {
    case connectionFailed(String)
    case invalidFrame
    case timeout
    case storeUnavailable

    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return msg
        case .invalidFrame: return "Invalid sync payload frame"
        case .timeout: return "Sync connection timed out"
        case .storeUnavailable: return "FinanceStore is not attached"
        }
    }
}

@MainActor
public final class BonjourSyncService: ObservableObject {
    public static let serviceType = "_mdaily-sync._tcp"

    @Published public var peers: [DiscoveredPeer] = []
    @Published public var isRunning: Bool = false
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncedAt: Date? = nil
    @Published public var statusMessage: String? = nil

    private var listener: NWListener?
    private var browser: NWBrowser?
    private let networkQueue = DispatchQueue(label: "com.mdaily.bonjour.network", qos: .userInitiated)
    private weak var boundStore: FinanceStore?
    private let localDeviceName: String

    public init() {
        self.localDeviceName = Self.resolveDeviceName()
    }

    public var deviceDisplayName: String {
        localDeviceName
    }

    public func attach(store: FinanceStore) {
        self.boundStore = store
    }

    public func start(store: FinanceStore? = nil) {
        if let store {
            self.boundStore = store
        }
        guard !isRunning else { return }
        startListener()
        startBrowser()
        isRunning = true
    }

    public func stop() {
        listener?.stateUpdateHandler = nil
        listener?.newConnectionHandler = nil
        listener?.cancel()
        listener = nil

        browser?.stateUpdateHandler = nil
        browser?.browseResultsChangedHandler = nil
        browser?.cancel()
        browser = nil

        isRunning = false
    }

    public func refreshPeers() {
        browser?.stateUpdateHandler = nil
        browser?.browseResultsChangedHandler = nil
        browser?.cancel()
        browser = nil
        peers.removeAll()

        if listener == nil {
            startListener()
        }
        startBrowser()
        isRunning = true
    }

    public func sync(with peer: DiscoveredPeer, store: FinanceStore) async {
        self.boundStore = store
        guard !isSyncing else { return }

        isSyncing = true
        let isEn = store.language == .en
        statusMessage = isEn
            ? "Connecting to \(peer.name)..."
            : "Đang kết nối tới \(peer.name)..."

        do {
            let params = NWParameters.tcp
            params.includePeerToPeer = true
            let connection = NWConnection(to: peer.endpoint, using: params)

            try await waitUntilReady(connection: connection, timeoutSeconds: 12)
            defer { connection.cancel() }

            let outgoing = store.exportSyncPayload()
            let frameData = try Self.encodeFrame(outgoing)
            try await sendData(frameData, on: connection)

            let incoming = try await receiveFrame(on: connection)
            let stats = store.mergeSyncPayload(incoming)
            let now = Date()
            self.lastSyncedAt = now
            self.statusMessage = Self.formatSyncSummary(
                peerName: peer.name,
                stats: stats,
                isEnglish: isEn
            )
        } catch {
            self.statusMessage = isEn
                ? "Sync failed with \(peer.name): \(error.localizedDescription)"
                : "Đồng bộ thất bại với \(peer.name): \(error.localizedDescription)"
        }

        isSyncing = false
    }

    // MARK: - Listener & Browser

    private func startListener() {
        do {
            let params = NWParameters.tcp
            params.includePeerToPeer = true
            let listener = try NWListener(using: params)
            listener.service = NWListener.Service(name: localDeviceName, type: Self.serviceType)

            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    switch state {
                    case .failed(let error):
                        self.statusMessage = "Listener error: \(error.localizedDescription)"
                        self.listener?.cancel()
                        self.listener = nil
                    default:
                        break
                    }
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor [weak self] in
                    await self?.handleIncomingConnection(connection)
                }
            }

            listener.start(queue: networkQueue)
            self.listener = listener
        } catch {
            statusMessage = "Failed to start LAN listener: \(error.localizedDescription)"
        }
    }

    private func startBrowser() {
        let params = NWParameters.tcp
        params.includePeerToPeer = true
        let descriptor = NWBrowser.Descriptor.bonjour(type: Self.serviceType, domain: nil)
        let browser = NWBrowser(for: descriptor, using: params)

        browser.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if case .failed(let error) = state {
                    self.statusMessage = "Discovery error: \(error.localizedDescription)"
                }
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            let discovered: [DiscoveredPeer] = results.compactMap { result in
                guard case let .service(name, type, domain, _) = result.endpoint else {
                    return nil
                }
                let identifier = "\(name).\(type).\(domain)"
                return DiscoveredPeer(
                    id: identifier,
                    name: name,
                    endpoint: result.endpoint,
                    lastSeen: Date()
                )
            }

            Task { @MainActor [weak self] in
                guard let self else { return }
                let filtered = discovered.filter { $0.name != self.localDeviceName }
                self.peers = filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
        }

        browser.start(queue: networkQueue)
        self.browser = browser
    }

    private func handleIncomingConnection(_ connection: NWConnection) async {
        do {
            try await waitUntilReady(connection: connection, timeoutSeconds: 12)
            defer { connection.cancel() }

            let incoming = try await receiveFrame(on: connection)
            guard let store = boundStore else {
                throw BonjourSyncError.storeUnavailable
            }

            let outgoing = store.exportSyncPayload()
            let stats = store.mergeSyncPayload(incoming)
            let frameData = try Self.encodeFrame(outgoing)
            try await sendData(frameData, on: connection)

            self.lastSyncedAt = Date()
            self.statusMessage = Self.formatSyncSummary(
                peerName: incoming.deviceName,
                stats: stats,
                isEnglish: store.language == .en
            )
        } catch {
            connection.cancel()
        }
    }

    // MARK: - Framing & Connection I/O

    private final class ReadyContinuationBox: @unchecked Sendable {
        private let lock = NSLock()
        private var resumed = false
        private let continuation: CheckedContinuation<Void, Error>

        init(_ continuation: CheckedContinuation<Void, Error>) {
            self.continuation = continuation
        }

        func finish(_ result: Result<Void, Error>) {
            lock.lock()
            defer { lock.unlock() }
            guard !resumed else { return }
            resumed = true
            continuation.resume(with: result)
        }
    }

    private func waitUntilReady(connection: NWConnection, timeoutSeconds: UInt64) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let box = ReadyContinuationBox(continuation)

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    box.finish(.success(()))
                case .failed(let error):
                    box.finish(.failure(BonjourSyncError.connectionFailed(error.localizedDescription)))
                case .cancelled:
                    box.finish(.failure(BonjourSyncError.connectionFailed("Connection cancelled")))
                default:
                    break
                }
            }

            connection.start(queue: networkQueue)

            networkQueue.asyncAfter(deadline: .now() + .seconds(Int(timeoutSeconds))) {
                box.finish(.failure(BonjourSyncError.timeout))
            }
        }
    }

    private func sendData(_ data: Data, on connection: NWConnection) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }

    private func receiveFrame(on connection: NWConnection) async throws -> SyncPayload {
        let headerData = try await receiveExact(length: 4, on: connection)
        let lengthValue: UInt32 = headerData.withUnsafeBytes { rawBuffer in
            let value = rawBuffer.load(as: UInt32.self)
            return UInt32(bigEndian: value)
        }

        let payloadLength = Int(lengthValue)
        guard payloadLength > 0, payloadLength <= 64 * 1024 * 1024 else {
            throw BonjourSyncError.invalidFrame
        }

        let jsonData = try await receiveExact(length: payloadLength, on: connection)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SyncPayload.self, from: jsonData)
    }

    private func receiveExact(length: Int, on connection: NWConnection) async throws -> Data {
        var buffer = Data()
        buffer.reserveCapacity(length)

        while buffer.count < length {
            let remaining = length - buffer.count
            let chunk: Data = try await withCheckedThrowingContinuation { continuation in
                connection.receive(minimumIncompleteLength: 1, maximumLength: remaining) { data, _, isComplete, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let data, !data.isEmpty {
                        continuation.resume(returning: data)
                    } else if isComplete {
                        continuation.resume(throwing: BonjourSyncError.invalidFrame)
                    } else {
                        continuation.resume(returning: Data())
                    }
                }
            }

            if chunk.isEmpty {
                throw BonjourSyncError.invalidFrame
            }
            buffer.append(chunk)
        }

        return buffer
    }

    private static func encodeFrame(_ payload: SyncPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(payload)
        var lengthPrefix = UInt32(jsonData.count).bigEndian
        var frame = Data(bytes: &lengthPrefix, count: MemoryLayout<UInt32>.size)
        frame.append(jsonData)
        return frame
    }

    private static func formatSyncSummary(peerName: String, stats: SyncMergeStats, isEnglish: Bool) -> String {
        if isEnglish {
            return "Synced with \(peerName): +\(stats.added) added, \(stats.updated) updated, \(stats.deleted) removed"
        } else {
            return "Đã đồng bộ với \(peerName): +\(stats.added) mới, \(stats.updated) cập nhật, \(stats.deleted) đã xoá"
        }
    }

    private static func resolveDeviceName() -> String {
        #if canImport(UIKit)
        return UIDevice.current.name
        #elseif canImport(AppKit)
        return Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        #else
        return ProcessInfo.processInfo.hostName
        #endif
    }
}
