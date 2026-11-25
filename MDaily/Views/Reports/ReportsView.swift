import SwiftUI
import Charts

@MainActor
public struct ReportsView: View {
    @ObservedObject public var store: FinanceStore
    public var transactions: [Transaction]
    @Binding public var timeFilterMode: TimeFilterMode
    public let layoutProfile: AdaptiveLayoutProfile

    @State private var selectedSegment: Int = 0 // 0: Analytics, 1: Category Manager
    @State private var granularity: ReportGranularity = .day
    @State private var breakdownKind: TransactionKind = .expense
    @State private var managerKind: TransactionKind = .expense

    @State private var isAddingCategory: Bool = false
    @State private var newCategoryLabel: String = ""
    @State private var editingCategoryId: String? = nil
    @State private var editCategoryLabel: String = ""
    @State private var categoryToDelete: CategoryItem? = nil
    @State private var showDeleteCategoryAlert: Bool = false

    private let chartPalette: [Color] = [
        .mdailyActionBlue,
        .mdailyIncomeGreen,
        Color(hex: 0x5856D6),
        Color(hex: 0xFF9500),
        Color(hex: 0xAF52DE),
        Color(hex: 0x00C7BE),
        Color(hex: 0xFF2D55),
        Color(hex: 0x64D2FF),
        Color(hex: 0x8E8E93),
        .mdailyDestructiveRed
    ]

    public init(
        store: FinanceStore,
        transactions: [Transaction],
        timeFilterMode: Binding<TimeFilterMode>,
        layoutProfile: AdaptiveLayoutProfile
    ) {
        self.store = store
        self.transactions = transactions
        self._timeFilterMode = timeFilterMode
        self.layoutProfile = layoutProfile
    }

