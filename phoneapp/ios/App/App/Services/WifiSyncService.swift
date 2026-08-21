import Foundation
import SwiftUI
import Combine

public struct SyncServerPayload: Codable, Sendable {
    public var app: String?
    public var v: String?
    public var ip: String
    public var allIps: [String]?
    public var port: Int
    public var token: String
    public var name: String?
}

public struct RemoteExpenseDTO: Codable {
    public var id: String
    public var amount: Double
    public var category: String
    public var date: String
    public var photo: String?
    public var note: String?
    public var isAiProcessed: Bool?
    public var updatedAt: Double?
}

public struct RemoteCategoryDTO: Codable {
    public var value: String
    public var label: String
}

public struct SyncResponseDTO: Codable {
    public var success: Bool
    public var expenses: [RemoteExpenseDTO]?
    public var categories: [RemoteCategoryDTO]?
    public var deletedExpenseIds: [String]?
    public var deletedCategoryValues: [String]?
    public var error: String?
}

@MainActor
public final class WifiSyncService: ObservableObject {
    public static let shared = WifiSyncService()

    @Published public var isSyncing: Bool = false
    @Published public var isConnected: Bool = false
    @Published public var lastMessage: String?
    @Published public var errorMessage: String?
    @Published public var pairedServer: SyncServerPayload?

    private let lastServerKey = "mdaily_last_sync_server_ios"
    private let deletedExpenseIdsKey = "mdaily_deleted_expense_ids_ios"
    private let deletedCategoryValuesKey = "mdaily_deleted_category_values_ios"
    private var autoSyncTask: Task<Void, Never>?
    private var sseTask: Task<Void, Never>?

    public init() {
        loadSavedServer()
    }

    private func loadSavedServer() {
        if let data = UserDefaults.standard.data(forKey: lastServerKey),
           let saved = try? JSONDecoder().decode(SyncServerPayload.self, from: data) {
            self.pairedServer = saved
        }
    }

    public func saveServer(_ server: SyncServerPayload) {
        self.pairedServer = server
        if let encoded = try? JSONEncoder().encode(server) {
            UserDefaults.standard.set(encoded, forKey: lastServerKey)
        }
    }

