import Foundation
import SwiftUI
import Combine

public enum CameraLayoutMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case `default` = "default"
    case dynamicIsland = "dynamic_island"

    public var id: String { rawValue }

    public func title(lang: Language) -> String {
        switch self {
        case .default: return lang == .en ? "Default" : "Mặc định"
        case .dynamicIsland: return lang == .en ? "Dynamic" : "Dynamic"
        }
    }
}

@MainActor
public final class ExpenseStore: ObservableObject {
    @Published public var expenses: [Expense] = []
    @Published public var categories: [CategoryItem] = []
    @Published public var language: Language = .vi
    @Published public var currency: Currency = .vnd
    @Published public var autoExtractEnabled: Bool = true
    @Published public var aiChatEnabled: Bool = true
    @Published public var appearanceMode: AppearanceMode = .system
    @Published public var cameraLayoutMode: CameraLayoutMode = .dynamicIsland
    @Published public var chatMessages: [ChatMessageSwift] = []
    @Published public var recurringExpenses: [RecurringExpense] = []

    private let expensesKey = "mdaily_expenses_json"
    private let categoriesKey = "mdaily_categories_json"
    private let langKey = "mdaily_lang_str"
    private let currKey = "mdaily_curr_str"
    private let autoExtractKey = "mdaily_auto_extract_bool"
    private let aiChatKey = "mdaily_ai_chat_bool"
    private let appearanceKey = "mdaily_appearance_str"
    private let recurringKey = "mdaily_recurring_json"
    private let cameraLayoutKey = "mdaily_camera_layout_str"

    public init() {
        loadSettings()
        loadCategories()
        loadExpenses()
        loadRecurringExpenses()
        WifiSyncService.shared.startRealtimeListener(store: self)
        WifiSyncService.shared.triggerAutoSync(store: self, delay: 0.5)
    }

    // MARK: - Translations Helper
    public func t(_ key: String) -> String {
        LocalizationService.t(key, lang: language)
    }

    public func formatCurrency(_ amount: Double) -> String {
        currency.format(amount)
    }

    public var currencySymbol: String {
        currency.symbol
    }

    /// Returns the localized label for a category, using language-aware names for default categories.
    public func categoryLabel(for id: String) -> String {
        guard let cat = categories.first(where: { $0.id == id }) else { return id }
        return cat.localizedLabel(lang: language)
    }

    // MARK: - Expense CRUD
    public func addExpense(_ expense: Expense) {
        var newEx = expense
        newEx.updatedAt = Date()
        expenses.insert(newEx, at: 0)
        saveExpenses()
        WifiSyncService.shared.triggerAutoSync(store: self)
    }

