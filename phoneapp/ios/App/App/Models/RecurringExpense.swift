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
        case .none: return lang == .en ? "No Repeat" : "Không lặp"
        case .daily: return lang == .en ? "Daily" : "Hàng ngày"
        case .weekly: return lang == .en ? "Weekly" : "Hàng tuần"
        case .monthly: return lang == .en ? "Monthly" : "Hàng tháng"
        case .yearly: return lang == .en ? "Yearly" : "Hàng năm"
        }
    }
}

public struct RecurringExpense: Identifiable, Codable, Sendable, Hashable {
    public var id: UUID
    public var amount: Double
    public var category: String
    public var note: String?
    public var photoData: Data?
    public var reminderDate: Date
    public var repeatInterval: RepeatInterval
    public var isActive: Bool
    public var lastTriggered: Date?
    public var linkedExpenseId: UUID?

    public init(
        id: UUID = UUID(),
        amount: Double,
        category: String,
        note: String? = nil,
        photoData: Data? = nil,
        reminderDate: Date,
        repeatInterval: RepeatInterval = .monthly,
        isActive: Bool = true,
        lastTriggered: Date? = nil,
        linkedExpenseId: UUID? = nil
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.note = note
        self.photoData = photoData
        self.reminderDate = reminderDate
        self.repeatInterval = repeatInterval
        self.isActive = isActive
        self.lastTriggered = lastTriggered
        self.linkedExpenseId = linkedExpenseId
    }
}