    public func deletedExpenseIds() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: deletedExpenseIdsKey) ?? []
        return Set(array.suffix(1000))
    }

    public func markDeletedExpense(_ id: String) {
        var ids = deletedExpenseIds()
        ids.insert(id)
        UserDefaults.standard.set(Array(ids.suffix(1000)), forKey: deletedExpenseIdsKey)
    }

    public func deletedCategoryValues() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: deletedCategoryValuesKey) ?? []
        return Set(array.suffix(200))
    }

    public func markDeletedCategory(_ value: String) {
        var values = deletedCategoryValues()
        values.insert(value)
        UserDefaults.standard.set(Array(values.suffix(200)), forKey: deletedCategoryValuesKey)
    }

    public func disconnect() {
        self.pairedServer = nil
        self.isConnected = false
        UserDefaults.standard.removeObject(forKey: lastServerKey)
        autoSyncTask?.cancel()
        sseTask?.cancel()
    }

    // Trigger debounced automatic 2-way sync
    public func triggerAutoSync(store: ExpenseStore, delay: Double = 0.25) {
        guard let server = pairedServer else { return }
        autoSyncTask?.cancel()
        autoSyncTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            do {
                try await performMerge(store: store, server: server)
                print("[iOS Auto-Sync] Background 2-way sync completed")
            } catch {
                print("[iOS Auto-Sync] Skipped (Desktop may be offline):", error)
            }
        }
    }

    // Real-time SSE background stream listener with dedicated keep-alive session
    public func startRealtimeListener(store: ExpenseStore) {
        guard let server = pairedServer else { return }
        sseTask?.cancel()

        // Fast immediate sync upon starting listener
        triggerAutoSync(store: store, delay: 0.0)

        sseTask = Task { @MainActor in
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 6.0
            sessionConfig.timeoutIntervalForResource = TimeInterval(3600 * 24)
            sessionConfig.waitsForConnectivity = true
            let sseSession = URLSession(configuration: sessionConfig)

            // Try active working IP first, then other fallback IPs
            let candidateIps = [server.ip] + (server.allIps ?? []).filter { $0 != server.ip }

            while !Task.isCancelled {
                for ip in candidateIps {
                    guard let url = URL(string: "http://\(ip):\(server.port)/api/sync/stream?token=\(server.token)") else { continue }

                    do {
                        let (bytes, response) = try await sseSession.bytes(from: url)
                        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
                            continue
                        }

                        self.isConnected = true

                        for try await line in bytes.lines {
                            if Task.isCancelled { break }
                            if line.hasPrefix("data:") {
                                let jsonStr = line.replacingOccurrences(of: "data:", with: "").trimmingCharacters(in: .whitespaces)
                                if jsonStr.contains("data_changed") {
                                    print("[iOS SSE] Desktop mutation detected, auto-syncing in background...")
                                    triggerAutoSync(store: store, delay: 0.02)
                                }
                            }
                        }
                    } catch {
                        // Connection failed or closed, will try next candidate IP
                    }
                }

                self.isConnected = false
                if Task.isCancelled { break }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    // Ping check with fallback candidates
    public func ping(ip: String, port: Int, candidateIps: [String]? = nil) async throws -> (deviceName: String, workingIp: String, allIps: [String]?) {
        let ipsToTry = candidateIps?.isEmpty == false ? candidateIps! : [ip]

        for candidate in ipsToTry {
            guard let url = URL(string: "http://\(candidate):\(port)/api/ping") else { continue }
            var req = URLRequest(url: url)
            req.timeoutInterval = 3.5

            if let (data, response) = try? await URLSession.shared.data(for: req),
               let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let name = (json["deviceName"] as? String) ?? "MDaily Desktop"
                    let allIps = json["allIps"] as? [String]
                    return (name, candidate, allIps)
                }
                return ("MDaily Desktop", candidate, nil)
            }
        }
        throw URLError(.cannotConnectToHost)
    }

    // Date parsing helper supporting ISO8601 with/without ms and timestamp
    private func parseDate(from str: String) -> Date {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: str) { return date }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: str) { return date }

        let customFmt = DateFormatter()
        customFmt.locale = Locale(identifier: "en_US_POSIX")
        customFmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = customFmt.date(from: str) { return date }

        customFmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = customFmt.date(from: str) { return date }

        customFmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = customFmt.date(from: str) { return date }

        if let ts = Double(str) {
            let seconds = ts > 10_000_000_000 ? ts / 1000.0 : ts
            return Date(timeIntervalSince1970: seconds)
        }

        return Date()
    }

    // 2-Way Merge wrapped in iOS background task
    public func performMerge(store: ExpenseStore, server: SyncServerPayload? = nil, ip: String? = nil, port: Int? = nil, token: String? = nil) async throws {
        self.isSyncing = true
        self.errorMessage = nil
        defer { self.isSyncing = false }

        let targetServer = server ?? pairedServer
        let useIp = ip ?? targetServer?.ip ?? ""
        let usePort = port ?? targetServer?.port ?? 18321
        let useToken = token ?? targetServer?.token ?? ""
        let candidateIps = targetServer?.allIps?.isEmpty == false ? targetServer!.allIps! : [useIp]

        // Begin background task on iOS to ensure sync finishes if app is backgrounded
        let bgTask = UIApplication.shared.beginBackgroundTask(withName: "MDailyWifiSync") {}
        defer {
            if bgTask != .invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
            }
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Prepare local expenses
        let localDTOs: [RemoteExpenseDTO] = store.expenses.map { ex in
            var photoBase64: String? = nil
            if let photoData = ex.photoData {
                photoBase64 = "data:image/jpeg;base64,\(photoData.base64EncodedString())"
            }
            return RemoteExpenseDTO(
                id: ex.id,
                amount: ex.amount,
                category: ex.category,
                date: isoFormatter.string(from: ex.date),
                photo: photoBase64,
                note: ex.note,
                isAiProcessed: ex.isAiProcessed,
                updatedAt: ex.updatedAt.timeIntervalSince1970 * 1000.0
            )
        }

        let localCatDTOs: [RemoteCategoryDTO] = store.categories.map {
            RemoteCategoryDTO(value: $0.id, label: $0.label)
        }

        let reqBody: [String: Any] = [
            "token": useToken,
            "expenses": localDTOs.map { [
                "id": $0.id,
                "amount": $0.amount,
                "category": $0.category,
                "date": $0.date,
                "photo": $0.photo as Any,
                "note": $0.note as Any,
                "isAiProcessed": $0.isAiProcessed ?? false,
                "updatedAt": $0.updatedAt as Any
            ] },
            "categories": localCatDTOs.map { [
                "value": $0.value,
                "label": $0.label
            ] },
            "deletedExpenseIds": Array(deletedExpenseIds()),
            "deletedCategoryValues": Array(deletedCategoryValues())
        ]

        let reqData = try JSONSerialization.data(withJSONObject: reqBody)

        var lastError: Error? = nil
        var successData: Data? = nil
        var workingIp = useIp

        for candidateIp in candidateIps {
            guard let url = URL(string: "http://\(candidateIp):\(usePort)/api/sync/merge") else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(useToken, forHTTPHeaderField: "x-sync-token")
            req.timeoutInterval = 12.0
            req.httpBody = reqData

            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 {
                    successData = data
                    workingIp = candidateIp
                    break
                }
            } catch {
                lastError = error
            }
        }

        guard let data = successData else {
            throw lastError ?? URLError(.cannotConnectToHost)
        }

        let resDTO = try JSONDecoder().decode(SyncResponseDTO.self, from: data)
        guard resDTO.success, let returnedExpenses = resDTO.expenses else {
            throw NSError(domain: "Sync", code: -1, userInfo: [NSLocalizedDescriptionKey: resDTO.error ?? "Merge failed"])
        }

        // Apply merged expenses to Swift ExpenseStore preserving exact IDs and timestamps
        var newExpenses: [Expense] = []
        for dto in returnedExpenses {
            let date = parseDate(from: dto.date)
            let updatedAt: Date = dto.updatedAt != nil
                ? Date(timeIntervalSince1970: dto.updatedAt! / 1000.0)
                : date

            var photoData: Data? = nil
            if let photoStr = dto.photo, !photoStr.isEmpty {
                var clean = photoStr
                if let commaIndex = clean.firstIndex(of: ",") {
                    clean = String(clean[clean.index(after: commaIndex)...])
                }
                clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)
                photoData = Data(base64Encoded: clean, options: .ignoreUnknownCharacters)
            }

            let ex = Expense(
                id: dto.id,
                amount: dto.amount,
                category: dto.category,
                date: date,
                note: dto.note,
                photoData: photoData,
                isAiProcessed: dto.isAiProcessed ?? false,
                updatedAt: updatedAt
            )
            newExpenses.append(ex)
        }

        // Sort descending by date
        newExpenses.sort { $0.date > $1.date }

        if let returnedDeletedIds = resDTO.deletedExpenseIds {
            UserDefaults.standard.set(Array(Set(returnedDeletedIds).suffix(1000)), forKey: deletedExpenseIdsKey)
        }

        if let returnedDeletedCats = resDTO.deletedCategoryValues {
            UserDefaults.standard.set(Array(Set(returnedDeletedCats).suffix(200)), forKey: deletedCategoryValuesKey)
        }

        // Categories
        let deletedCatSet = deletedCategoryValues()
        var updatedCategories = store.categories.filter { !deletedCatSet.contains($0.id) }
        if let returnedCats = resDTO.categories {
            for cat in returnedCats {
                if !deletedCatSet.contains(cat.value) && !updatedCategories.contains(where: { $0.id == cat.value }) {
                    updatedCategories.append(CategoryItem(id: cat.value, label: cat.label, isDefault: false))
                }
            }
        }

        // Persist both expenses and categories to state and UserDefaults
        store.applySyncedData(expenses: newExpenses, categories: updatedCategories)

        if var current = targetServer, current.ip != workingIp {
            current.ip = workingIp
            saveServer(current)
        }

        self.lastMessage = "Đồng bộ 2 chiều thành công (\(newExpenses.count) chi tiêu)"
    }
}

