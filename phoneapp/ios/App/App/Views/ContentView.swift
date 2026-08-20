import SwiftUI

public enum TimePreset: String, CaseIterable, Identifiable, Sendable {
    case all = "all"
    case today = "today"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case thisYear = "this_year"

    public var id: String { rawValue }

    public func title(lang: Language) -> String {
        switch self {
        case .all: return lang == .en ? "All Time" : "Tất cả thời gian"
        case .today: return lang == .en ? "Today" : "Hôm nay"
        case .thisWeek: return lang == .en ? "This Week" : "Tuần này"
        case .thisMonth: return lang == .en ? "This Month" : "Tháng này"
        case .thisYear: return lang == .en ? "This Year" : "Năm nay"
        }
    }
}

public enum TimeFilterMode: Equatable {
    case preset(TimePreset)
    case specificDate(Date)
    case specificMonth(month: Int, year: Int)
    case specificYear(year: Int)
    case dateRange(from: Date, to: Date)

    public func displayTitle(lang: Language) -> String {
        let formatter = DateFormatter()
        switch self {
        case .preset(let preset):
            return preset.title(lang: lang)
        case .specificDate(let date):
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: date)
        case .specificMonth(let month, let year):
            return lang == .en ? "Month \(month)/\(year)" : "Tháng \(month)/\(year)"
        case .specificYear(let year):
            return lang == .en ? "Year \(year)" : "Năm \(year)"
        case .dateRange(let from, let to):
            formatter.dateFormat = "dd/MM"
            return "\(formatter.string(from: from)) - \(formatter.string(from: to))"
        }
    }
}

