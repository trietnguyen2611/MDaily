import Foundation
import SwiftUI
import Combine

public struct SyncServerPayload: Codable, Sendable {
    public var app: String?
    public var v: String?
    public var ip: String
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
}

public struct RemoteCategoryDTO: Codable {
    public var value: String
    public var label: String
}

public struct SyncResponseDTO: Codable {
    public var success: Bool
    public var expenses: [RemoteExpenseDTO]?
    public var categories: [RemoteCategoryDTO]?
    public var error: String?
}

@MainActor
public final class WifiSyncService: ObservableObject {
    public static let shared = WifiSyncService()

    @Published public var isSyncing: Bool = false
    @Published public var lastMessage: String?
    @Published public var errorMessage: String?
    @Published public var pairedServer: SyncServerPayload?

    private let lastServerKey = "mdaily_last_sync_server_ios"

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

    public func disconnect() {
        self.pairedServer = nil
        UserDefaults.standard.removeObject(forKey: lastServerKey)
    }

    // Ping check
    public func ping(ip: String, port: Int) async throws -> String {
        guard let url = URL(string: "http://\(ip):\(port)/api/ping") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 4.0

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            throw URLError(.cannotConnectToHost)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let name = json["deviceName"] as? String {
            return name
        }
        return "MDaily Desktop"
    }

    // 2-Way Merge
    public func performMerge(store: ExpenseStore, ip: String, port: Int, token: String) async throws {
        self.isSyncing = true
        self.errorMessage = nil
        defer { self.isSyncing = false }

        guard let url = URL(string: "http://\(ip):\(port)/api/sync/merge") else {
            throw URLError(.badURL)
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
                id: ex.id.uuidString,
                amount: ex.amount,
                category: ex.category,
                date: isoFormatter.string(from: ex.date),
                photo: photoBase64,
                note: ex.note,
                isAiProcessed: ex.isAiProcessed
            )
        }

        let localCatDTOs: [RemoteCategoryDTO] = store.categories.map {
            RemoteCategoryDTO(value: $0.id, label: $0.label)
        }

        let reqBody: [String: Any] = [
            "token": token,
            "expenses": localDTOs.map { [
                "id": $0.id,
                "amount": $0.amount,
                "category": $0.category,
                "date": $0.date,
                "photo": $0.photo as Any,
                "note": $0.note as Any,
                "isAiProcessed": $0.isAiProcessed ?? false
            ] },
            "categories": localCatDTOs.map { [
                "value": $0.value,
                "label": $0.label
            ] }
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(token, forHTTPHeaderField: "x-sync-token")
        req.timeoutInterval = 15.0
        req.httpBody = try JSONSerialization.data(withJSONObject: reqBody)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let resDTO = try JSONDecoder().decode(SyncResponseDTO.self, from: data)
        guard resDTO.success, let returnedExpenses = resDTO.expenses else {
            throw NSError(domain: "Sync", code: -1, userInfo: [NSLocalizedDescriptionKey: resDTO.error ?? "Merge failed"])
        }

        // Apply to Swift ExpenseStore
        var newExpenses: [Expense] = []
        for dto in returnedExpenses {
            let uuid = UUID(uuidString: dto.id) ?? UUID()
            let date = isoFormatter.date(from: dto.date) ?? ISO8601DateFormatter().date(from: dto.date) ?? Date()

            var photoData: Data? = nil
            if let photoStr = dto.photo, !photoStr.isEmpty {
                let clean = photoStr.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                                    .replacingOccurrences(of: "data:image/png;base64,", with: "")
                photoData = Data(base64Encoded: clean)
            }

            let ex = Expense(
                id: uuid,
                amount: dto.amount,
                category: dto.category,
                date: date,
                note: dto.note,
                photoData: photoData,
                isAiProcessed: dto.isAiProcessed ?? false
            )
            newExpenses.append(ex)
        }

        // Sort descending
        newExpenses.sort { $0.date > $1.date }
        store.expenses = newExpenses

        // Categories
        if let returnedCats = resDTO.categories {
            for cat in returnedCats {
                if !store.categories.contains(where: { $0.id == cat.value }) {
                    store.categories.append(CategoryItem(id: cat.value, label: cat.label, isDefault: false))
                }
            }
        }

        self.lastMessage = "Đồng bộ 2 chiều thành công (\(newExpenses.count) chi tiêu)"
    }
}
