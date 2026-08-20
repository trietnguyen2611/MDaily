import SwiftUI

public enum CustomFilterTab: Int, CaseIterable, Identifiable {
    case specificDate = 0
    case specificMonth = 1
    case specificYear = 2
    case dateRange = 3

    public var id: Int { rawValue }

    public func title(lang: Language) -> String {
        switch self {
        case .specificDate: return lang == .en ? "Day" : "Ngày"
        case .specificMonth: return lang == .en ? "Month" : "Tháng"
        case .specificYear: return lang == .en ? "Year" : "Năm"
        case .dateRange: return lang == .en ? "Range" : "Khoảng ngày"
        }
    }
}

@MainActor
public struct CustomTimeFilterSheet: View {
    @ObservedObject public var store: ExpenseStore
    @Binding public var currentMode: TimeFilterMode
    public var onClose: () -> Void

    @State private var selectedTab: CustomFilterTab = .specificDate
    @State private var selectedDate: Date = Date()
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var fromDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var toDate: Date = Date()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let years: [Int] = {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 10)...(current + 5)).reversed()
    }()

    public init(
        store: ExpenseStore,
        currentMode: Binding<TimeFilterMode>,
        initialTab: CustomFilterTab = .specificDate,
        onClose: @escaping () -> Void
    ) {
        self.store = store
        self._currentMode = currentMode
        self._selectedTab = State(initialValue: initialTab)
        self.onClose = onClose

        // Initialize state from current mode if already set
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
            _selectedTab = State(initialValue: initialTab)
        }
    }

    public var body: some View {
        NavigationView {
            ZStack {
                (colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Segmented Control
                    Picker("", selection: $selectedTab) {
                        ForEach(CustomFilterTab.allCases) { tab in
                            Text(tab.title(lang: store.language)).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case .specificDate:
                                specificDateView
                            case .specificMonth:
                                specificMonthView
                            case .specificYear:
                                specificYearView
                            case .dateRange:
                                dateRangeView
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    // Bottom Action Buttons
                    VStack(spacing: 10) {
                        Button {
                            applyFilter()
                        } label: {
                            Text(store.language == .en ? "Apply Filter" : "Áp dụng bộ lọc")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.16, green: 0.72, blue: 0.54), Color(red: 0.08, green: 0.48, blue: 0.68)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(color: Color(red: 0.16, green: 0.72, blue: 0.54).opacity(0.35), radius: 8, x: 0, y: 3)
                        }

                        Button {
                            currentMode = .preset(.all)
                            dismiss()
                            onClose()
                        } label: {
                            Text(store.language == .en ? "Reset to All Time" : "Xoá bộ lọc (Tất cả thời gian)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle(store.language == .en ? "Filter by Time" : "Bộ lọc thời gian")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(store.t("cancel")) {
                        dismiss()
                        onClose()
                    }
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 1. Specific Date View (Graphical Calendar)
    private var specificDateView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.language == .en ? "Select a single day:" : "Chọn một ngày cụ thể:")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)

            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06), lineWidth: 0.5)
                    )
            }
        }
    }

    // MARK: - 2. Specific Month View
    private var specificMonthView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Year Selector Row
            HStack {
                Text(store.language == .en ? "Year:" : "Năm:")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)

                Spacer()

                Menu {
                    ForEach(years, id: \.self) { y in
                        Button(String(y)) {
                            selectedYear = y
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(String(selectedYear))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(colorScheme == .dark ? Color(white: 0.16) : Color(white: 0.90))
                    )
                }
            }
            .padding(.horizontal, 4)

            Text(store.language == .en ? "Select Month:" : "Chọn Tháng:")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)

            // 12 Months Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(1...12, id: \.self) { m in
                    let isSelected = selectedMonth == m
                    Button {
                        selectedMonth = m
                    } label: {
                        Text(store.language == .en ? "Month \(m)" : "Tháng \(m)")
                            .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundColor(isSelected ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(red: 0.16, green: 0.72, blue: 0.54), Color(red: 0.08, green: 0.48, blue: 0.68)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06), lineWidth: 0.5)
                                        )
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 3. Specific Year View
    private var specificYearView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(store.language == .en ? "Select a Year:" : "Chọn một Năm:")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(years, id: \.self) { y in
                    let isSelected = selectedYear == y
                    Button {
                        selectedYear = y
                    } label: {
                        Text(String(y))
                            .font(.system(size: 16, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundColor(isSelected ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(red: 0.16, green: 0.72, blue: 0.54), Color(red: 0.08, green: 0.48, blue: 0.68)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06), lineWidth: 0.5)
                                        )
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 4. Date Range View (From Date -> To Date)
    private var dateRangeView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(store.language == .en ? "Select Date Range:" : "Chọn khoảng thời gian:")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                HStack {
                    Label {
                        Text(store.language == .en ? "From Date:" : "Từ ngày:")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    } icon: {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    DatePicker("", selection: $fromDate, displayedComponents: [.date])
                        .labelsHidden()
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                }

                HStack {
                    Label {
                        Text(store.language == .en ? "To Date:" : "Đến ngày:")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(Color(red: 0.16, green: 0.72, blue: 0.54))
                    }

                    Spacer()

                    DatePicker("", selection: $toDate, displayedComponents: [.date])
                        .labelsHidden()
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                }
            }
        }
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
