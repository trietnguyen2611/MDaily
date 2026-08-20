import Foundation
import SwiftUI
import Combine

@MainActor
public final class ExpenseStore: ObservableObject {
    @Published public var expenses: [Expense] = []
    @Published public var categories: [CategoryItem] = []
    @Published public var language: Language = .vi
    @Published public var currency: Currency = .vnd
    @Published public var autoExtractEnabled: Bool = true
    @Published public var aiChatEnabled: Bool = true
    @Published public var appearanceMode: AppearanceMode = .system
    @Published public var chatMessages: [ChatMessageSwift] = []

    private let expensesKey = "mdaily_expenses_json"
    private let categoriesKey = "mdaily_categories_json"
    private let langKey = "mdaily_lang_str"
    private let currKey = "mdaily_curr_str"
    private let autoExtractKey = "mdaily_auto_extract_bool"
    private let aiChatKey = "mdaily_ai_chat_bool"
    private let appearanceKey = "mdaily_appearance_str"

    public init() {
        loadSettings()
        loadCategories()
        loadExpenses()
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
        expenses.insert(expense, at: 0)
        saveExpenses()
    }

    public func updateExpense(_ expense: Expense) {
        if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[idx] = expense
            saveExpenses()
        }
    }

    public func deleteExpense(id: UUID) {
        expenses.removeAll(where: { $0.id == id })
        saveExpenses()
    }

    public func clearAllData() {
        expenses.removeAll()
        saveExpenses()
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
    }

    public func updateCategory(id: String, newLabel: String) {
        if let idx = categories.firstIndex(where: { $0.id == id }) {
            categories[idx].label = newLabel
            saveCategories()
        }
    }

    public func updateCategory(id: String, label: String) {
        updateCategory(id: id, newLabel: label)
    }

    public func deleteCategory(id: String) {
        categories.removeAll(where: { $0.id == id })
        saveCategories()
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

    private func saveCategories() {
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

    private func saveExpenses() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: expensesKey)
        }
    }
}
