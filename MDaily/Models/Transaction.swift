import Foundation

public enum TransactionKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case expense = "expense"
    case income = "income"

    public var id: String { rawValue }

    public func title(lang: Language) -> String {
        switch self {
        case .expense:
            return lang == .en ? "Expense" : "Chi tiêu"
        case .income:
            return lang == .en ? "Income" : "Thu nhập"
        }
    }

    public var signPrefix: String {
        switch self {
        case .expense: return "-"
        case .income: return "+"
        }
    }
}

public struct Transaction: Identifiable, Codable, Sendable, Hashable {
    public var id: String
    public var kind: TransactionKind
    public var amount: Double
    public var categoryId: String
    public var date: Date
    public var note: String?
    public var photoData: Data?
    public var isAiProcessed: Bool
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        kind: TransactionKind = .expense,
        amount: Double,
        categoryId: String,
        date: Date = Date(),
        note: String? = nil,
        photoData: Data? = nil,
        isAiProcessed: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.amount = amount
        self.categoryId = categoryId
        self.date = date
        self.note = note
        self.photoData = photoData
        self.isAiProcessed = isAiProcessed
        self.updatedAt = updatedAt
    }
}

public struct ChatMessageSwift: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let role: String
    public var content: String
    public var animate: Bool

    public init(
        id: String = UUID().uuidString,
        role: String,
        content: String,
        animate: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.animate = animate
    }
}

public struct SyncPayload: Codable, Sendable {
    public var app: String
    public var version: String
    public var deviceName: String
    public var timestamp: Date
    public var transactions: [Transaction]
    public var categories: [CategoryItem]
    public var deletedTransactionIds: [String]
    public var deletedCategoryIds: [String]

    public init(
        app: String = "MDaily",
        version: String = "3.0",
        deviceName: String,
        timestamp: Date = Date(),
        transactions: [Transaction],
        categories: [CategoryItem],
        deletedTransactionIds: [String] = [],
        deletedCategoryIds: [String] = []
    ) {
        self.app = app
        self.version = version
        self.deviceName = deviceName
        self.timestamp = timestamp
        self.transactions = transactions
        self.categories = categories
        self.deletedTransactionIds = deletedTransactionIds
        self.deletedCategoryIds = deletedCategoryIds
    }
}

public struct SyncMergeStats: Sendable {
    public var added: Int
    public var updated: Int
    public var deleted: Int
    public var total: Int

    public init(added: Int = 0, updated: Int = 0, deleted: Int = 0, total: Int = 0) {
        self.added = added
        self.updated = updated
        self.deleted = deleted
        self.total = total
    }
}
