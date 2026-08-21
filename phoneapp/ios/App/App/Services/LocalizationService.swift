import Foundation
import SwiftUI

public enum Language: String, Codable, CaseIterable, Identifiable, Sendable {
    case vi = "vi"
    case en = "en"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .vi: return "Tiếng Việt"
        case .en: return "English"
        }
    }

    public var displayName: String { title }
}

public enum Currency: String, Codable, CaseIterable, Identifiable, Sendable {
    case vnd = "vnd"
    case usd = "usd"
    case eur = "eur"
    case jpy = "jpy"
    case gbp = "gbp"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .vnd: return "VNĐ (₫)"
        case .usd: return "USD ($)"
        case .eur: return "EUR (€)"
        case .jpy: return "JPY (¥)"
        case .gbp: return "GBP (£)"
        }
    }

    public var displayName: String { title }

    public var symbol: String {
        switch self {
        case .vnd: return "đ"
        case .usd: return "$"
        case .eur: return "€"
        case .jpy: return "¥"
        case .gbp: return "£"
        }
    }

    public func format(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        switch self {
        case .vnd:
            formatter.locale = Locale(identifier: "vi_VN")
            formatter.maximumFractionDigits = 0
            let str = formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
            return "\(str) đ"
        case .usd:
            formatter.locale = Locale(identifier: "en_US")
            formatter.maximumFractionDigits = 2
            let str = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
            return "$\(str)"
        case .eur:
            formatter.locale = Locale(identifier: "de_DE")
            formatter.maximumFractionDigits = 2
            let str = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
            return "€\(str)"
        case .jpy:
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.maximumFractionDigits = 0
            let str = formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
            return "¥\(str)"
        case .gbp:
            formatter.locale = Locale(identifier: "en_GB")
            formatter.maximumFractionDigits = 2
            let str = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
            return "£\(str)"
        }
    }
}

/// Appearance mode for the app (light, dark, or system default)
public enum AppearanceMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    public var id: String { rawValue }
}