    private var isEnglish: Bool { store.language == .en }
    private var isCompactWidth: Bool {
        layoutProfile == .iPhoneDuoFolded || layoutProfile == .standardPhone
    }
    private var horizontalPadding: CGFloat {
        layoutProfile == .iPhoneDuoFolded ? 14 : 20
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                headerSection
                segmentedSwitch

                if selectedSegment == 0 {
                    analyticsSection
                } else {
                    categoryManagerSection
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 14)
            .padding(.bottom, layoutProfile == .standardPhone ? 104 : 32)
        }
        .background(Color.mdailyCanvas.ignoresSafeArea())
        .alert(isEnglish ? "Delete Category?" : "Xoá danh mục?", isPresented: $showDeleteCategoryAlert) {
            Button(isEnglish ? "Delete" : "Xoá", role: .destructive) {
                if let cat = categoryToDelete {
                    store.deleteCategory(id: cat.id)
                    categoryToDelete = nil
                }
            }
            Button(isEnglish ? "Cancel" : "Huỷ", role: .cancel) {
                categoryToDelete = nil
            }
        } message: {
            if let cat = categoryToDelete {
                Text(cat.localizedLabel(lang: store.language))
            }
        }
    }

    // MARK: - Header & Controls

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isEnglish ? "Reports" : "Báo cáo")
                    .font(isCompactWidth ? MDailyTypography.tagline : MDailyTypography.displayMd)
                    .tracking(MDailyTypography.Tracking.displayMd)
                    .foregroundStyle(Color.mdailyInk)

                Text(timeFilterMode.displayTitle(lang: store.language))
                    .font(MDailyTypography.caption)
                    .foregroundStyle(Color.mdailyMutedInk)
            }

            Spacer()

            timeFilterMenu
        }
    }

    private var timeFilterMenu: some View {
        Menu {
            ForEach(TimePreset.allCases) { preset in
                Button {
                    timeFilterMode = .preset(preset)
                } label: {
                    HStack {
                        Text(preset.title(lang: store.language))
                        if case .preset(preset) = timeFilterMode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                Text(timeFilterMode.displayTitle(lang: store.language))
                    .font(MDailyTypography.captionStrong)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(Color.mdailyActionBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .mdailyCard(cornerRadius: MDailyRadius.pill, background: .mdailyParchment)
        }
        .buttonStyle(.plain)
    }

    private var segmentedSwitch: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                segmentButton(
                    title: isEnglish ? "Income & Expense" : "Báo cáo Thu & Chi",
                    icon: "chart.bar.xaxis",
                    isSelected: selectedSegment == 0
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        selectedSegment = 0
                    }
                }

                segmentButton(
                    title: isEnglish ? "Categories" : "Quản lý danh mục",
                    icon: "square.grid.2x2",
                    isSelected: selectedSegment == 1
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        selectedSegment = 1
                    }
                }
            }
            .padding(4)
            .mdailyCard(cornerRadius: MDailyRadius.pill, background: .mdailyParchment)

            if selectedSegment == 0 {
                Picker("", selection: $granularity) {
                    ForEach(ReportGranularity.allCases) { mode in
                        Text(mode.title(lang: store.language)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private func segmentButton(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(MDailyTypography.captionStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(isSelected ? Color.white : Color.mdailyInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .padding(.horizontal, 10)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Color.mdailyActionBlue)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Analytics Tab

    private var analyticsSection: some View {
        let totalIncome = store.totalIncome(in: transactions)
        let totalExpense = store.totalExpense(in: transactions)
        let netBalance = store.netBalance(in: transactions)

        return VStack(alignment: .leading, spacing: 16) {
            kpiStrip(income: totalIncome, expense: totalExpense, net: netBalance)
            cashflowBarChartCard
            categoryBreakdownCard
        }
    }

    private func kpiStrip(income: Double, expense: Double, net: Double) -> some View {
        Group {
            if isCompactWidth {
                VStack(spacing: 10) {
                    kpiCard(
                        title: isEnglish ? "Net Cashflow" : "Dòng tiền ròng (Thu − Chi)",
                        amountText: formatSignedNet(net),
                        accent: net >= 0 ? .mdailyIncomeGreen : .mdailyDestructiveRed,
                        icon: net >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill"
                    )
                    HStack(spacing: 10) {
                        kpiCard(
                            title: isEnglish ? "Income" : "Tổng Thu",
                            amountText: "+\(store.formatCurrency(income))",
                            accent: .mdailyIncomeGreen,
                            icon: "plus.circle.fill"
                        )
                        kpiCard(
                            title: isEnglish ? "Expense" : "Tổng Chi",
                            amountText: "−\(store.formatCurrency(expense))",
                            accent: .mdailyInk,
                            icon: "minus.circle.fill"
                        )
                    }
                }
            } else {
                HStack(spacing: 12) {
                    kpiCard(
                        title: isEnglish ? "Income" : "Tổng Thu",
                        amountText: "+\(store.formatCurrency(income))",
                        accent: .mdailyIncomeGreen,
                        icon: "plus.circle.fill"
                    )
                    kpiCard(
                        title: isEnglish ? "Expense" : "Tổng Chi",
                        amountText: "−\(store.formatCurrency(expense))",
                        accent: .mdailyInk,
                        icon: "minus.circle.fill"
                    )
                    kpiCard(
                        title: isEnglish ? "Net Cashflow" : "Thu − Chi",
                        amountText: formatSignedNet(net),
                        accent: net >= 0 ? .mdailyIncomeGreen : .mdailyDestructiveRed,
                        icon: net >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill"
                    )
                }
            }
        }
    }

    private func kpiCard(title: String, amountText: String, accent: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
                Text(title)
                    .font(MDailyTypography.finePrint)
                    .foregroundStyle(Color.mdailyMutedInk)
                    .lineLimit(1)
            }
            Text(amountText)
                .font(MDailyTypography.bodyStrong)
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .mdailyCard(cornerRadius: MDailyRadius.lg, background: .mdailyCardSurface)
    }

    // MARK: - Dual Bar Chart (Day / Week / Month)

    private struct PeriodBucket: Identifiable {
        let id: Date
        let label: String
        let income: Double
        let expense: Double
        var net: Double { income - expense }
    }

    private struct BarDatum: Identifiable {
        let id: String
        let periodDate: Date
        let periodLabel: String
        let series: String
        let amount: Double
    }

    private var periodBuckets: [PeriodBucket] {
        let calendar = Calendar.current
        var grouped: [Date: (income: Double, expense: Double)] = [:]

        for tx in transactions {
            let bucketDate = bucketStartDate(for: tx.date, granularity: granularity, calendar: calendar)
            var current = grouped[bucketDate] ?? (0, 0)
            if tx.kind == .income {
                current.income += tx.amount
            } else {
                current.expense += tx.amount
            }
            grouped[bucketDate] = current
        }

        let sortedDates = grouped.keys.sorted()
        let limitedDates = sortedDates.suffix(isCompactWidth ? 7 : 12)

        return limitedDates.map { date in
            let sums = grouped[date] ?? (0, 0)
            return PeriodBucket(
                id: date,
                label: formatBucketLabel(date, granularity: granularity, calendar: calendar),
                income: sums.income,
                expense: sums.expense
            )
        }
    }

    private func bucketStartDate(for date: Date, granularity: ReportGranularity, calendar: Calendar) -> Date {
        switch granularity {
        case .day:
            return calendar.startOfDay(for: date)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
        }
    }

    private func formatBucketLabel(_ date: Date, granularity: ReportGranularity, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isEnglish ? "en_US" : "vi_VN")
        switch granularity {
        case .day:
            formatter.dateFormat = "dd/MM"
            return formatter.string(from: date)
        case .week:
            let week = calendar.component(.weekOfYear, from: date)
            return isEnglish ? "W\(week)" : "T\(week)"
        case .month:
            formatter.dateFormat = "MM/yy"
            return formatter.string(from: date)
        }
    }

    private var cashflowBarChartCard: some View {
        let buckets = periodBuckets
        let incomeSeries = isEnglish ? "Income" : "Thu nhập"
        let expenseSeries = isEnglish ? "Expense" : "Chi tiêu"

        let barData: [BarDatum] = buckets.flatMap { bucket in
            [
                BarDatum(
                    id: "\(bucket.id.timeIntervalSince1970)_inc",
                    periodDate: bucket.id,
                    periodLabel: bucket.label,
                    series: incomeSeries,
                    amount: bucket.income
                ),
                BarDatum(
                    id: "\(bucket.id.timeIntervalSince1970)_exp",
                    periodDate: bucket.id,
                    periodLabel: bucket.label,
                    series: expenseSeries,
                    amount: bucket.expense
                )
            ]
        }

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isEnglish ? "Income vs Expense" : "So sánh Thu & Chi")
                        .font(MDailyTypography.bodyStrong)
                        .foregroundStyle(Color.mdailyInk)
                    Text(isEnglish
                         ? "Grouped by \(granularity.title(lang: store.language).lowercased()) with net trend"
                         : "Theo \(granularity.title(lang: store.language).lowercased()) kèm xu hướng dòng tiền ròng")
                        .font(MDailyTypography.finePrint)
                        .foregroundStyle(Color.mdailyMutedInk)
                }
                Spacer()
            }

            if buckets.isEmpty {
                emptyChartPlaceholder(
                    icon: "chart.bar",
                    message: isEnglish ? "No transactions for this period" : "Chưa có giao dịch trong khoảng thời gian này"
                )
            } else {
                Chart {
                    ForEach(barData) { item in
                        BarMark(
                            x: .value("Period", item.periodLabel),
                            y: .value("Amount", item.amount)
                        )
                        .foregroundStyle(by: .value("Series", item.series))
                        .position(by: .value("Series", item.series))
                        .cornerRadius(4)
                    }

                    ForEach(buckets) { bucket in
                        LineMark(
                            x: .value("Period", bucket.label),
                            y: .value("Net", bucket.net)
                        )
                        .foregroundStyle(Color.mdailyActionBlue)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 3]))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Period", bucket.label),
                            y: .value("Net", bucket.net)
                        )
                        .foregroundStyle(Color.mdailyActionBlue)
                        .symbolSize(26)
                        .annotation(position: .top, spacing: 4) {
                            if buckets.count <= 6 {
                                Text(compactNumber(bucket.net))
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(Color.mdailyActionBlue)
                            }
                        }
                    }
                }
                .chartForegroundStyleScale([
                    incomeSeries: Color.mdailyIncomeGreen,
                    expenseSeries: Color.mdailyInk.opacity(0.75)
                ])
                .chartLegend(position: .bottom, alignment: .leading, spacing: 14)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.mdailyHairline)
                        AxisValueLabel {
                            if let num = value.as(Double.self) {
                                Text(compactNumber(num))
                                    .font(MDailyTypography.microLegal)
                                    .foregroundStyle(Color.mdailyMutedInk)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(MDailyTypography.microLegal)
                            .foregroundStyle(Color.mdailyMutedInk)
                    }
                }
                .frame(height: 220)

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.mdailyActionBlue)
                        .frame(width: 14, height: 2)
                    Text(isEnglish ? "Net cashflow trend (Income − Expense)" : "Đường xu hướng dòng tiền ròng (Thu − Chi)")
                        .font(MDailyTypography.finePrint)
                        .foregroundStyle(Color.mdailyActionBlue)
                }
            }
        }
        .padding(16)
        .mdailyCard(cornerRadius: MDailyRadius.lg, background: .mdailyCardSurface)
    }

    // MARK: - Donut / Sector Breakdown

    private var categoryBreakdownCard: some View {
        let filteredByKind = transactions.filter { $0.kind == breakdownKind }
        let kindTotal = filteredByKind.reduce(0.0) { $0 + $1.amount }

        let relevantCategories = store.categories.filter { $0.kind == breakdownKind }
        var categorySums: [(item: CategoryItem, total: Double, color: Color)] = relevantCategories
            .enumerated()
            .compactMap { idx, cat in
                let sum = filteredByKind
                    .filter { $0.categoryId == cat.id }
                    .reduce(0.0) { $0 + $1.amount }
                guard sum > 0 else { return nil }
                return (item: cat, total: sum, color: chartPalette[idx % chartPalette.count])
            }

        // Catch any transactions whose categoryId doesn't match a category of breakdownKind
        let matchedIds = Set(categorySums.map { $0.item.id })
        let orphanSum = filteredByKind
            .filter { !matchedIds.contains($0.categoryId) }
            .reduce(0.0) { $0 + $1.amount }
        if orphanSum > 0 {
            let fallbackCat = CategoryItem(
                id: "__other__",
                label: isEnglish ? "Other" : "Khác",
                kind: breakdownKind,
                iconSymbol: "ellipsis.circle.fill",
                isDefault: true
            )
            categorySums.append((item: fallbackCat, total: orphanSum, color: Color.mdailyMutedInk))
        }

        let sortedTotals = categorySums.sorted { $0.total > $1.total }

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Text(isEnglish ? "Category Breakdown" : "Phân bổ theo danh mục")
                    .font(MDailyTypography.bodyStrong)
                    .foregroundStyle(Color.mdailyInk)

                Spacer()

                Picker("", selection: $breakdownKind) {
                    Text(isEnglish ? "Expense" : "Chi tiêu").tag(TransactionKind.expense)
                    Text(isEnglish ? "Income" : "Thu nhập").tag(TransactionKind.income)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 190)
            }

            if sortedTotals.isEmpty || kindTotal <= 0 {
                emptyChartPlaceholder(
                    icon: "chart.pie",
                    message: isEnglish ? "No data for this category filter" : "Không có dữ liệu cho mục này"
                )
            } else {
                Group {
                    if isCompactWidth {
                        VStack(spacing: 16) {
                            donutChart(items: sortedTotals, total: kindTotal, count: filteredByKind.count)
                            categoryBreakdownRows(items: sortedTotals, total: kindTotal)
                        }
                    } else {
                        HStack(alignment: .top, spacing: 24) {
                            donutChart(items: sortedTotals, total: kindTotal, count: filteredByKind.count)
                                .frame(width: 210)
                            categoryBreakdownRows(items: sortedTotals, total: kindTotal)
                        }
                    }
                }
            }
        }
        .padding(16)
        .mdailyCard(cornerRadius: MDailyRadius.lg, background: .mdailyCardSurface)
    }

    private func donutChart(
        items: [(item: CategoryItem, total: Double, color: Color)],
        total: Double,
        count: Int
    ) -> some View {
        ZStack {
            Chart(items, id: \.item.id) { entry in
                SectorMark(
                    angle: .value("Amount", entry.total),
                    innerRadius: .ratio(0.62),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(entry.color)
            }
            .frame(width: 170, height: 170)

            VStack(spacing: 2) {
                Text(compactNumber(total))
                    .font(MDailyTypography.bodyStrong)
                    .foregroundStyle(breakdownKind == .income ? Color.mdailyIncomeGreen : Color.mdailyInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(store.currencySymbol)
                    .font(MDailyTypography.finePrint)
                    .foregroundStyle(Color.mdailyMutedInk)
                Text("\(count) \(isEnglish ? "tx" : "GD")")
                    .font(MDailyTypography.microLegal)
                    .foregroundStyle(Color.mdailyMutedInk)
            }
            .frame(maxWidth: 94)
        }
        .frame(maxWidth: .infinity)
    }

    private func categoryBreakdownRows(
        items: [(item: CategoryItem, total: Double, color: Color)],
        total: Double
    ) -> some View {
        VStack(spacing: 12) {
            ForEach(items, id: \.item.id) { entry in
                let ratio = total > 0 ? (entry.total / total) : 0
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(entry.color)
                            .frame(width: 9, height: 9)

                        Image(systemName: entry.item.resolvedIconName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.mdailyMutedInk)

                        Text(entry.item.localizedLabel(lang: store.language))
                            .font(MDailyTypography.captionStrong)
                            .foregroundStyle(Color.mdailyInk)
                            .lineLimit(1)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 1) {
                            Text(store.formatCurrency(entry.total))
                                .font(MDailyTypography.captionStrong)
                                .foregroundStyle(Color.mdailyInk)
                            Text(String(format: "%.1f%%", ratio * 100))
                                .font(MDailyTypography.microLegal)
                                .foregroundStyle(Color.mdailyMutedInk)
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule(style: .continuous)
                                .fill(Color.mdailyHairline)
                                .frame(height: 5)
                            Capsule(style: .continuous)
                                .fill(entry.color)
                                .frame(width: max(5, geo.size.width * CGFloat(ratio)), height: 5)
                        }
                    }
                    .frame(height: 5)
                }
            }
        }
    }

    // MARK: - Category Manager Tab

    private var categoryManagerSection: some View {
        let filteredCategories = store.categories.filter { $0.kind == managerKind }

        return VStack(alignment: .leading, spacing: 14) {
            Picker("", selection: $managerKind) {
                Text(isEnglish ? "Expense" : "Chi tiêu").tag(TransactionKind.expense)
                Text(isEnglish ? "Income" : "Thu nhập").tag(TransactionKind.income)
            }
            .pickerStyle(.segmented)

            if !isAddingCategory {
                Button {
                    isAddingCategory = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text(isEnglish
                             ? "Add \(managerKind == .income ? "Income" : "Expense") Category"
                             : "Thêm danh mục \(managerKind == .income ? "Thu nhập" : "Chi tiêu")")
                            .font(MDailyTypography.captionStrong)
                        Spacer()
                    }
                    .foregroundStyle(Color.mdailyActionBlue)
                    .padding(14)
                    .mdailyCard(cornerRadius: MDailyRadius.lg, background: .mdailyCardSurface)
                }
                .buttonStyle(MDailyPressButtonStyle())
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(isEnglish ? "New Category" : "Danh mục mới")
                        .font(MDailyTypography.captionStrong)
                        .foregroundStyle(Color.mdailyInk)

                    HStack(spacing: 8) {
                        TextField(
                            isEnglish ? "Category name..." : "Tên danh mục...",
                            text: $newCategoryLabel
                        )
                        .textFieldStyle(.plain)
                        .font(MDailyTypography.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .mdailyCard(cornerRadius: MDailyRadius.md, background: .mdailyParchment)

                        Button(isEnglish ? "Save" : "Lưu") {
                            let trimmed = newCategoryLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            store.addCategory(label: trimmed, kind: managerKind)
                            newCategoryLabel = ""
                            isAddingCategory = false
                        }
                        .buttonStyle(MDailyPrimaryPillButtonStyle(isDisabled: newCategoryLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                        .disabled(newCategoryLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        MDailyCloseButton(accessibilityLabel: isEnglish ? "Cancel" : "Huỷ") {
                            isAddingCategory = false
                            newCategoryLabel = ""
                        }
                    }
                }
                .padding(14)
                .mdailyCard(cornerRadius: MDailyRadius.lg, background: .mdailyCardSurface)
            }

            VStack(spacing: 10) {
                ForEach(filteredCategories) { cat in
                    let matching = transactions.filter { $0.categoryId == cat.id && $0.kind == managerKind }
                    let sum = matching.reduce(0.0) { $0 + $1.amount }

                    if editingCategoryId == cat.id {
                        categoryEditRow(for: cat)
                    } else {
                        categoryDisplayRow(for: cat, count: matching.count, total: sum)
                    }
                }
            }
        }
    }

    private func categoryEditRow(for cat: CategoryItem) -> some View {
        HStack(spacing: 8) {
            TextField(isEnglish ? "Category name" : "Tên danh mục", text: $editCategoryLabel)
                .textFieldStyle(.plain)
                .font(MDailyTypography.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .mdailyCard(cornerRadius: MDailyRadius.md, background: .mdailyParchment)

            Button(isEnglish ? "Save" : "Lưu") {
                let trimmed = editCategoryLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                store.updateCategory(id: cat.id, newLabel: trimmed)
                editingCategoryId = nil
            }
            .buttonStyle(MDailyPrimaryPillButtonStyle(isDisabled: editCategoryLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            .disabled(editCategoryLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            MDailyCloseButton(accessibilityLabel: isEnglish ? "Cancel" : "Huỷ") {
                editingCategoryId = nil
            }
        }
        .padding(14)
        .mdailyCard(cornerRadius: MDailyRadius.lg, background: .mdailyCardSurface)
    }

    private func categoryDisplayRow(for cat: CategoryItem, count: Int, total: Double) -> some View {
        HStack(spacing: 12) {
            Image(systemName: cat.resolvedIconName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(cat.kind == .income ? Color.mdailyIncomeGreen : Color.mdailyActionBlue)
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill((cat.kind == .income ? Color.mdailyIncomeGreen : Color.mdailyActionBlue).opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(cat.localizedLabel(lang: store.language))
                        .font(MDailyTypography.captionStrong)
                        .foregroundStyle(Color.mdailyInk)
                    if cat.isDefault {
                        Text(isEnglish ? "Default" : "Mặc định")
                            .font(MDailyTypography.microLegal)
                            .foregroundStyle(Color.mdailyMutedInk)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.mdailyParchment))
                    }
                }
                Text("\(count) \(isEnglish ? "transactions" : "giao dịch") • \(store.formatCurrency(total))")
                    .font(MDailyTypography.finePrint)
                    .foregroundStyle(Color.mdailyMutedInk)
            }

            Spacer()

            HStack(spacing: 6) {
                Button {
                    editingCategoryId = cat.id
                    editCategoryLabel = cat.label
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.mdailyActionBlue)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.mdailyActionBlue.opacity(0.10)))
                }
                .buttonStyle(.plain)

                if !cat.isDefault {
                    Button {
                        categoryToDelete = cat
                        showDeleteCategoryAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.mdailyDestructiveRed)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.mdailyDestructiveRed.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .mdailyCard(cornerRadius: MDailyRadius.lg, background: .mdailyCardSurface)
    }

    // MARK: - Helpers

    private func emptyChartPlaceholder(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.mdailyMutedInk.opacity(0.6))
            Text(message)
                .font(MDailyTypography.caption)
                .foregroundStyle(Color.mdailyMutedInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private func formatSignedNet(_ net: Double) -> String {
        if net > 0 {
            return "+\(store.formatCurrency(net))"
        } else if net < 0 {
            return "−\(store.formatCurrency(abs(net)))"
        }
        return store.formatCurrency(0)
    }

    private func compactNumber(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        let absVal = abs(value)
        if absVal >= 1_000_000_000 {
            return String(format: "%@%.1fB", sign, absVal / 1_000_000_000)
        } else if absVal >= 1_000_000 {
            return String(format: "%@%.1fM", sign, absVal / 1_000_000)
        } else if absVal >= 1_000 {
            return String(format: "%@%.0fK", sign, absVal / 1_000)
        } else {
            return String(format: "%@%.0f", sign, absVal)
        }
    }
}