@MainActor
public struct ContentView: View {
    @StateObject private var store = ExpenseStore()
    @State private var activeTab: AppTab = .dashboard
    @State private var timeFilterMode: TimeFilterMode = .preset(.all)
    @State private var categoryFilter: String = "all"
    @State private var showAiChat: Bool = false
    @State private var showCustomTimeFilterSheet: Bool = false
    @State private var customTimeFilterTab: CustomFilterTab = .specificDate
    @State private var selectedExpense: Expense? = nil
    @State private var capturedPhotoData: Data? = nil
    @State private var showCameraFromQuickAction: Bool = false
    @State private var isKeyboardVisible: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    private var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        return store.expenses.filter { expense in
            if categoryFilter != "all" && expense.category != categoryFilter {
                return false
            }

            switch timeFilterMode {
            case .preset(let preset):
                switch preset {
                case .all:
                    return true
                case .today:
                    return calendar.isDateInToday(expense.date)
                case .thisWeek:
                    return calendar.isDate(expense.date, equalTo: Date(), toGranularity: .weekOfYear)
                case .thisMonth:
                    return calendar.isDate(expense.date, equalTo: Date(), toGranularity: .month)
                case .thisYear:
                    return calendar.isDate(expense.date, equalTo: Date(), toGranularity: .year)
                }
            case .specificDate(let targetDate):
                return calendar.isDate(expense.date, inSameDayAs: targetDate)
            case .specificMonth(let month, let year):
                let comps = calendar.dateComponents([.year, .month], from: expense.date)
                return comps.year == year && comps.month == month
            case .specificYear(let year):
                let comps = calendar.dateComponents([.year], from: expense.date)
                return comps.year == year
            case .dateRange(let fromDate, let toDate):
                let startOfDay = calendar.startOfDay(for: fromDate)
                let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: toDate) ?? toDate
                return expense.date >= startOfDay && expense.date <= endOfDay
            }
        }
    }

    private var pageTitle: String {
        switch activeTab {
        case .dashboard: return store.t("tab_dashboard")
        case .addExpense: return store.t("tab_add_expense")
        case .reports: return store.t("tab_reports")
        case .settings: return store.t("tab_settings")
        }
    }

    /// Computed preferred color scheme based on store's appearance setting
    private var preferredColorScheme: ColorScheme? {
        switch store.appearanceMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Pitch Black / Grouped System Background Canvas
            AmbientBackgroundView()

            // 2. Main Content
            VStack(spacing: 0) {
                // Top Header (Fixed at top)
                topHeader

                // Main Tab Content View
                Group {
                    switch activeTab {
                    case .dashboard:
                        DashboardView(
                            store: store,
                            expenses: filteredExpenses,
                            onSelectExpense: { selectedExpense = $0 }
                        )
                    case .addExpense:
                        AddExpenseView(
                            store: store,
                            initialPhotoData: capturedPhotoData,
                            onSave: {
                                capturedPhotoData = nil
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                    activeTab = .dashboard
                                }
                            },
                            onCancel: {
                                capturedPhotoData = nil
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                    activeTab = .dashboard
                                }
                            }
                        )
                    case .reports:
                        ReportsView(
                            store: store,
                            expenses: filteredExpenses
                        )
                    case .settings:
                        SettingsView(store: store)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // 3. Floating Bottom Blur Fade (frosted glass blur instead of color fade)
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 110)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black.opacity(0.5), location: 0.35),
                                .init(color: .black, location: 0.65),
                                .init(color: .black, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .bottom)

            // 4. Floating Bottom Dock
            LiquidGlassDock(
                activeTab: $activeTab,
                onQuickPhotoCaptured: { photoData in
                    self.capturedPhotoData = photoData
                },
                isKeyboardActive: isKeyboardVisible
            )
        }
        .preferredColorScheme(preferredColorScheme)
        .hideKeyboardOnTap()
        .onChange(of: activeTab) { _, newTab in
            if newTab != .addExpense {
                capturedPhotoData = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isKeyboardVisible = false
            }
        }
        .sheet(item: $selectedExpense) { exp in
            ExpenseDetailSheet(
                store: store,
                expense: exp,
                onClose: { selectedExpense = nil }
            )
        }
        .sheet(isPresented: $showAiChat) {
            ChatbotSheet(
                store: store,
                onClose: { showAiChat = false }
            )
        }
        .sheet(isPresented: $showCustomTimeFilterSheet) {
            CustomTimeFilterSheet(
                store: store,
                currentMode: $timeFilterMode,
                initialTab: customTimeFilterTab,
                onClose: { showCustomTimeFilterSheet = false }
            )
        }
        .sheet(isPresented: $showCameraFromQuickAction) {
            ImagePickerView(sourceType: UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary) { image in
                if let data = image.jpegData(compressionQuality: 0.85) {
                    self.capturedPhotoData = data
                    activeTab = .addExpense
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .handleQuickAction)) { notification in
            guard let actionType = notification.object as? String else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                switch actionType {
                case "org.mdaily.app.quickAdd":
                    activeTab = .addExpense
                case "org.mdaily.app.quickCamera":
                    activeTab = .addExpense
                    showCameraFromQuickAction = true
                case "org.mdaily.app.quickReports":
                    activeTab = .reports
                default:
                    break
                }
            }
        }
    }

    // MARK: - Top Header (Clean Design with Enhanced Time Filters)
    private var topHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(pageTitle)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            // Filter Bar (For Dashboard & Reports)
            if activeTab == .dashboard || activeTab == .reports {
                HStack(spacing: 12) {
                    // 1. Time Filter Dropdown & Advanced Picker
                    Menu {
                        Section(header: Text(store.language == .en ? "Quick Presets" : "Mặc định")) {
                            ForEach(TimePreset.allCases) { preset in
                                Button(preset.title(lang: store.language)) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        timeFilterMode = .preset(preset)
                                    }
                                }
                            }
                        }

                        Section(header: Text(store.language == .en ? "Advanced Filter" : "Tùy chọn thời gian")) {
                            Button {
                                customTimeFilterTab = .specificDate
                                showCustomTimeFilterSheet = true
                            } label: {
                                Label(
                                    store.language == .en ? "Specific Day..." : "Chọn ngày cụ thể...",
                                    systemImage: "calendar.badge.clock"
                                )
                            }

                            Button {
                                customTimeFilterTab = .specificMonth
                                showCustomTimeFilterSheet = true
                            } label: {
                                Label(
                                    store.language == .en ? "Specific Month..." : "Chọn tháng cụ thể...",
                                    systemImage: "calendar"
                                )
                            }

                            Button {
                                customTimeFilterTab = .specificYear
                                showCustomTimeFilterSheet = true
                            } label: {
                                Label(
                                    store.language == .en ? "Specific Year..." : "Chọn năm cụ thể...",
                                    systemImage: "calendar.badge.checkmark"
                                )
                            }

                            Button {
                                customTimeFilterTab = .dateRange
                                showCustomTimeFilterSheet = true
                            } label: {
                                Label(
                                    store.language == .en ? "Date Range..." : "Chọn khoảng thời gian...",
                                    systemImage: "arrow.left.and.right"
                                )
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(timeFilterMode.displayTitle(lang: store.language))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? Color(white: 0.16) : Color(white: 0.90))
                        )
                    }

                    // 2. Category Filter Dropdown
                    Menu {
                        Button(store.t("all_categories")) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                categoryFilter = "all"
                            }
                        }
                        ForEach(store.categories) { cat in
                            Button(cat.localizedLabel(lang: store.language)) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    categoryFilter = cat.id
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(categoryFilter == "all" ? store.t("all_categories") : store.categoryLabel(for: categoryFilter))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? Color(white: 0.16) : Color(white: 0.90))
                        )
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 8)
            }
        }
    }
}