public struct LocalizationService {
    public static func t(_ key: String, lang: Language) -> String {
        let dict: [String: [Language: String]] = [
            // Tabs
            "tab_dashboard": [.vi: "Tổng quan", .en: "Overview"],
            "tab_add_expense": [.vi: "Thêm chi tiêu", .en: "Add Expense"],
            "tab_reports": [.vi: "Phân loại", .en: "Categories"],
            "tab_settings": [.vi: "Cài đặt", .en: "Settings"],
            "mdaily_ai": [.vi: "MDaily AI", .en: "MDaily AI"],

            // Filters
            "all_time": [.vi: "Tất cả thời gian", .en: "All Time"],
            "today": [.vi: "Hôm nay", .en: "Today"],
            "this_week": [.vi: "Tuần này", .en: "This Week"],
            "this_month": [.vi: "Tháng này", .en: "This Month"],
            "this_year": [.vi: "Năm nay", .en: "This Year"],
            "all_categories": [.vi: "Tất cả danh mục", .en: "All Categories"],

            // Dashboard
            "no_expenses": [.vi: "Chưa có chi tiêu nào. Bấm \"+\" hoặc nút chụp ảnh để thêm mới.", .en: "No expenses yet. Tap \"+\" or camera button to create one."],
            "delete_confirm": [.vi: "Xoá khoản chi tiêu này?", .en: "Delete this expense?"],
            "delete": [.vi: "Xoá", .en: "Delete"],
            "cancel": [.vi: "Huỷ", .en: "Cancel"],
            "save": [.vi: "Lưu", .en: "Save"],
            "done": [.vi: "Xong", .en: "Done"],
            "edit": [.vi: "Sửa", .en: "Edit"],

            // Add Expense
            "add_photo": [.vi: "Thêm ảnh (tùy chọn)", .en: "Add Photo (Optional)"],
            "ai_auto_extract": [.vi: "✨ MDaily AI sẽ tự động nhận diện hoá đơn", .en: "✨ MDaily AI will auto-extract receipt"],
            "take_photo": [.vi: "Chụp hoặc chọn ảnh hoá đơn", .en: "Capture or choose receipt photo"],
            "amount": [.vi: "Số tiền", .en: "Amount"],
            "category": [.vi: "Danh mục", .en: "Category"],
            "add_new_category": [.vi: "Thêm danh mục mới", .en: "Add new category"],
            "new_cat_placeholder": [.vi: "Tên danh mục mới...", .en: "New category name..."],
            "note": [.vi: "Ghi chú / Tên đồ vật", .en: "Note / Item Name"],
            "note_placeholder": [.vi: "Nhập ghi chú...", .en: "Enter note..."],
            "save_expense": [.vi: "Lưu chi tiêu", .en: "Save Expense"],
            "invalid_amount": [.vi: "Vui lòng nhập số tiền hợp lệ!", .en: "Please enter a valid amount!"],

            // Detail
            "expense_details": [.vi: "Chi tiết chi tiêu", .en: "Expense Details"],
            "edit_expense": [.vi: "Chỉnh sửa chi tiêu", .en: "Edit Expense"],
            "expense_amount": [.vi: "Số tiền chi tiêu", .en: "Expense Amount"],
            "time": [.vi: "Thời gian", .en: "Time"],
            "date": [.vi: "Thời gian", .en: "Time"],
            "no_note": [.vi: "Không có ghi chú", .en: "No note"],
            "delete_this_expense": [.vi: "Xoá chi tiêu này", .en: "Delete this expense"],
            "view_full": [.vi: "Xem đầy đủ", .en: "View Full"],

            // Reports
            "chart_overview": [.vi: "Tổng phân bổ", .en: "Total Allocation"],
            "transactions": [.vi: "giao dịch", .en: "transactions"],
            "categories_count": [.vi: "danh mục", .en: "categories"],
            "no_data": [.vi: "Chưa có dữ liệu chi tiêu trong khoảng thời gian này", .en: "No expense data for this time period"],
            "category_breakdown": [.vi: "Chi tiết theo danh mục", .en: "Category Breakdown"],
            "create_category": [.vi: "Tạo danh mục mới", .en: "Create New Category"],
            "rename_category": [.vi: "Đổi tên danh mục", .en: "Rename Category"],
            "cat_placeholder": [.vi: "Nhập tên danh mục...", .en: "Enter category name..."],
            "delete_cat_confirm": [.vi: "Bạn chắc chắn muốn xoá danh mục này?", .en: "Are you sure you want to delete this category?"],

            // Settings
            "apple_intelligence": [.vi: "MDaily AI", .en: "MDaily AI"],
            "status": [.vi: "Trạng thái", .en: "Status"],
            "available": [.vi: "Khả dụng", .en: "Available"],
            "unavailable": [.vi: "Không khả dụng", .en: "Unavailable"],
            "auto_extract": [.vi: "Tự động nhận diện ảnh", .en: "Auto Image Recognition"],
            "auto_extract_desc": [.vi: "Trích xuất hoá đơn khi chụp ảnh", .en: "Extract receipts when taking photos"],
            "ai_chat": [.vi: "AI Chat", .en: "AI Chat"],
            "ai_chat_desc": [.vi: "Trò chuyện với MDaily AI trợ lý tài chính", .en: "Chat with MDaily AI financial assistant"],
            "ui_options": [.vi: "Giao diện & Tuỳ chọn", .en: "Appearance & Options"],
            "language": [.vi: "Ngôn ngữ", .en: "Language"],
            "language_desc": [.vi: "Ngôn ngữ hiển thị trong ứng dụng", .en: "Display language of the app"],
            "currency": [.vi: "Đơn vị tiền tệ", .en: "Currency"],
            "currency_desc": [.vi: "Đơn vị tiền tệ hiển thị trong ứng dụng", .en: "Display currency throughout the app"],
            "data_management": [.vi: "Quản lý dữ liệu", .en: "Data Management"],
            "delete_all_data": [.vi: "Xoá toàn bộ dữ liệu", .en: "Clear All Data"],
            "delete_all_desc": [.vi: "Xoá tất cả chi tiêu đã lưu", .en: "Permanently remove all recorded expenses"],
            "delete_data_btn": [.vi: "Xoá dữ liệu", .en: "Clear Data"],
            "delete_confirm_all": [.vi: "Bạn chắc chắn muốn xoá toàn bộ dữ liệu chi tiêu?", .en: "Are you sure you want to clear all expense data?"],
            "app_info": [.vi: "Thông tin ứng dụng", .en: "About App"],
            "app_version": [.vi: "v2.3 — MDaily AI", .en: "v2.3 — MDaily AI"],

            // Chatbot
            "financial_assistant": [.vi: "Trợ lý tài chính thông minh", .en: "Smart Financial Assistant"],
            "clear_chat": [.vi: "Xoá đoạn chat", .en: "Clear Chat"],
            "clear_chat_confirm_title": [.vi: "Xoá lịch sử chat?", .en: "Clear chat history?"],
            "clear_chat_confirm_desc": [.vi: "Hành động này sẽ xoá sạch cuộc hội thoại hiện tại.", .en: "This will permanently delete all messages in the current conversation."],
            "type_message": [.vi: "Hỏi AI về chi tiêu của bạn...", .en: "Ask AI about your spending..."],
            "send": [.vi: "Gửi", .en: "Send"],
            "ai_thinking": [.vi: "MDaily AI đang suy nghĩ...", .en: "MDaily AI is thinking..."],

            // New keys for language fixes
            "data_cleared": [.vi: "Đã xoá dữ liệu", .en: "Data Cleared"],
            "delete_all_confirm_message": [.vi: "Toàn bộ chi tiêu và dữ liệu của bạn sẽ bị xoá hoàn toàn.", .en: "All your expenses and data will be permanently deleted."],
            "ai_recognizing": [.vi: "AI đang nhận diện...", .en: "AI recognizing..."],
            "add_expense_photo": [.vi: "Thêm ảnh chi tiêu", .en: "Add expense photo"],
            "take_photo_camera": [.vi: "Chụp ảnh từ Máy ảnh", .en: "Take Photo"],
            "choose_from_library": [.vi: "Chọn từ Thư viện ảnh", .en: "Choose from Library"],
            "chat_button": [.vi: "Trò chuyện", .en: "Chat"],
            "ai_recognized_by": [.vi: "Nhận diện bởi AI", .en: "Recognized by AI"],
            "app_title": [.vi: "MDaily — Quản Lý Chi Tiêu", .en: "MDaily — Expense Manager"],

            // Appearance mode
            "appearance": [.vi: "Giao diện", .en: "Appearance"],
            "appearance_desc": [.vi: "Chế độ giao diện sáng, tối hoặc theo hệ thống", .en: "Light, dark, or system appearance mode"],
            "appearance_light": [.vi: "Sáng", .en: "Light"],
            "appearance_dark": [.vi: "Tối", .en: "Dark"],
            "appearance_system": [.vi: "Hệ thống", .en: "System"],

            // Recurring reminder features
            "recurring_reminder": [.vi: "Nhắc thanh toán", .en: "Payment Reminder"],
            "recurring_reminder_desc": [.vi: "Tạo nhắc nhở thanh toán tự động định kỳ", .en: "Create automated recurring payment reminders"],
            "reminder_date": [.vi: "Ngày nhắc", .en: "Reminder Date"],
            "repeat_interval": [.vi: "Lặp lại", .en: "Repeat"],
            "view_details": [.vi: "Xem chi tiết", .en: "View Details"],
            "share_image": [.vi: "Chia sẻ ảnh", .en: "Share Image"]
        ]

        return dict[key]?[lang] ?? dict[key]?[.vi] ?? key
    }
}
