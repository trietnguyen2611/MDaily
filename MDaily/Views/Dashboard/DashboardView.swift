import SwiftUI

@MainActor
public struct DashboardView: View {
    @ObservedObject public var store: FinanceStore
    public var transactions: [Transaction]
    @Binding public var searchText: String
    @Binding public var kindFilter: TransactionKindFilter
    @Binding public var timeFilterMode: TimeFilterMode
    @Binding public var categoryFilter: String
    public var layoutProfile: AdaptiveLayoutProfile
    public var onSelectTransaction: (Transaction) -> Void
    public var onEditTransaction: (Transaction) -> Void

    @State private var transactionToDelete: Transaction? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var showCustomTimeSheet: Bool = false
    @FocusState private var isSearchFocused: Bool

    @Environment(\.colorScheme) private var colorScheme

    public init(
        store: FinanceStore,
        transactions: [Transaction],
        searchText: Binding<String>,
        kindFilter: Binding<TransactionKindFilter>,
        timeFilterMode: Binding<TimeFilterMode>,
        categoryFilter: Binding<String>,
        layoutProfile: AdaptiveLayoutProfile,
        onSelectTransaction: @escaping (Transaction) -> Void,
        onEditTransaction: @escaping (Transaction) -> Void
    ) {
        self.store = store
        self.transactions = transactions
        self._searchText = searchText
        self._kindFilter = kindFilter
        self._timeFilterMode = timeFilterMode
        self._categoryFilter = categoryFilter
        self.layoutProfile = layoutProfile
        self.onSelectTransaction = onSelectTransaction
        self.onEditTransaction = onEditTransaction
    }

    private var isEnglish: Bool { store.language == .en }

    private var totalIncome: Double {
        store.totalIncome(in: transactions)
    }

    private var totalExpense: Double {
        store.totalExpense(in: transactions)
    }

    private var netBalance: Double {
        store.netBalance(in: transactions)
    }

    private var horizontalPadding: CGFloat {
        switch layoutProfile {
        case .iPhoneDuoFolded: return 14
        case .standardPhone: return 16
        case .iPhoneDuoUnfolded, .pad, .mac: return 24
        }
    }

    private var isNarrowLayout: Bool {
        layoutProfile == .iPhoneDuoFolded || layoutProfile == .standardPhone
    }