    public func updateExpense(_ expense: Expense) {
        if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
            var updated = expense
            updated.updatedAt = Date()
            expenses[idx] = updated
            saveExpenses()
            WifiSyncService.shared.triggerAutoSync(store: self)
        }
    }

    public func deleteExpense(id: String) {
        expenses.removeAll(where: { $0.id == id })
        WifiSyncService.shared.markDeletedExpense(id)
        saveExpenses()
        // Also remove linked recurring expenses
        if let recurringIdx = recurringExpenses.firstIndex(where: { $0.linkedExpenseId == id }) {
            let recurringId = recurringExpenses[recurringIdx].id
            NotificationService.shared.cancelNotification(for: recurringId)
            recurringExpenses.remove(at: recurringIdx)
            saveRecurringExpenses()
        }
        WifiSyncService.shared.triggerAutoSync(store: self)
    }

    public func clearAllData() {
        for expense in expenses {
            WifiSyncService.shared.markDeletedExpense(expense.id)
        }
        expenses.removeAll()
        saveExpenses()
        recurringExpenses.removeAll()
        saveRecurringExpenses()
        NotificationService.shared.cancelAllNotifications()
        WifiSyncService.shared.triggerAutoSync(store: self)
    }

    // MARK: - Recurring Expense CRUD
    public func addRecurringExpense(_ recurring: RecurringExpense) {
        recurringExpenses.append(recurring)
        saveRecurringExpenses()
        NotificationService.shared.scheduleRecurringNotification(
            for: recurring,
            currencySymbol: currencySymbol,
            isEnglish: language == .en
        )
    }

    public func updateRecurringExpense(_ recurring: RecurringExpense) {
        if let idx = recurringExpenses.firstIndex(where: { $0.id == recurring.id }) {
            recurringExpenses[idx] = recurring
            saveRecurringExpenses()
            if recurring.isActive {
                NotificationService.shared.scheduleRecurringNotification(
                    for: recurring,
                    currencySymbol: currencySymbol,
                    isEnglish: language == .en
                )
            } else {
                NotificationService.shared.cancelNotification(for: recurring.id)
            }
        }
    }

    public func deleteRecurringExpense(id: UUID) {
        NotificationService.shared.cancelNotification(for: id)
        recurringExpenses.removeAll(where: { $0.id == id })
        saveRecurringExpenses()
    }

    // MARK: - Category CRUD
    public func addCategory(label: String) {
        let cleanId = label.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }

        let item = CategoryItem(id: cleanId.isEmpty ? UUID().uuidString : cleanId, label: label, isDefault: false)
        categories.append(item)
        saveCategories()
        WifiSyncService.shared.triggerAutoSync(store: self)
    }

    public func updateCategory(id: String, newLabel: String) {
        if let idx = categories.firstIndex(where: { $0.id == id }) {
            categories[idx].label = newLabel
            saveCategories()
            WifiSyncService.shared.triggerAutoSync(store: self)
        }
    }

    public func updateCategory(id: String, label: String) {
        updateCategory(id: id, newLabel: label)
    }

    public func deleteCategory(id: String) {
        categories.removeAll(where: { $0.id == id })
        WifiSyncService.shared.markDeletedCategory(id)
        saveCategories()
        WifiSyncService.shared.triggerAutoSync(store: self)
    }

    // MARK: - Settings Updaters
    public func setLanguage(_ lang: Language) {
        self.language = lang
        UserDefaults.standard.set(lang.rawValue, forKey: langKey)
    }

    public func setCurrency(_ curr: Currency) {
        self.currency = curr
        UserDefaults.standard.set(curr.rawValue, forKey: currKey)
    }

    public func setAutoExtract(_ enabled: Bool) {
        self.autoExtractEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: autoExtractKey)
    }

    public func setAiChat(_ enabled: Bool) {
        self.aiChatEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: aiChatKey)
    }

    public func setAppearanceMode(_ mode: AppearanceMode) {
        self.appearanceMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: appearanceKey)
        // Apply appearance immediately to all windows
        applyAppearance(mode)
    }

    public func setCameraLayoutMode(_ mode: CameraLayoutMode) {
        if !UIDevice.current.hasDynamicIsland {
            self.cameraLayoutMode = .default
        } else {
            self.cameraLayoutMode = mode
        }
        UserDefaults.standard.set(self.cameraLayoutMode.rawValue, forKey: cameraLayoutKey)
    }

    // MARK: - Appearance Application
    private func applyAppearance(_ mode: AppearanceMode) {
        let style: UIUserInterfaceStyle
        switch mode {
        case .light: style = .light
        case .dark: style = .dark
        case .system: style = .unspecified
        }
        // Apply to all scenes/windows
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = style
                }
            }
        }
    }

    // MARK: - Persistence
    private func loadSettings() {
        if let langStr = UserDefaults.standard.string(forKey: langKey),
           let savedLang = Language(rawValue: langStr) {
            self.language = savedLang
        }
        if let currStr = UserDefaults.standard.string(forKey: currKey),
           let savedCurr = Currency(rawValue: currStr) {
            self.currency = savedCurr
        }
        if UserDefaults.standard.object(forKey: autoExtractKey) != nil {
            self.autoExtractEnabled = UserDefaults.standard.bool(forKey: autoExtractKey)
        }
        if UserDefaults.standard.object(forKey: aiChatKey) != nil {
            self.aiChatEnabled = UserDefaults.standard.bool(forKey: aiChatKey)
        }
        if let appearanceStr = UserDefaults.standard.string(forKey: appearanceKey),
           let savedAppearance = AppearanceMode(rawValue: appearanceStr) {
            self.appearanceMode = savedAppearance
            applyAppearance(savedAppearance)
        }
        if let layoutStr = UserDefaults.standard.string(forKey: cameraLayoutKey),
           let savedLayout = CameraLayoutMode(rawValue: layoutStr) {
            self.cameraLayoutMode = savedLayout
        }
        if !UIDevice.current.hasDynamicIsland {
            self.cameraLayoutMode = .default
        }
    }

    private func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: categoriesKey),
           let decoded = try? JSONDecoder().decode([CategoryItem].self, from: data), !decoded.isEmpty {
            self.categories = decoded
        } else {
            self.categories = CategoryItem.defaults
            saveCategories()
        }
    }

    public func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: categoriesKey)
        }
    }

    private func loadExpenses() {
        if let data = UserDefaults.standard.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            self.expenses = decoded
        }
    }

    public func saveExpenses() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: expensesKey)
        }
    }

    public func applySyncedData(expenses newExpenses: [Expense], categories newCategories: [CategoryItem]) {
        self.expenses = newExpenses
        self.saveExpenses()
        self.categories = newCategories
        self.saveCategories()
    }

    private func loadRecurringExpenses() {
        if let data = UserDefaults.standard.data(forKey: recurringKey),
           let decoded = try? JSONDecoder().decode([RecurringExpense].self, from: data) {
            self.recurringExpenses = decoded
        }
    }

    public func saveRecurringExpenses() {
        if let encoded = try? JSONEncoder().encode(recurringExpenses) {
            UserDefaults.standard.set(encoded, forKey: recurringKey)
        }
    }
}

// MARK: - UIDevice Dynamic Island Detection
public extension UIDevice {
    var hasDynamicIsland: Bool {
        let maxDim = Int(max(UIScreen.main.bounds.height, UIScreen.main.bounds.width))
        // Known Dynamic Island screen heights: 852 (14 Pro, 15, 15 Pro, 16), 874 (16 Pro), 932 (14 Pro Max, 15 Plus, 15 Pro Max, 16 Plus), 956 (16 Pro Max)
        if maxDim == 852 || maxDim == 874 || maxDim == 932 || maxDim == 956 {
            return true
        }

        // Secondary fallback: Safe area top inset >= 51pt
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first {
            return window.safeAreaInsets.top >= 51
        }
        return false
    }
}
