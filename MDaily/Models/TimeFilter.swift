import Foundation

public enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case dashboard
    case addTransaction
    case reports
    case settings

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .addTransaction: return "plus.circle.fill"
        case .reports: return "chart.bar.xaxis"
        case .settings: return "gearshape"
        }
    }

    public func title(lang: Language) -> String {
        switch self {
        case .dashboard: return LocalizationService.t("tab_dashboard", lang: lang)
        case .addTransaction: return LocalizationService.t("tab_add_transaction", lang: lang)
        case .reports: return LocalizationService.t("tab_reports", lang: lang)
        case .settings: return LocalizationService.t("tab_settings", lang: lang)
        }
    }
}

public enum DashboardViewMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case waterfall
    case list

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .waterfall: return "rectangle.grid.2x2"
        case .list: return "list.bullet"
        }
    }

    public func title(lang: Language) -> String {
        switch self {
        case .waterfall: return LocalizationService.t("view_waterfall", lang: lang)
        case .list: return LocalizationService.t("view_list", lang: lang)
        }
    }
}

public enum ReportGranularity: String, CaseIterable, Identifiable, Sendable {
    case day
    case week
    case month

    public var id: String { rawValue }

    public func title(lang: Language) -> String {
        switch self {
        case .day: return lang == .en ? "Day" : "Ngày"
        case .week: return lang == .en ? "Week" : "Tuần"
        case .month: return lang == .en ? "Month" : "Tháng"
        }
    }
}

public enum TransactionKindFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case expense
    case income

    public var id: String { rawValue }

    public func title(lang: Language) -> String {
        switch self {
        case .all: return lang == .en ? "All" : "Tất cả"
        case .expense: return lang == .en ? "Expense" : "Chi tiêu"
        case .income: return lang == .en ? "Income" : "Thu nhập"
        }
    }
}

public enum TimePreset: String, CaseIterable, Identifiable, Sendable {
    case all
    case today
    case thisWeek
    case thisMonth
    case thisYear

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

public enum TimeFilterMode: Equatable, Sendable {
    case preset(TimePreset)
    case specificDate(Date)
    case specificMonth(month: Int, year: Int)
    case specificYear(year: Int)
    case dateRange(from: Date, to: Date)

    public func displayTitle(lang: Language) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: lang == .en ? "en_US" : "vi_VN")

        switch self {
        case .preset(let preset):
            return preset.title(lang: lang)
        case .specificDate(let date):
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: date)
        case .specificMonth(let month, let year):
            return String(format: "%02d/%d", month, year)
        case .specificYear(let year):
            return "\(year)"
        case .dateRange(let from, let to):
            formatter.dateFormat = "dd/MM/yy"
            return "\(formatter.string(from: min(from, to))) – \(formatter.string(from: max(from, to)))"
        }
    }

    public func matches(_ date: Date, calendar: Calendar = .current) -> Bool {
        let now = Date()
        switch self {
        case .preset(let preset):
            switch preset {
            case .all:
                return true
            case .today:
                return calendar.isDateInToday(date)
            case .thisWeek:
                return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
            case .thisMonth:
                return calendar.isDate(date, equalTo: now, toGranularity: .month)
            case .thisYear:
                return calendar.isDate(date, equalTo: now, toGranularity: .year)
            }
        case .specificDate(let target):
            return calendar.isDate(date, inSameDayAs: target)
        case .specificMonth(let month, let year):
            let comps = calendar.dateComponents([.month, .year], from: date)
            return comps.month == month && comps.year == year
        case .specificYear(let year):
            return calendar.component(.year, from: date) == year
        case .dateRange(let from, let to):
            let start = calendar.startOfDay(for: min(from, to))
            let endDayStart = calendar.startOfDay(for: max(from, to))
            let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: endDayStart) ?? max(from, to)
            return date >= start && date <= end
        }
    }
}
