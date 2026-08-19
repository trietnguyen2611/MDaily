import Foundation
import SwiftUI

public struct Expense: Identifiable, Codable, Sendable, Hashable {
    public var id: UUID
    public var amount: Double
    public var category: String
    public var date: Date
    public var note: String?
    public var photoData: Data?
    public var isAiProcessed: Bool

    public init(
        id: UUID = UUID(),
        amount: Double,
        category: String,
        date: Date = Date(),
        note: String? = nil,
        photoData: Data? = nil,
        isAiProcessed: Bool = false
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.note = note
        self.photoData = photoData
        self.isAiProcessed = isAiProcessed
    }
}
