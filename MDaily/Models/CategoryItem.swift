import Foundation

public struct CategoryItem: Identifiable, Codable, Sendable, Hashable {
    public var id: String
    public var label: String
    public var kind: TransactionKind
    public var iconSymbol: String?
    public var isDefault: Bool

    public init(
        id: String,
        label: String,
        kind: TransactionKind = .expense,
        iconSymbol: String? = nil,
        isDefault: Bool = false
    ) {
        self.id = id
        self.label = label
        self.kind = kind
        self.iconSymbol = iconSymbol
        self.isDefault = isDefault
    }

    public var resolvedIconName: String {
        if let iconSymbol, !iconSymbol.isEmpty {
            return iconSymbol
        }
        switch id {
        case "shopping": return "bag.fill"
        case "food": return "fork.knife"
        case "bills": return "doc.text.fill"
        case "transport": return "car.fill"
        case "health": return "cross.case.fill"
        case "salary": return "banknote.fill"
        case "bonus": return "gift.fill"
        case "investment": return "chart.line.uptrend.xyaxis"
        case "freelance": return "laptopcomputer"
        case "other_income": return "plus.circle.fill"
        default:
            return kind == .income ? "arrow.down.circle.fill" : "tag.fill"
        }
    }

    public func localizedLabel(lang: Language) -> String {
        guard isDefault else { return label }
        switch id {
        // Expense defaults
        case "shopping": return lang == .en ? "Shopping" : "Mua sắm"
        case "food": return lang == .en ? "Food & Dining" : "Ăn uống"
        case "bills": return lang == .en ? "Bills" : "Hoá đơn"
        case "transport": return lang == .en ? "Transport" : "Di chuyển"
        case "health": return lang == .en ? "Health" : "Sức khoẻ"
        // Income defaults
        case "salary": return lang == .en ? "Salary" : "Lương"
        case "bonus": return lang == .en ? "Bonus" : "Thưởng"
        case "investment": return lang == .en ? "Investment" : "Đầu tư"
        case "freelance": return lang == .en ? "Freelance" : "Làm thêm"
        case "other_income": return lang == .en ? "Other Income" : "Thu nhập khác"
        default: return label
        }
    }
}

public extension CategoryItem {
    static let defaultExpenses: [CategoryItem] = [
        CategoryItem(id: "shopping", label: "Mua sắm", kind: .expense, iconSymbol: "bag.fill", isDefault: true),
        CategoryItem(id: "food", label: "Ăn uống", kind: .expense, iconSymbol: "fork.knife", isDefault: true),
        CategoryItem(id: "bills", label: "Hoá đơn", kind: .expense, iconSymbol: "doc.text.fill", isDefault: true),
        CategoryItem(id: "transport", label: "Di chuyển", kind: .expense, iconSymbol: "car.fill", isDefault: true),
        CategoryItem(id: "health", label: "Sức khoẻ", kind: .expense, iconSymbol: "cross.case.fill", isDefault: true)
    ]

    static let defaultIncomes: [CategoryItem] = [
        CategoryItem(id: "salary", label: "Lương", kind: .income, iconSymbol: "banknote.fill", isDefault: true),
        CategoryItem(id: "bonus", label: "Thưởng", kind: .income, iconSymbol: "gift.fill", isDefault: true),
        CategoryItem(id: "investment", label: "Đầu tư", kind: .income, iconSymbol: "chart.line.uptrend.xyaxis", isDefault: true),
        CategoryItem(id: "freelance", label: "Làm thêm", kind: .income, iconSymbol: "laptopcomputer", isDefault: true),
        CategoryItem(id: "other_income", label: "Thu nhập khác", kind: .income, iconSymbol: "plus.circle.fill", isDefault: true)
    ]

    static let defaults: [CategoryItem] = defaultExpenses + defaultIncomes
}
