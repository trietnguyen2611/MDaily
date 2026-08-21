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
    @State private var editingExpense: Expense? = nil
    @State private var capturedPhotoData: Data? = nil
    @State private var showCameraPicker: Bool = false
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
                            onSelectExpense: { selectedExpense = $0 },
                            onEditExpense: { expense in
                                editingExpense = expense
                            },
                            onShareExpense: { expense in
                                shareExpenseCard(expense)
                            }
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

            // 3. Floating Bottom Ambient Gradient Fade
            LinearGradient(
                stops: [
                    .init(color: Color.clear, location: 0.0),
                    .init(color: (colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)).opacity(0.80), location: 0.60),
                    .init(color: (colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 90)
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .bottom)

            // 4. Floating Bottom Dock
            LiquidGlassDock(
                activeTab: $activeTab,
                onQuickPhotoCaptured: { photoData in
                    self.capturedPhotoData = photoData
                },
                isKeyboardActive: isKeyboardVisible,
                showCameraPicker: $showCameraPicker
            )
            .offset(y: 12)
            
            // 5. Quick Camera Overlay (Floats directly over app layout)
            if showCameraPicker {
                QuickCameraView(
                    store: store,
                    onPhotoCaptured: { data in
                        self.capturedPhotoData = data
                        self.activeTab = .addExpense
                        self.showCameraPicker = false
                    },
                    onDismiss: {
                        self.showCameraPicker = false
                    }
                )
                .zIndex(10)
            }
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
        .sheet(item: $editingExpense) { exp in
            ExpenseDetailSheet(
                store: store,
                expense: exp,
                startInEditMode: true,
                onClose: { editingExpense = nil }
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
        .onReceive(NotificationCenter.default.publisher(for: .handleQuickAction)) { notification in
            guard let actionType = notification.object as? String else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                switch actionType {
                case "org.mdaily.app.quickAdd":
                    activeTab = .addExpense
                case "org.mdaily.app.quickCamera":
                    activeTab = .addExpense
                    showCameraPicker = true
                case "org.mdaily.app.quickReports":
                    activeTab = .reports
                case "org.mdaily.app.quickAIChat":
                    showAiChat = true
                default:
                    break
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openExpenseDetail)) { notification in
            guard let expenseIdStr = notification.object as? String,
                  let expenseId = UUID(uuidString: expenseIdStr) else { return }
            if let expense = store.expenses.first(where: { $0.id == expenseId }) {
                // Instantly open the detail sheet
                self.selectedExpense = expense
            }
        }
    }

    // MARK: - Share Expense Card
    private func shareExpenseCard(_ expense: Expense) {
        let renderer = ImageRenderer(content: ShareCardView(expense: expense, store: store))
        renderer.scale = UIScreen.main.scale

        if let uiImage = renderer.uiImage {
            let activityVC = UIActivityViewController(activityItems: [uiImage], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
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
                
                if activeTab == .dashboard {
                    Button {
                        showAiChat = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .bold))
                            Text("MDaily AI")
                                .font(.appFont(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color(red: 0.5, green: 0, blue: 0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
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

// MARK: - Share Card View (rendered as image for sharing)
private struct ShareCardView: View {
    let expense: Expense
    let store: ExpenseStore

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                Text("MDaily")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(store.categoryLabel(for: expense.category))
                    .font(.system(size: 18, weight: .bold, design: .rounded))

                Text(store.formatCurrency(expense.amount))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)

                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }

                if let photoData = expense.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.vertical, 4)
                }

                let formatter = DateFormatter()
                Text({
                    formatter.dateFormat = "HH:mm dd/MM/yyyy"
                    return formatter.string(from: expense.date)
                }())
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .frame(width: 320)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

public struct SplashScreenView: View {
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme
    
    public var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color.black : Color(UIColor.systemBackground))
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Icon using new Logo asset
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    .scaleEffect(isAnimating ? 1.0 : 0.6)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                // Text
                Text("MDaily")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0.8)) {
                isAnimating = true
            }
        }
    }
}
