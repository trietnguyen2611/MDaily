// Language & Currency Service for MDaily Desktop
export type Language = 'vi' | 'en'
export type Currency = 'vnd' | 'usd' | 'eur' | 'jpy' | 'gbp'

const LANG_KEY = 'mdaily_lang'
const CURRENCY_KEY = 'mdaily_currency'

export const getLanguage = (): Language => {
  const saved = localStorage.getItem(LANG_KEY)
  if (saved === 'en' || saved === 'vi') return saved
  return 'vi'
}

export const setLanguage = (lang: Language) => {
  localStorage.setItem(LANG_KEY, lang)
  window.dispatchEvent(new CustomEvent('mdaily_settings_change', { detail: { type: 'language', value: lang } }))
}

export const getCurrency = (): Currency => {
  const saved = localStorage.getItem(CURRENCY_KEY)
  if (saved && ['vnd', 'usd', 'eur', 'jpy', 'gbp'].includes(saved)) {
    return saved as Currency
  }
  return 'vnd'
}

export const setCurrency = (currency: Currency) => {
  localStorage.setItem(CURRENCY_KEY, currency)
  window.dispatchEvent(new CustomEvent('mdaily_settings_change', { detail: { type: 'currency', value: currency } }))
}

export const getCurrencySymbol = (curr?: Currency): string => {
  const c = curr || getCurrency()
  switch (c) {
    case 'usd': return '$'
    case 'eur': return '€'
    case 'jpy': return '¥'
    case 'gbp': return '£'
    case 'vnd':
    default: return 'đ'
  }
}

export const formatCurrency = (amount: number, curr?: Currency): string => {
  const c = curr || getCurrency()
  switch (c) {
    case 'usd':
      return `$${amount.toLocaleString('en-US')}`
    case 'eur':
      return `€${amount.toLocaleString('de-DE')}`
    case 'jpy':
      return `¥${amount.toLocaleString('ja-JP')}`
    case 'gbp':
      return `£${amount.toLocaleString('en-GB')}`
    case 'vnd':
    default:
      return `${amount.toLocaleString('vi-VN')} đ`
  }
}

