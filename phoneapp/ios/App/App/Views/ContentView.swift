import SwiftUI

public enum TimeFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case today = "today"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case thisYear = "this_year"

    public var id: String { rawValue }

    public func title(for store: ExpenseStore) -> String {
        switch self {
        case .all: return store.t("all_time")
        case .today: return store.t("today")
        case .thisWeek: return store.t("this_week")
        case .thisMonth: return store.t("this_month")
        case .thisYear: return store.t("this_year")
        }
    }
}

public struct ContentView: View {
    @StateObject private var store = ExpenseStore()
    @State private var activeTab: AppTab = .dashboard
    @State private var timeFilter: TimeFilter = .all
    @State private var categoryFilter: String = "all"
    @State private var showAiChat: Bool = false
    @State private var selectedExpense: Expense? = nil
    @State private var capturedPhotoData: Data? = nil

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
            VStack(spacing: 0) {
                // Top Navigation Bar (Liquid Glass Header)
                HStack {
                    Text(pageTitle)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    if store.aiChatEnabled {
                        Button {
                            showAiChat = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.blue)
                                Text("MDaily AI")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .liquidGlassPill()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)

                // Filter Bar (For Dashboard & Reports)
                if activeTab == .dashboard || activeTab == .reports {
                    HStack(spacing: 10) {
                        Menu {
                            ForEach(TimeFilter.allCases) { filter in
                                Button(filter.title(for: store)) {
                                    timeFilter = filter
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(timeFilter.title(for: store))
                                    .font(.system(size: 13, weight: .medium))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .liquidGlassPill()
                        }

                        Menu {
                            Button(store.t("all_categories")) {
                                categoryFilter = "all"
                            }
                            ForEach(store.categories) { cat in
                                Button(cat.label) {
                                    categoryFilter = cat.id
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(categoryFilter == "all" ? store.t("all_categories") : store.categoryLabel(for: categoryFilter))
                                    .font(.system(size: 13, weight: .medium))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .liquidGlassPill()
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }

                // Main Tab Content
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
                                withAnimation { activeTab = .dashboard }
                            },
                            onCancel: {
                                capturedPhotoData = nil
                                withAnimation { activeTab = .dashboard }
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
    }
}
