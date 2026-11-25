import Foundation

public enum Language: String, Codable, CaseIterable, Identifiable, Sendable {
    case vi = "vi"
    case en = "en"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .vi: return "Tiếng Việt"
        case .en: return "English"
        }
    }

    public var title: String { displayName }
}

public enum Currency: String, Codable, CaseIterable, Identifiable, Sendable {
    case vnd = "vnd"
    case usd = "usd"
    case eur = "eur"
    case jpy = "jpy"
    case gbp = "gbp"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .vnd: return "VNĐ (₫)"
        case .usd: return "USD ($)"
        case .eur: return "EUR (€)"
        case .jpy: return "JPY (¥)"
        case .gbp: return "GBP (£)"
        }
    }

    public var title: String { displayName }

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

        let isNegative = amount < 0
        let absAmount = abs(amount)

        let formatted: String
        switch self {
        case .vnd:
            formatter.locale = Locale(identifier: "vi_VN")
            formatter.maximumFractionDigits = 0
            let str = formatter.string(from: NSNumber(value: absAmount)) ?? "\(Int(absAmount))"
            formatted = "\(str) đ"
        case .usd:
            formatter.locale = Locale(identifier: "en_US")
            formatter.maximumFractionDigits = 2
            let str = formatter.string(from: NSNumber(value: absAmount)) ?? "\(absAmount)"
            formatted = "$\(str)"
        case .eur:
            formatter.locale = Locale(identifier: "de_DE")
            formatter.maximumFractionDigits = 2
            let str = formatter.string(from: NSNumber(value: absAmount)) ?? "\(absAmount)"
            formatted = "€\(str)"
        case .jpy:
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.maximumFractionDigits = 0
            let str = formatter.string(from: NSNumber(value: absAmount)) ?? "\(Int(absAmount))"
            formatted = "¥\(str)"
        case .gbp:
            formatter.locale = Locale(identifier: "en_GB")
            formatter.maximumFractionDigits = 2
            let str = formatter.string(from: NSNumber(value: absAmount)) ?? "\(absAmount)"
            formatted = "£\(str)"
        }

        return isNegative ? "-\(formatted)" : formatted
    }
}

public enum AppearanceMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    public var id: String { rawValue }

    public func title(lang: Language) -> String {
        switch self {
        case .system: return lang == .en ? "System" : "Hệ thống"
        case .light: return lang == .en ? "Light" : "Sáng"
        case .dark: return lang == .en ? "Dark" : "Tối"
        }
    }
}