export const TRANSLATIONS = {
  vi: {
    // Tabs & Header
    tab_dashboard: 'Tổng quan',
    tab_add_expense: 'Thêm chi tiêu',
    tab_reports: 'Phân loại',
    tab_settings: 'Cài đặt',
    mdaily_ai: 'MDaily AI',

    // Filters
    all_time: 'Tất cả thời gian',
    today: 'Hôm nay',
    this_week: 'Tuần này',
    this_month: 'Tháng này',
    this_year: 'Năm nay',
    custom_day: 'Chọn ngày cụ thể...',
    custom_month: 'Chọn tháng cụ thể...',
    custom_year: 'Chọn năm cụ thể...',
    custom_range: 'Khoảng thời gian...',
    all_categories: 'Tất cả danh mục',
    from_date: 'Từ ngày',
    to_date: 'Đến ngày',
    year_placeholder: 'Năm',

    // Dashboard
    no_expenses: 'Chưa có chi tiêu nào. Bấm "Thêm chi tiêu" để tạo mới.',
    delete_expense_confirm: 'Bạn chắc chắn muốn xoá khoản chi tiêu này?',
    delete: 'Xoá',
    ai_badge: 'AI',

    // Add Expense
    add_photo_optional: 'Thêm ảnh hoá đơn (tùy chọn)',
    processing: 'Đang xử lý...',
    take_photo_sub: 'Kéo thả hoặc chọn ảnh hoá đơn / đồ vật',
    ai_auto_sub: '✨ AI sẽ tự động nhận diện hoá đơn',
    ai_extracting: 'AI đang nhận diện...',
    amount_label: 'Số tiền',
    amount_placeholder: 'Ví dụ: 50,000',
    category_label: 'Danh mục',
    add_category_btn: 'Thêm danh mục mới',
    new_cat_placeholder: 'Tên danh mục mới...',
    add_btn: 'Thêm',
    note_label: 'Ghi chú / Tên đồ vật',
    note_placeholder: 'Nhập ghi chú...',
    note_ai_placeholder: 'AI sẽ tự điền khi có ảnh...',
    cancel: 'Huỷ',
    save_expense: 'Lưu chi tiêu',
    amount_invalid: 'Vui lòng nhập số tiền hợp lệ!',
    heic_error: 'Không thể chuyển đổi ảnh HEIC. Vui lòng chọn JPG/PNG.',

    // Reports / Categories
    chart_overview: 'Tổng phân bổ',
    transactions: 'giao dịch',
    categories_count: 'danh mục',
    no_data_period: 'Chưa có dữ liệu chi tiêu trong khoảng thời gian này',
    category_breakdown: 'Chi tiết theo danh mục',
    add_category: 'Thêm danh mục',
    create_category: 'Tạo danh mục mới',
    cat_placeholder: 'Nhập tên danh mục (ví dụ: Giải trí)...',
    edit_category_title: 'Đổi tên danh mục',
    save: 'Lưu',
    delete_category_confirm: 'Bạn chắc chắn muốn xoá danh mục này?',

    // Expense Detail Modal
    expense_details: 'Chi tiết chi tiêu',
    edit_expense: 'Chỉnh sửa chi tiêu',
    expense_amount: 'Số tiền chi tiêu',
    time: 'Thời gian',
    note: 'Ghi chú',
    no_note: 'Không có ghi chú',
    delete_this_expense: 'Xoá chi tiêu này',
    done: 'Xong',
    edit: 'Sửa',
    expand_photo: 'Xem đầy đủ',

    // Settings
    ai_local_status: 'Trạng thái AI local',
    ai_local_desc_connected: 'Đã kết nối máy chủ AI',
    ai_local_desc_disconnected: 'Cần kết nối Jan, LM Studio hoặc Ollama',
    ai_ready: 'Sẵn sàng',
    ai_not_ready: 'Chưa sẵn sàng',
    auto_extract: 'Tự động nhận diện ảnh',
    auto_extract_desc: 'Tự điền số tiền và danh mục từ ảnh hoá đơn',
    auto_extract_req: 'Cần kết nối AI Server',
    ai_chat: 'MDaily AI Chat',
    ai_chat_desc: 'Mở trợ lý AI từ thanh công cụ',
    ui_options: 'Giao diện & Tuỳ chọn',
    language: 'Ngôn ngữ',
    language_desc: 'Ngôn ngữ hiển thị trong ứng dụng',
    currency: 'Đơn vị tiền tệ',
    currency_desc: 'Đơn vị tiền tệ hiển thị trong ứng dụng',
    data_management: 'Quản lý dữ liệu',
    delete_all_data: 'Xoá toàn bộ dữ liệu',
    delete_all_desc: 'Xoá tất cả chi tiêu đã lưu trong cơ sở dữ liệu',
    delete_data_btn: 'Xoá dữ liệu',
    deleting: 'Đang xoá...',
    deleted_success: 'Đã xoá toàn bộ dữ liệu chi tiêu.',
    delete_confirm_all: 'Bạn chắc chắn muốn xoá toàn bộ dữ liệu chi tiêu?',
    app_info: 'Thông tin ứng dụng',
    app_version_desc: 'v2.4 — Native AI & Wi-Fi Sync',

    // Wi-Fi Sync
    wifi_sync: 'Đồng bộ Wi-Fi (QR Code)',
    wifi_sync_desc: 'Quét mã QR từ điện thoại để đồng bộ dữ liệu hai chiều',
    sync_server_running: 'Máy chủ đồng bộ đang chạy trên mạng Wi-Fi cục bộ',
    sync_qr_instruction: 'Mở MDaily trên điện thoại > Cài đặt > Đồng bộ Wi-Fi > Quét mã QR dưới đây:',
    sync_server_ip: 'Địa chỉ IP máy tính',
    sync_server_port: 'Cổng (Port)',
    sync_server_pin: 'Mã PIN bảo mật',
    sync_copy_ip: 'Sao chép IP',
    sync_refresh_token: 'Đổi mã kết nối mới',
    sync_last_event: 'Trạng thái đồng bộ gần nhất',
    sync_ready_waiting: 'Đang chờ điện thoại quét mã QR để kết nối...',

    // Chatbot
    ai_assistant_title: 'MDaily AI',
    financial_assistant: 'Trợ lý tài chính thông minh',
    clear_chat: 'Xoá đoạn chat',
    quick_suggestions: 'Gợi ý nhanh',
    type_message_placeholder: 'Hỏi AI về chi tiêu của bạn...',
    send: 'Gửi',
    ai_thinking: 'AI đang phân tích...'
  },
  en: {
    // Tabs & Header
    tab_dashboard: 'Overview',
    tab_add_expense: 'Add Expense',
    tab_reports: 'Categories',
    tab_settings: 'Settings',
    mdaily_ai: 'MDaily AI',

    // Filters
    all_time: 'All Time',
    today: 'Today',
    this_week: 'This Week',
    this_month: 'This Month',
    this_year: 'This Year',
    custom_day: 'Specific Day...',
    custom_month: 'Specific Month...',
    custom_year: 'Specific Year...',
    custom_range: 'Date Range...',
    all_categories: 'All Categories',
    from_date: 'From Date',
    to_date: 'To Date',
    year_placeholder: 'Year',

    // Dashboard
    no_expenses: 'No expenses yet. Click "Add Expense" to create one.',
    delete_expense_confirm: 'Are you sure you want to delete this expense?',
    delete: 'Delete',
    ai_badge: 'AI',

    // Add Expense
    add_photo_optional: 'Add Receipt Photo (Optional)',
    processing: 'Processing...',
    take_photo_sub: 'Drag & drop or select receipt/item image',
    ai_auto_sub: '✨ AI will auto-extract receipt details',
    ai_extracting: 'AI is analyzing...',
    amount_label: 'Amount',
    amount_placeholder: 'e.g. 50,000',
    category_label: 'Category',
    add_category_btn: 'Add new category',
    new_cat_placeholder: 'New category name...',
    add_btn: 'Add',
    note_label: 'Note / Item Name',
    note_placeholder: 'Enter note...',
    note_ai_placeholder: 'AI will fill in when photo is added...',
    cancel: 'Cancel',
    save_expense: 'Save Expense',
    amount_invalid: 'Please enter a valid amount!',
    heic_error: 'Unable to convert HEIC image. Please select JPG/PNG.',

    // Reports / Categories
    chart_overview: 'Total Allocation',
    transactions: 'transactions',
    categories_count: 'categories',
    no_data_period: 'No expense data for this time period',
    category_breakdown: 'Category Breakdown',
    add_category: 'Add Category',
    create_category: 'Create New Category',
    cat_placeholder: 'Enter category name (e.g. Entertainment)...',
    edit_category_title: 'Rename Category',
    save: 'Save',
    delete_category_confirm: 'Are you sure you want to delete this category?',

    // Expense Detail Modal
    expense_details: 'Expense Details',
    edit_expense: 'Edit Expense',
    expense_amount: 'Expense Amount',
    time: 'Time',
    note: 'Note',
    no_note: 'No note',
    delete_this_expense: 'Delete this expense',
    done: 'Done',
    edit: 'Edit',
    expand_photo: 'View Full',

    // Settings
    ai_local_status: 'Local AI Status',
    ai_local_desc_connected: 'Connected to local AI server',
    ai_local_desc_disconnected: 'Connect Jan, LM Studio, or Ollama',
    ai_ready: 'Ready',
    ai_not_ready: 'Not Ready',
    auto_extract: 'Auto Image Recognition',
    auto_extract_desc: 'Extract receipts & items when adding photos',
    auto_extract_req: 'Requires AI Server',
    ai_chat: 'MDaily AI Chat',
    ai_chat_desc: 'Open AI financial assistant from top bar',
    ui_options: 'Appearance & Options',
    language: 'Language',
    language_desc: 'Display language of the app',
    currency: 'Currency',
    currency_desc: 'Display currency throughout the app',
    data_management: 'Data Management',
    delete_all_data: 'Clear All Data',
    delete_all_desc: 'Permanently remove all recorded expenses',
    delete_data_btn: 'Clear Data',
    deleting: 'Clearing...',
    deleted_success: 'All expense data has been cleared.',
    delete_confirm_all: 'Are you sure you want to clear all expense data?',
    app_info: 'About App',
    app_version_desc: 'v2.4 — Native AI & Wi-Fi Sync',

    // Wi-Fi Sync
    wifi_sync: 'Wi-Fi Sync (QR Code)',
    wifi_sync_desc: 'Scan QR code from phone to sync data bidirectionally',
    sync_server_running: 'Sync server is running on your local Wi-Fi',
    sync_qr_instruction: 'Open MDaily on your phone > Settings > Wi-Fi Sync > Scan this QR Code:',
    sync_server_ip: 'Computer IP Address',
    sync_server_port: 'Port',
    sync_server_pin: 'Security PIN',
    sync_copy_ip: 'Copy IP',
    sync_refresh_token: 'Generate New PIN',
    sync_last_event: 'Last Sync Status',
    sync_ready_waiting: 'Waiting for phone to scan QR code and connect...',

    // Chatbot
    ai_assistant_title: 'MDaily AI',
    financial_assistant: 'Smart Financial Assistant',
    clear_chat: 'Clear Chat',
    quick_suggestions: 'Quick Prompts',
    type_message_placeholder: 'Ask AI about your spending...',
    send: 'Send',
    ai_thinking: 'AI is analyzing...'
  }
}

export const t = (key: keyof typeof TRANSLATIONS['vi'], lang?: Language): string => {
  const l = lang || getLanguage()
  return TRANSLATIONS[l]?.[key] || TRANSLATIONS['vi'][key] || key
}
