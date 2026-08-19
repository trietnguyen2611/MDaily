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
}

public extension CategoryItem {
    static let defaults: [CategoryItem] = [
        CategoryItem(id: "shopping", label: "Mua sắm", isDefault: true),
        CategoryItem(id: "food", label: "Ăn uống", isDefault: true),
        CategoryItem(id: "bills", label: "Hoá đơn", isDefault: true),
        CategoryItem(id: "transport", label: "Di chuyển", isDefault: true)
    ]
}