public struct LocalizationService: Sendable {
    public static func t(_ key: String, lang: Language) -> String {
        let dict: [String: [Language: String]] = [
            // Navigation Tabs
            "tab_dashboard": [.vi: "Tổng quan", .en: "Overview"],
            "tab_add_transaction": [.vi: "Thêm giao dịch", .en: "Add Transaction"],
            "tab_add_expense": [.vi: "Thêm giao dịch", .en: "Add Transaction"],
            "tab_reports": [.vi: "Báo cáo", .en: "Reports"],
            "tab_settings": [.vi: "Cài đặt", .en: "Settings"],
            "mdaily_ai": [.vi: "MDaily AI", .en: "MDaily AI"],

            // Transaction Kinds & Summary
            "expense": [.vi: "Chi tiêu", .en: "Expense"],
            "income": [.vi: "Thu nhập", .en: "Income"],
            "all": [.vi: "Tất cả", .en: "All"],
            "transaction_kind": [.vi: "Loại giao dịch", .en: "Transaction Type"],
            "net_balance": [.vi: "Số dư ròng", .en: "Net Balance"],
            "total_income": [.vi: "Tổng thu", .en: "Total Income"],
            "total_expense": [.vi: "Tổng chi", .en: "Total Expense"],
            "net_cashflow": [.vi: "Dòng tiền ròng", .en: "Net Cashflow"],

            // Filters & Search
            "all_time": [.vi: "Tất cả thời gian", .en: "All Time"],
            "today": [.vi: "Hôm nay", .en: "Today"],
            "this_week": [.vi: "Tuần này", .en: "This Week"],
            "this_month": [.vi: "Tháng này", .en: "This Month"],
            "this_year": [.vi: "Năm nay", .en: "This Year"],
            "custom_time": [.vi: "Tuỳ chọn thời gian", .en: "Custom Time"],
            "specific_date": [.vi: "Ngày cụ thể", .en: "Specific Date"],
            "specific_month": [.vi: "Tháng cụ thể", .en: "Specific Month"],
            "specific_year": [.vi: "Năm cụ thể", .en: "Specific Year"],
            "date_range": [.vi: "Khoảng thời gian", .en: "Date Range"],
            "from_date": [.vi: "Từ ngày", .en: "From"],
            "to_date": [.vi: "Đến ngày", .en: "To"],
            "apply": [.vi: "Áp dụng", .en: "Apply"],
            "all_categories": [.vi: "Tất cả danh mục", .en: "All Categories"],
            "search_placeholder": [.vi: "Tìm ghi chú, danh mục, số tiền...", .en: "Search note, category, amount..."],
            "view_mode": [.vi: "Kiểu hiển thị", .en: "View Mode"],
            "view_waterfall": [.vi: "Thẻ", .en: "Cards"],
            "view_list": [.vi: "Danh sách", .en: "List"],

            // Dashboard
            "no_transactions": [.vi: "Chưa có giao dịch nào. Bấm \"+\" hoặc chụp ảnh hoá đơn để thêm mới.", .en: "No transactions yet. Tap \"+\" or capture a receipt to add one."],
            "no_expenses": [.vi: "Chưa có giao dịch nào. Bấm \"+\" hoặc chụp ảnh hoá đơn để thêm mới.", .en: "No transactions yet. Tap \"+\" or capture a receipt to add one."],
            "no_matching_transactions": [.vi: "Không tìm thấy giao dịch phù hợp với bộ lọc hiện tại.", .en: "No transactions match the current filters."],
            "delete_confirm": [.vi: "Xoá giao dịch này?", .en: "Delete this transaction?"],
            "delete": [.vi: "Xoá", .en: "Delete"],
            "cancel": [.vi: "Huỷ", .en: "Cancel"],
            "save": [.vi: "Lưu", .en: "Save"],
            "done": [.vi: "Xong", .en: "Done"],
            "edit": [.vi: "Sửa", .en: "Edit"],
            "close": [.vi: "Đóng", .en: "Close"],

            // Add / Edit Transaction
            "add_photo": [.vi: "Thêm ảnh / hoá đơn (tuỳ chọn)", .en: "Add Photo / Receipt (Optional)"],
            "ai_auto_extract": [.vi: "MDaily AI tự động trích xuất hoá đơn & chuyển khoản", .en: "MDaily AI auto-extracts receipts & transfers"],
            "take_photo": [.vi: "Chụp hoặc chọn ảnh hoá đơn", .en: "Capture or choose receipt photo"],
            "drop_receipt_here": [.vi: "Kéo thả ảnh hoá đơn vào đây hoặc chọn tệp", .en: "Drop receipt image here or choose file"],
            "import_from_files": [.vi: "Chọn từ tệp", .en: "Choose File"],
            "camera_unavailable": [.vi: "Camera không khả dụng trên thiết bị này. Vui lòng chọn ảnh từ thư viện hoặc tệp.", .en: "Camera is unavailable on this device. Please pick a photo from library or files."],
            "amount": [.vi: "Số tiền", .en: "Amount"],
            "category": [.vi: "Danh mục", .en: "Category"],
            "add_new_category": [.vi: "Thêm danh mục mới", .en: "Add new category"],
            "new_cat_placeholder": [.vi: "Tên danh mục mới...", .en: "New category name..."],
            "note": [.vi: "Ghi chú / Mô tả", .en: "Note / Description"],
            "note_placeholder": [.vi: "Nhập ghi chú...", .en: "Enter note..."],
            "save_transaction": [.vi: "Lưu giao dịch", .en: "Save Transaction"],
            "save_expense": [.vi: "Lưu giao dịch", .en: "Save Transaction"],
            "invalid_amount": [.vi: "Vui lòng nhập số tiền hợp lệ!", .en: "Please enter a valid amount!"],

            // Detail
            "transaction_details": [.vi: "Chi tiết giao dịch", .en: "Transaction Details"],
            "expense_details": [.vi: "Chi tiết giao dịch", .en: "Transaction Details"],
            "edit_transaction": [.vi: "Chỉnh sửa giao dịch", .en: "Edit Transaction"],
            "edit_expense": [.vi: "Chỉnh sửa giao dịch", .en: "Edit Transaction"],
            "expense_amount": [.vi: "Số tiền", .en: "Amount"],
            "time": [.vi: "Thời gian", .en: "Time"],
            "date": [.vi: "Thời gian", .en: "Time"],
            "no_note": [.vi: "Không có ghi chú", .en: "No note"],
            "delete_this_transaction": [.vi: "Xoá giao dịch này", .en: "Delete this transaction"],
            "delete_this_expense": [.vi: "Xoá giao dịch này", .en: "Delete this transaction"],
            "view_full": [.vi: "Xem đầy đủ", .en: "View Full"],

            // Reports & Categories
            "reports_analytics": [.vi: "Báo cáo Thu & Chi", .en: "Income & Expense"],
            "category_manager": [.vi: "Quản lý danh mục", .en: "Categories"],
            "granularity_day": [.vi: "Ngày", .en: "Day"],
            "granularity_week": [.vi: "Tuần", .en: "Week"],
            "granularity_month": [.vi: "Tháng", .en: "Month"],
            "income_vs_expense": [.vi: "So sánh Thu & Chi", .en: "Income vs Expense"],
            "cashflow_trend": [.vi: "Xu hướng dòng tiền", .en: "Cashflow Trend"],
            "chart_overview": [.vi: "Tổng phân bổ", .en: "Total Allocation"],
            "transactions": [.vi: "giao dịch", .en: "transactions"],
            "categories_count": [.vi: "danh mục", .en: "categories"],
            "no_data": [.vi: "Chưa có dữ liệu giao dịch trong khoảng thời gian này", .en: "No transaction data for this time period"],
            "category_breakdown": [.vi: "Chi tiết theo danh mục", .en: "Category Breakdown"],
            "create_category": [.vi: "Tạo danh mục mới", .en: "Create New Category"],
            "rename_category": [.vi: "Đổi tên danh mục", .en: "Rename Category"],
            "cat_placeholder": [.vi: "Nhập tên danh mục...", .en: "Enter category name..."],
            "delete_cat_confirm": [.vi: "Bạn chắc chắn muốn xoá danh mục này?", .en: "Are you sure you want to delete this category?"],

            // Settings
            "apple_intelligence": [.vi: "MDaily AI", .en: "MDaily AI"],
            "status": [.vi: "Mô hình", .en: "Model"],
            "available": [.vi: "Khả dụng", .en: "Available"],
            "unavailable": [.vi: "Không khả dụng", .en: "Unavailable"],
            "auto_extract": [.vi: "Tự động nhận diện ảnh", .en: "Auto Image Recognition"],
            "auto_extract_desc": [.vi: "Trích xuất hoá đơn khi chụp hoặc chọn ảnh", .en: "Extract receipts when capturing or picking photos"],
            "ai_chat": [.vi: "AI Chat", .en: "AI Chat"],
            "ai_chat_desc": [.vi: "Trò chuyện với MDaily AI trợ lý tài chính", .en: "Chat with MDaily AI financial assistant"],
            "ui_options": [.vi: "Giao diện, Ngôn ngữ & Tiền tệ", .en: "Appearance, Language & Currency"],
            "language": [.vi: "Ngôn ngữ", .en: "Language"],
            "language_desc": [.vi: "Ngôn ngữ hiển thị trong ứng dụng", .en: "Display language of the app"],
            "currency": [.vi: "Đơn vị tiền tệ", .en: "Currency"],
            "currency_desc": [.vi: "Đơn vị tiền tệ hiển thị trong ứng dụng", .en: "Display currency throughout the app"],
            "default_view_mode": [.vi: "Hiển thị mặc định", .en: "Default Dashboard View"],
            "data_management": [.vi: "Quản lý dữ liệu", .en: "Data Management"],
            "delete_all_data": [.vi: "Xoá toàn bộ dữ liệu", .en: "Clear All Data"],
            "delete_all_desc": [.vi: "Xoá tất cả giao dịch đã lưu", .en: "Permanently remove all recorded transactions"],
            "delete_data_btn": [.vi: "Xoá dữ liệu", .en: "Clear Data"],
            "delete_confirm_all": [.vi: "Bạn chắc chắn muốn xoá toàn bộ dữ liệu giao dịch?", .en: "Are you sure you want to clear all transaction data?"],
            "app_info": [.vi: "Thông tin ứng dụng", .en: "About App"],
            "app_version": [.vi: "v3.0 — MDaily Native (macOS 26 & iOS 26)", .en: "v3.0 — MDaily Native (macOS 26 & iOS 26)"],

            // Adaptive Layout & iPhone Duo
            "adaptive_layout": [.vi: "Bố cục thích ứng & Thiết bị", .en: "Adaptive Layout & Device"],
            "detected_device": [.vi: "Thiết bị nhận diện", .en: "Detected Device"],
            "layout_override": [.vi: "Xem trước bố cục", .en: "Layout Preview"],
            "layout_auto": [.vi: "Tự động", .en: "Automatic"],
            "layout_duo_folded": [.vi: "iPhone Duo (Gập)", .en: "iPhone Duo (Folded)"],
            "layout_duo_unfolded": [.vi: "iPhone Duo (Mở)", .en: "iPhone Duo (Unfolded)"],
            "layout_standard_phone": [.vi: "iPhone tiêu chuẩn", .en: "Standard iPhone"],
            "layout_pad": [.vi: "iPad", .en: "iPad"],
            "layout_mac": [.vi: "Mac", .en: "Mac"],

            // Chatbot
            "financial_assistant": [.vi: "Trợ lý tài chính trên thiết bị", .en: "On-Device Financial Assistant"],
            "clear_chat": [.vi: "Xoá đoạn chat", .en: "Clear Chat"],
            "clear_chat_confirm_title": [.vi: "Xoá lịch sử chat?", .en: "Clear chat history?"],
            "clear_chat_confirm_desc": [.vi: "Hành động này sẽ xoá sạch cuộc hội thoại hiện tại.", .en: "This will permanently delete all messages in the current conversation."],
            "type_message": [.vi: "Hỏi AI về thu chi của bạn...", .en: "Ask AI about your income & spending..."],
            "send": [.vi: "Gửi", .en: "Send"],
            "ai_thinking": [.vi: "MDaily AI đang suy nghĩ...", .en: "MDaily AI is thinking..."],

            // General helpers
            "data_cleared": [.vi: "Đã xoá dữ liệu", .en: "Data Cleared"],
            "delete_all_confirm_message": [.vi: "Toàn bộ giao dịch và dữ liệu của bạn sẽ bị xoá hoàn toàn.", .en: "All your transactions and data will be permanently deleted."],
            "ai_recognizing": [.vi: "AI đang nhận diện...", .en: "AI recognizing..."],
            "add_expense_photo": [.vi: "Thêm ảnh giao dịch", .en: "Add transaction photo"],
            "take_photo_camera": [.vi: "Chụp ảnh từ Máy ảnh", .en: "Take Photo"],
            "choose_from_library": [.vi: "Chọn từ Thư viện ảnh", .en: "Choose from Library"],
            "chat_button": [.vi: "Trò chuyện", .en: "Chat"],
            "ai_recognized_by": [.vi: "Nhận diện bởi AI", .en: "Recognized by AI"],
            "app_title": [.vi: "MDaily — Quản Lý Thu Chi", .en: "MDaily — Income & Expense Manager"],

            // Appearance mode
            "appearance": [.vi: "Giao diện", .en: "Appearance"],
            "appearance_desc": [.vi: "Chế độ giao diện sáng, tối hoặc theo hệ thống", .en: "Light, dark, or system appearance mode"],
            "appearance_light": [.vi: "Sáng", .en: "Light"],
            "appearance_dark": [.vi: "Tối", .en: "Dark"],
            "appearance_system": [.vi: "Hệ thống", .en: "System"],

            // Recurring reminders
            "recurring_reminder": [.vi: "Nhắc định kỳ", .en: "Recurring Reminder"],
            "recurring_reminder_desc": [.vi: "Tạo nhắc nhở thu/chi định kỳ tự động", .en: "Create automated recurring reminders"],
            "reminder_date": [.vi: "Ngày nhắc", .en: "Reminder Date"],
            "repeat_interval": [.vi: "Lặp lại", .en: "Repeat"],
            "view_details": [.vi: "Xem chi tiết", .en: "View Details"],
            "share_image": [.vi: "Chia sẻ ảnh", .en: "Share Image"],

            // Bonjour LAN Sync & JSON Backup
            "bonjour_sync": [.vi: "Đồng bộ LAN (Bonjour)", .en: "Bonjour LAN Sync"],
            "bonjour_sync_desc": [.vi: "Tự động tìm Mac / iPhone / iPad cùng mạng Wi-Fi để đồng bộ 1 chạm", .en: "Automatically discover nearby Mac / iPhone / iPad on Wi-Fi for 1-tap sync"],
            "nearby_devices": [.vi: "Thiết bị gần đây", .en: "Nearby Devices"],
            "searching_peers": [.vi: "Đang quét thiết bị trên mạng LAN...", .en: "Scanning local network for devices..."],
            "no_peers_found": [.vi: "Chưa thấy thiết bị MDaily nào khác trên cùng mạng Wi-Fi.", .en: "No other MDaily devices found on the same Wi-Fi network yet."],
            "refresh_peers": [.vi: "Quét lại", .en: "Refresh"],
            "last_synced": [.vi: "Đồng bộ lần cuối", .en: "Last Synced"],
            "export_json": [.vi: "Xuất bản sao lưu JSON", .en: "Export JSON Backup"],
            "import_json": [.vi: "Nhập bản sao lưu JSON", .en: "Import JSON Backup"],
            "cloud_sync": [.vi: "Sao lưu & Khôi phục JSON", .en: "JSON Backup & Restore"],
            "cloud_sync_desc": [.vi: "Xuất hoặc nhập tệp JSON qua iCloud Drive / Finder / Files", .en: "Export or import JSON backups via iCloud Drive / Finder / Files"],
            "sync_connected": [.vi: "Đã kết nối", .en: "Connected"],
            "sync_now": [.vi: "Đồng bộ ngay", .en: "Sync Now"],
            "syncing": [.vi: "Đang đồng bộ...", .en: "Syncing..."],
            "sync_success": [.vi: "Đồng bộ thành công!", .en: "Sync successful!"],
            "sync_error": [.vi: "Lỗi kết nối đồng bộ", .en: "Sync connection failed"]
        ]

        return dict[key]?[lang] ?? dict[key]?[.vi] ?? key
    }
}