    public var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    balanceSummaryStrip
                    filterAndSearchToolbar
                    contentSection(availableWidth: geo.size.width - horizontalPadding * 2)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, bottomScrollPadding)
            }
            .background(Color.mdailyCanvas.ignoresSafeArea())
        }
        .onReceive(NotificationCenter.default.publisher(for: .mdailyFocusSearch)) { _ in
            isSearchFocused = true
        }
        .sheet(isPresented: $showCustomTimeSheet) {
            CustomTimeFilterSheet(store: store, currentMode: $timeFilterMode) {
                showCustomTimeSheet = false
            }
        }
        .alert(
            isEnglish ? "Delete Transaction?" : "Xoá giao dịch này?",
            isPresented: $showDeleteConfirmation
        ) {
            Button(isEnglish ? "Delete" : "Xoá", role: .destructive) {
                if let tx = transactionToDelete {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        store.deleteTransaction(id: tx.id)
                    }
                    transactionToDelete = nil
                }
            }
            Button(isEnglish ? "Cancel" : "Huỷ", role: .cancel) {
                transactionToDelete = nil
            }
        } message: {
            if let tx = transactionToDelete {
                let label = store.categories.first(where: { $0.id == tx.categoryId })?.localizedLabel(lang: store.language) ?? tx.categoryId
                Text("\(label) · \(TransactionFormatHelper.signedPrefix(for: tx.kind))\(store.formatCurrency(tx.amount))")
            }
        }
    }

    private var bottomScrollPadding: CGFloat {
        switch layoutProfile {
        case .standardPhone: return 104
        case .iPhoneDuoFolded, .iPhoneDuoUnfolded: return 32
        case .pad, .mac: return 32
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(isEnglish ? "Cashflow" : "Thu & Chi")
                    .font(.system(size: isNarrowLayout ? 28 : 34, weight: .semibold))
                    .tracking(-0.37)
                    .foregroundStyle(.primary)

                Text(timeFilterMode.displayTitle(lang: store.language))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(transactions.count) \(isEnglish ? "items" : "mục")")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.mdailyParchment, in: Capsule())
        }
    }

    // MARK: - Balance Summary Strip

    private var balanceSummaryStrip: some View {
        Group {
            if isNarrowLayout {
                VStack(alignment: .leading, spacing: 12) {
                    netBalanceBlock
                    Divider().overlay(Color.mdailyHairline)
                    HStack(spacing: 12) {
                        incomeStatBlock
                        Spacer(minLength: 8)
                        expenseStatBlock
                    }
                }
            } else {
                HStack(spacing: 20) {
                    netBalanceBlock
                    Spacer(minLength: 16)
                    Divider().frame(height: 36).overlay(Color.mdailyHairline)
                    incomeStatBlock
                    Divider().frame(height: 36).overlay(Color.mdailyHairline)
                    expenseStatBlock
                }
            }
        }
        .padding(16)
        .mdailyCard(cornerRadius: 18)
    }

    private var netBalanceBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(isEnglish ? "Net Balance" : "Số dư ròng")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            let prefix = netBalance > 0 ? "+" : (netBalance < 0 ? "−" : "")
            Text("\(prefix)\(store.formatCurrency(abs(netBalance)))")
                .font(.system(size: isNarrowLayout ? 26 : 28, weight: .semibold))
                .tracking(-0.4)
                .monospacedDigit()
                .foregroundStyle(netBalance >= 0 ? Color.mdailyIncomeGreen : (colorScheme == .dark ? Color.white : Color(red: 0.114, green: 0.114, blue: 0.122)))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private var incomeStatBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label {
                Text(isEnglish ? "Income" : "Thu nhập")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "arrow.down.left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mdailyIncomeGreen)
            }

            Text("+\(store.formatCurrency(totalIncome))")
                .font(.system(size: 16, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color.mdailyIncomeGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private var expenseStatBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label {
                Text(isEnglish ? "Expense" : "Chi tiêu")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Text("−\(store.formatCurrency(totalExpense))")
                .font(.system(size: 16, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(colorScheme == .dark ? Color.white : Color(red: 0.114, green: 0.114, blue: 0.122))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    // MARK: - Unified Filter & Search Toolbar

    private var filterAndSearchToolbar: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Search + View Mode Toggle
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)

                    TextField(
                        isEnglish ? "Search notes, categories, amounts…" : "Tìm ghi chú, danh mục, số tiền…",
                        text: $searchText
                    )
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .regular))
                    .focused($isSearchFocused)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(Color.mdailyCardSurface, in: Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.mdailyHairline, lineWidth: 1)
                )

                viewModeToggle
            }

            // Kind segmented pill + Time Menu + Category Menu
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    kindSegmentedControl
                    Spacer(minLength: 6)
                    timeFilterMenu
                    categoryFilterMenu
                }

                VStack(alignment: .leading, spacing: 8) {
                    kindSegmentedControl
                    HStack(spacing: 8) {
                        timeFilterMenu
                        categoryFilterMenu
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var viewModeToggle: some View {
        HStack(spacing: 2) {
            ForEach(DashboardViewMode.allCases) { mode in
                let isSelected = store.dashboardViewMode == mode
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.dashboardViewMode = mode
                    }
                } label: {
                    Image(systemName: mode == .waterfall ? "square.grid.2x2" : "list.bullet")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .frame(width: 34, height: 32)
                        .background(
                            isSelected ? Color.mdailyActionBlue : Color.clear,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode == .waterfall ? (isEnglish ? "Card Grid" : "Thẻ") : (isEnglish ? "Compact List" : "Danh sách"))
            }
        }
        .padding(4)
        .background(Color.mdailyCardSurface, in: Capsule())
        .overlay(
            Capsule().strokeBorder(Color.mdailyHairline, lineWidth: 1)
        )
    }

    private var kindSegmentedControl: some View {
        HStack(spacing: 3) {
            ForEach(TransactionKindFilter.allCases) { filter in
                let isSelected = kindFilter == filter
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        kindFilter = filter
                        // Clear incompatible category filter if switching kind
                        if categoryFilter != "all",
                           let cat = store.categories.first(where: { $0.id == categoryFilter }),
                           (filter == .expense && cat.kind != .expense) || (filter == .income && cat.kind != .income) {
                            categoryFilter = "all"
                        }
                    }
                } label: {
                    Text(filter.title(lang: store.language))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            isSelected ? Color.mdailyActionBlue : Color.clear,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.mdailyCardSurface, in: Capsule())
        .overlay(
            Capsule().strokeBorder(Color.mdailyHairline, lineWidth: 1)
        )
    }

    private var timeFilterMenu: some View {
        Menu {
            ForEach(TimePreset.allCases) { preset in
                Button {
                    timeFilterMode = .preset(preset)
                } label: {
                    HStack {
                        Text(preset.title(lang: store.language))
                        if case .preset(let current) = timeFilterMode, current == preset {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button {
                showCustomTimeSheet = true
            } label: {
                Label(isEnglish ? "Custom Date / Range…" : "Tuỳ chọn ngày / khoảng…", systemImage: "calendar.badge.clock")
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.mdailyActionBlue)
                Text(timeFilterMode.displayTitle(lang: store.language))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.mdailyCardSurface, in: Capsule())
            .overlay(
                Capsule().strokeBorder(Color.mdailyHairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var activeCategoryTitle: String {
        if categoryFilter == "all" {
            return isEnglish ? "All Categories" : "Tất cả danh mục"
        }
        return store.categories.first(where: { $0.id == categoryFilter })?.localizedLabel(lang: store.language) ?? categoryFilter
    }

    private var categoryFilterMenu: some View {
        let expenseCats = store.categories.filter { $0.kind == .expense }
        let incomeCats = store.categories.filter { $0.kind == .income }

        return Menu {
            Button {
                categoryFilter = "all"
            } label: {
                HStack {
                    Text(isEnglish ? "All Categories" : "Tất cả danh mục")
                    if categoryFilter == "all" {
                        Image(systemName: "checkmark")
                    }
                }
            }

            if kindFilter != .income && !expenseCats.isEmpty {
                Section(isEnglish ? "Expenses" : "Chi tiêu") {
                    ForEach(expenseCats) { cat in
                        Button {
                            categoryFilter = cat.id
                        } label: {
                            HStack {
                                Text(cat.localizedLabel(lang: store.language))
                                if categoryFilter == cat.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }

            if kindFilter != .expense && !incomeCats.isEmpty {
                Section(isEnglish ? "Income" : "Thu nhập") {
                    ForEach(incomeCats) { cat in
                        Button {
                            categoryFilter = cat.id
                        } label: {
                            HStack {
                                Text(cat.localizedLabel(lang: store.language))
                                if categoryFilter == cat.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "tag")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.mdailyActionBlue)
                Text(activeCategoryTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.mdailyCardSurface, in: Capsule())
            .overlay(
                Capsule().strokeBorder(Color.mdailyHairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content (Waterfall vs List)

    @ViewBuilder
    private func contentSection(availableWidth: CGFloat) -> some View {
        if transactions.isEmpty {
            emptyStateView
        } else if store.dashboardViewMode == .waterfall {
            waterfallView(availableWidth: availableWidth)
        } else {
            compactListView
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.mdailyParchment)
                    .frame(width: 72, height: 72)
                Image(systemName: "tray")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(Color.mdailyActionBlue)
            }

            Text(isEnglish ? "No matching transactions" : "Chưa có giao dịch phù hợp")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            Text(isEnglish
                 ? "Add a new expense or income, or adjust your active filters."
                 : "Thêm khoản thu chi mới hoặc thay đổi bộ lọc hiện tại.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
        .mdailyCard(cornerRadius: 18)
    }

    // MARK: - Responsive Waterfall Grid

    private func columnCount(for availableWidth: CGFloat) -> Int {
        if availableWidth < 310 {
            return 1
        }
        switch layoutProfile {
        case .standardPhone, .iPhoneDuoFolded:
            return 2
        case .iPhoneDuoUnfolded, .pad, .mac:
            return 3
        }
    }

    private var amountRange: (min: Double, max: Double) {
        let amounts = transactions.map(\.amount)
        let minAmt = amounts.min() ?? 0
        let maxAmt = amounts.max() ?? 1
        return (minAmt, max(minAmt + 1, maxAmt))
    }

    private func cardHeight(for tx: Transaction) -> CGFloat {
        let range = amountRange
        let baseMin: CGFloat = tx.photoData != nil ? 195 : 158
        let baseMax: CGFloat = tx.photoData != nil ? 290 : 245
        if range.max <= range.min { return (baseMin + baseMax) * 0.5 }
        let ratio = min(1.0, max(0.0, (tx.amount - range.min) / (range.max - range.min)))
        return baseMin + CGFloat(ratio) * (baseMax - baseMin)
    }

    private func distributeIntoColumns(count: Int) -> [[Transaction]] {
        var columns = Array(repeating: [Transaction](), count: max(1, count))
        var heights = Array(repeating: CGFloat(0), count: max(1, count))
        let spacing: CGFloat = 12

        for tx in transactions {
            let shortestIndex = heights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            columns[shortestIndex].append(tx)
            heights[shortestIndex] += cardHeight(for: tx) + spacing
        }
        return columns
    }

    @ViewBuilder
    private func waterfallView(availableWidth: CGFloat) -> some View {
        let count = columnCount(for: availableWidth)
        let columns = distributeIntoColumns(count: count)

        HStack(alignment: .top, spacing: 12) {
            ForEach(0..<columns.count, id: \.self) { colIndex in
                LazyVStack(spacing: 12) {
                    ForEach(columns[colIndex]) { tx in
                        waterfallCard(for: tx)
                            .frame(height: cardHeight(for: tx))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func waterfallCard(for tx: Transaction) -> some View {
        let isRecurring = store.recurringTransactions.contains {
            $0.linkedTransactionId == tx.id && $0.isActive
        }

        if let photoData = tx.photoData, Image(platformImageData: photoData) != nil {
            TransactionPhotoCard(
                transaction: tx,
                photoData: photoData,
                store: store,
                isRecurring: isRecurring,
                onSelect: { onSelectTransaction(tx) },
                onEdit: { onEditTransaction(tx) },
                onDelete: {
                    transactionToDelete = tx
                    showDeleteConfirmation = true
                }
            )
        } else {
            TransactionTextCard(
                transaction: tx,
                store: store,
                isRecurring: isRecurring,
                onSelect: { onSelectTransaction(tx) },
                onEdit: { onEditTransaction(tx) },
                onDelete: {
                    transactionToDelete = tx
                    showDeleteConfirmation = true
                }
            )
        }
    }

    // MARK: - Compact List Mode

    private struct DayGroup: Identifiable {
        let date: Date
        let items: [Transaction]
        var id: Date { date }
    }

    private var groupedByDay: [DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { tx in
            calendar.startOfDay(for: tx.date)
        }
        return grouped
            .map { DayGroup(date: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }

    private func dayHeaderTitle(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return isEnglish ? "Today" : "Hôm nay"
        }
        if calendar.isDateInYesterday(date) {
            return isEnglish ? "Yesterday" : "Hôm qua"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isEnglish ? "en_US" : "vi_VN")
        formatter.dateFormat = isEnglish ? "EEE, MMM d, yyyy" : "EEEE, dd/MM/yyyy"
        return formatter.string(from: date).capitalized
    }

    private var compactListView: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            ForEach(groupedByDay) { group in
                let groupNet = store.netBalance(in: group.items)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(dayHeaderTitle(group.date))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        let prefix = groupNet > 0 ? "+" : (groupNet < 0 ? "−" : "")
                        Text("\(prefix)\(store.formatCurrency(abs(groupNet)))")
                            .font(.system(size: 13, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(groupNet > 0 ? Color.mdailyIncomeGreen : Color.secondary)
                    }
                    .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        ForEach(Array(group.items.enumerated()), id: \.element.id) { index, tx in
                            let isRecurring = store.recurringTransactions.contains {
                                $0.linkedTransactionId == tx.id && $0.isActive
                            }

                            TransactionCompactRow(
                                transaction: tx,
                                store: store,
                                isRecurring: isRecurring,
                                onSelect: { onSelectTransaction(tx) },
                                onEdit: { onEditTransaction(tx) },
                                onDelete: {
                                    transactionToDelete = tx
                                    showDeleteConfirmation = true
                                }
                            )

                            if index < group.items.count - 1 {
                                Divider()
                                    .overlay(Color.mdailyHairline)
                                    .padding(.leading, 64)
                            }
                        }
                    }
                    .mdailyCard(cornerRadius: 18)
                }
            }
        }
    }
}

// MARK: - Cross-Platform Custom Time Filter Sheet

private enum CustomTimeTab: Int, CaseIterable, Identifiable {
    case specificDate
    case specificMonth
    case specificYear
    case dateRange

    var id: Int { rawValue }

    func title(isEnglish: Bool) -> String {
        switch self {
        case .specificDate: return isEnglish ? "Day" : "Ngày"
        case .specificMonth: return isEnglish ? "Month" : "Tháng"
        case .specificYear: return isEnglish ? "Year" : "Năm"
        case .dateRange: return isEnglish ? "Range" : "Khoảng"
        }
    }
}

private struct CustomTimeFilterSheet: View {
    @ObservedObject var store: FinanceStore
    @Binding var currentMode: TimeFilterMode
    let onClose: () -> Void

    @State private var selectedTab: CustomTimeTab = .specificDate
    @State private var selectedDate: Date = Date()
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var fromDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var toDate: Date = Date()

    @Environment(\.dismiss) private var dismiss

    private let years: [Int] = {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 10)...(current + 2)).reversed()
    }()

    init(store: FinanceStore, currentMode: Binding<TimeFilterMode>, onClose: @escaping () -> Void) {
        self.store = store
        self._currentMode = currentMode
        self.onClose = onClose

        switch currentMode.wrappedValue {
        case .specificDate(let d):
            _selectedTab = State(initialValue: .specificDate)
            _selectedDate = State(initialValue: d)
        case .specificMonth(let m, let y):
            _selectedTab = State(initialValue: .specificMonth)
            _selectedMonth = State(initialValue: m)
            _selectedYear = State(initialValue: y)
        case .specificYear(let y):
            _selectedTab = State(initialValue: .specificYear)
            _selectedYear = State(initialValue: y)
        case .dateRange(let from, let to):
            _selectedTab = State(initialValue: .dateRange)
            _fromDate = State(initialValue: from)
            _toDate = State(initialValue: to)
        case .preset:
            _selectedTab = State(initialValue: .specificDate)
        }
    }

    private var isEnglish: Bool { store.language == .en }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(isEnglish ? "Custom Time Filter" : "Bộ lọc thời gian")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button {
                    dismiss()
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Picker("", selection: $selectedTab) {
                ForEach(CustomTimeTab.allCases) { tab in
                    Text(tab.title(isEnglish: isEnglish)).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .specificDate:
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .padding(12)
                        .mdailyCard(cornerRadius: 18)

                    case .specificMonth:
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text(isEnglish ? "Year" : "Năm")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Picker("", selection: $selectedYear) {
                                    ForEach(years, id: \.self) { y in
                                        Text(String(y)).tag(y)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                                ForEach(1...12, id: \.self) { month in
                                    let isSelected = selectedMonth == month
                                    Button {
                                        selectedMonth = month
                                    } label: {
                                        Text(isEnglish ? "Month \(month)" : "Tháng \(month)")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 40)
                                            .background(
                                                isSelected ? Color.mdailyActionBlue : Color.mdailyParchment,
                                                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                        .mdailyCard(cornerRadius: 18)

                    case .specificYear:
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(years, id: \.self) { year in
                                let isSelected = selectedYear == year
                                Button {
                                    selectedYear = year
                                } label: {
                                    Text(String(year))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(
                                            isSelected ? Color.mdailyActionBlue : Color.mdailyParchment,
                                            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                        .mdailyCard(cornerRadius: 18)

                    case .dateRange:
                        VStack(spacing: 14) {
                            DatePicker(
                                isEnglish ? "From" : "Từ ngày",
                                selection: $fromDate,
                                displayedComponents: [.date]
                            )
                            Divider().overlay(Color.mdailyHairline)
                            DatePicker(
                                isEnglish ? "To" : "Đến ngày",
                                selection: $toDate,
                                displayedComponents: [.date]
                            )
                        }
                        .padding(16)
                        .mdailyCard(cornerRadius: 18)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }

            VStack(spacing: 10) {
                Button {
                    applyFilter()
                } label: {
                    Text(isEnglish ? "Apply Filter" : "Áp dụng bộ lọc")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.mdailyActionBlue, in: Capsule())
                }
                .buttonStyle(MDailyPressButtonStyle())

                Button {
                    currentMode = .preset(.all)
                    dismiss()
                    onClose()
                } label: {
                    Text(isEnglish ? "Reset to All Time" : "Đặt lại tất cả thời gian")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .background(Color.mdailyCanvas)
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 480)
        #endif
    }

    private func applyFilter() {
        switch selectedTab {
        case .specificDate:
            currentMode = .specificDate(selectedDate)
        case .specificMonth:
            currentMode = .specificMonth(month: selectedMonth, year: selectedYear)
        case .specificYear:
            currentMode = .specificYear(year: selectedYear)
        case .dateRange:
            let start = min(fromDate, toDate)
            let end = max(fromDate, toDate)
            currentMode = .dateRange(from: start, to: end)
        }
        dismiss()
        onClose()
    }
}
