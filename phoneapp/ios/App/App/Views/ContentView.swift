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
    @State private var isKeyboardVisible: Bool = false

    @Environment(\.colorScheme) private var colorScheme

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

            // 2. Main Content
            VStack(spacing: 0) {
                // Top Liquid Glass Navigation Header
                topLiquidGlassHeader

                // Main Tab Content View with Spring Transitions
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
                },
                isKeyboardActive: isKeyboardVisible
            )
        }
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

    // MARK: - Top Liquid Glass Header (iOS 27 Design)
    private var topLiquidGlassHeader: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                Text(pageTitle)
                    .font(.appLargeTitle)
                    .foregroundColor(.primary)

                Spacer()

                // Top-Right AI Chat Button (Apple Intelligence AFM)
                Button {
                    showAiChat = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("AI")
                            .font(.appFont(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .liquidGlassPill()
                }
                .liquidGlassButton()
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)

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
                                .font(.appFont(size: 12, weight: .semibold))
                                .foregroundColor(.blue)
                            Text(timeFilter.title(lang: store.language))
                                .font(.appFont(size: 13, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.appFont(size: 10, weight: .semibold))
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
                                .font(.appFont(size: 11, weight: .semibold))
                                .foregroundColor(.orange)
                            Text(categoryFilter == "all" ? store.t("all_categories") : store.categoryLabel(for: categoryFilter))
                                .font(.appFont(size: 13, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.appFont(size: 10, weight: .semibold))
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
                .padding(.bottom, 6)
            }
        }
        .padding(.bottom, 4)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.85))
                .overlay {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.02) : Color.white.opacity(0.20))
                }
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.40))
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .top)
        }
    }
}
