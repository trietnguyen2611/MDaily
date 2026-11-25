import Foundation

public enum RepeatInterval: String, Codable, CaseIterable, Identifiable, Sendable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"

    public var id: String { rawValue }

    public func title(lang: Language) -> String {
        switch self {
        case .none: return lang == .en ? "None" : "Không lặp lại"
        case .daily: return lang == .en ? "Daily" : "Hàng ngày"
        case .weekly: return lang == .en ? "Weekly" : "Hàng tuần"
        case .monthly: return lang == .en ? "Monthly" : "Hàng tháng"
        case .yearly: return lang == .en ? "Yearly" : "Hàng năm"
        }
    }
}

public struct RecurringTransaction: Identifiable, Codable, Sendable, Hashable {
    public var id: UUID
    public var kind: TransactionKind
    public var amount: Double
    public var categoryId: String
    public var note: String?
    public var reminderDate: Date
    public var repeatInterval: RepeatInterval
    public var isActive: Bool
    public var linkedTransactionId: String?

    public init(
        id: UUID = UUID(),
        kind: TransactionKind = .expense,
        amount: Double,
        categoryId: String,
        note: String? = nil,
        reminderDate: Date,
        repeatInterval: RepeatInterval = .monthly,
        isActive: Bool = true,
        linkedTransactionId: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.amount = amount
        self.categoryId = categoryId
        self.note = note
        self.reminderDate = reminderDate
        self.repeatInterval = repeatInterval
        self.isActive = isActive
        self.linkedTransactionId = linkedTransactionId
    }
}
