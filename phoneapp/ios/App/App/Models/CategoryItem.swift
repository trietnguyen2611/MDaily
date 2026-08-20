import Foundation
import SwiftUI

public struct CategoryItem: Identifiable, Codable, Sendable, Hashable {
    public var id: String
    public var label: String
    public var isDefault: Bool

    public init(id: String, label: String, isDefault: Bool = false) {
        self.id = id
        self.label = label
        self.isDefault = isDefault
    }

    public var iconName: String {
        switch id {
        case "bills": return "doc.text.fill"
        case "shopping": return "bag.fill"
        case "food": return "fork.knife"
        case "transport": return "car.fill"
        default: return "tag.fill"
        }
    }

    /// Returns the localized label for default categories based on language.
    /// User-created categories always return their original label.
    public func localizedLabel(lang: Language) -> String {
        guard isDefault else { return label }
        switch id {
        case "shopping": return lang == .en ? "Shopping" : "Mua sắm"
        case "food": return lang == .en ? "Food & Dining" : "Ăn uống"
        case "bills": return lang == .en ? "Bills" : "Hoá đơn"
        case "transport": return lang == .en ? "Transport" : "Di chuyển"
        default: return label
        }
    }
}

public extension CategoryItem {
    static let defaults: [CategoryItem] = [
        CategoryItem(id: "shopping", label: "Mua sắm", isDefault: true),
        CategoryItem(id: "food", label: "Ăn uống", isDefault: true),
        CategoryItem(id: "bills", label: "Hoá đơn", isDefault: true),
        CategoryItem(id: "transport", label: "Di chuyển", isDefault: true)
    ]
}
