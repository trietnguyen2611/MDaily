import Foundation

public enum CameraLayoutMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case `default` = "default"
    case dynamicIsland = "dynamic_island"

    public var id: String { rawValue }

    public func title(lang: Language) -> String {
        switch self {
        case .default: return lang == .en ? "Default Full Screen" : "Mặc định (Toàn màn hình)"
        case .dynamicIsland: return lang == .en ? "Dynamic Island" : "Dynamic Island"
        }
    }
}
