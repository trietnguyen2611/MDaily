import SwiftUI

public enum TimeFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "all"
    case today = "today"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case thisYear = "this_year"

    public var id: String { rawValue }

    public func title(lang: Language) -> String {
        switch self {
        case .all: return LocalizationService.t("all_time", lang: lang)
        case .today: return LocalizationService.t("today", lang: lang)
        case .thisWeek: return LocalizationService.t("this_week", lang: lang)
        case .thisMonth: return LocalizationService.t("this_month", lang: lang)
        case .thisYear: return LocalizationService.t("this_year", lang: lang)
        }
    }
}

@MainActor
public struct ContentView: View {
    @StateObject private var store = ExpenseStore()
    @State private var activeTab: AppTab = .dashboard
    @State private var timeFilter: TimeFilter = .all
    @State private var categoryFilter: String = "all"
    @State private var showAiChat: Bool = false
    @State private var selectedExpense: Expense? = nil
    @State private var capturedPhotoData: Data? = nil
    @State private var showCameraFromQuickAction: Bool = false

    private var filteredExpenses: [Expense] {
        store.expenses.filter { expense in
            if categoryFilter != "all" && expense.category != categoryFilter {
                return false
            }
            let calendar = Calendar.current
            switch timeFilter {
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

    public var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Ambient Dynamic Atmosphere Canvas
            AmbientBackgroundView()

            // 2. Main Content & Navigation
            VStack(spacing: 0) {
                // Top Liquid Glass Header
                HStack(alignment: .center) {
                    Text(pageTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 6)

                // Filter Bar (For Dashboard & Reports)
                if activeTab == .dashboard || activeTab == .reports {
                    HStack(spacing: 10) {
                        Menu {
                            ForEach(TimeFilter.allCases) { filter in
                                Button(filter.title(lang: store.language)) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        timeFilter = filter
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.blue)
                                Text(timeFilter.title(lang: store.language))
                                    .font(.system(size: 13, weight: .medium))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .liquidGlassPill()
                        }

                        Menu {
                            Button(store.t("all_categories")) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    categoryFilter = "all"
                                }
                            }
                            ForEach(store.categories) { cat in
                                Button(cat.label) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        categoryFilter = cat.id
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.orange)
                                Text(categoryFilter == "all" ? store.t("all_categories") : store.categoryLabel(for: categoryFilter))
                                    .font(.system(size: 13, weight: .medium))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .liquidGlassPill()
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)
                }

                // Main Tab View with Fluid Spring Transition
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

            // Bottom Liquid Glass Dock
            LiquidGlassDock(
                activeTab: $activeTab,
                onQuickPhotoCaptured: { photoData in
                    self.capturedPhotoData = photoData
                }
            )
        }
        .sheet(item: $selectedExpense) { exp in
            ExpenseDetailSheet(
                store: store,
                expense: Binding(
                    get: { selectedExpense },
                    set: { selectedExpense = $0 }
                ),
                onClose: { selectedExpense = nil }
            )
        }
        .sheet(isPresented: $showAiChat) {
            ChatbotSheet(
                store: store,
                onClose: { showAiChat = false }
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
}
