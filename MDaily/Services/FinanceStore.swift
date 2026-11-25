import Foundation
import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

@MainActor
public final class FinanceStore: ObservableObject {
    @Published public var transactions: [Transaction] = []
    @Published public var categories: [CategoryItem] = []
    @Published public var recurringTransactions: [RecurringTransaction] = []
    @Published public var language: Language = .vi
    @Published public var currency: Currency = .vnd
    @Published public var appearanceMode: AppearanceMode = .system
    @Published public var dashboardViewMode: DashboardViewMode = .waterfall
    @Published public var autoExtractEnabled: Bool = true
    @Published public var aiChatEnabled: Bool = true
    @Published public var chatMessages: [ChatMessageSwift] = []

    private var deletedTransactionIdSet: Set<String> = []
    private var deletedCategoryIdSet: Set<String> = []

    // UserDefaults Keys (Settings + Legacy Migration)
    private let langKey = "mdaily_lang_str"
    private let currKey = "mdaily_curr_str"
    private let appearanceKey = "mdaily_appearance_str"
    private let viewModeKey = "mdaily_dashboard_view_mode_str"
    private let autoExtractKey = "mdaily_auto_extract_bool"
    private let aiChatKey = "mdaily_ai_chat_bool"
    private let migratedFlagKey = "mdaily_v3_migrated_bool"

    private let legacyExpensesKey = "mdaily_expenses_json"
    private let legacyCategoriesKey = "mdaily_categories_json"
    private let legacyRecurringKey = "mdaily_recurring_json"
    private let legacyDeletedExpenseIdsKey = "mdaily_deleted_expense_ids_ios"
    private let legacyDeletedCategoryValuesKey = "mdaily_deleted_category_values_ios"

    private struct PersistedStoreData: Codable {
        var transactions: [Transaction]
        var categories: [CategoryItem]
        var recurringTransactions: [RecurringTransaction]
        var deletedTransactionIds: [String]
        var deletedCategoryIds: [String]
    }

    private struct LegacyExpense: Codable {
        var id: String
        var amount: Double
        var category: String
        var date: Date
        var note: String?
        var photoData: Data?
        var isAiProcessed: Bool
        var updatedAt: Date
    }

    private struct LegacyCategoryItem: Codable {
        var id: String
        var label: String
        var isDefault: Bool
    }

    private struct LegacyRecurringExpense: Codable {
        var id: UUID
        var amount: Double
        var category: String
        var note: String?
        var reminderDate: Date
        var repeatInterval: RepeatInterval
        var isActive: Bool
        var linkedExpenseId: String?
    }

    public init() {
        loadSettings()
        loadStoreData()
    }

    // MARK: - Persistence Paths
    private var storeDirectoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("MDaily", isDirectory: true)
    }

    private var dataFileURL: URL {
        storeDirectoryURL.appendingPathComponent("data.json", isDirectory: false)
    }

    // MARK: - Translations & Formatting
    public func t(_ key: String) -> String {
        LocalizationService.t(key, lang: language)
    }

    public func formatCurrency(_ amount: Double) -> String {
        currency.format(amount)
    }

    public func formatSignedAmount(_ transaction: Transaction) -> String {
        "\(transaction.kind.signPrefix)\(currency.format(transaction.amount))"
    }

    public var currencySymbol: String {
        currency.symbol
    }

    public func category(for id: String) -> CategoryItem? {
        categories.first(where: { $0.id == id })
    }

    public func categoryLabel(for id: String) -> String {
        guard let cat = category(for: id) else { return id }
        return cat.localizedLabel(lang: language)
    }

    public func categories(for kind: TransactionKind) -> [CategoryItem] {
        categories.filter { $0.kind == kind }
    }

    // MARK: - Filtering & Totals
    public func filteredTransactions(
        searchText: String = "",
        kindFilter: TransactionKindFilter = .all,
        timeFilter: TimeFilterMode = .preset(.all),
        categoryId: String = "all"
    ) -> [Transaction] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return transactions.filter { tx in
            switch kindFilter {
            case .all: break
            case .expense:
                guard tx.kind == .expense else { return false }
            case .income:
                guard tx.kind == .income else { return false }
            }

            if categoryId != "all" && tx.categoryId != categoryId {
                return false
            }

            guard timeFilter.matches(tx.date) else {
                return false
            }

            if !query.isEmpty {
                let noteMatch = tx.note?.lowercased().contains(query) ?? false
                let catMatch = categoryLabel(for: tx.categoryId).lowercased().contains(query)
                    || tx.categoryId.lowercased().contains(query)
                let amountPlain = String(Int(tx.amount))
                let amountFormatted = formatCurrency(tx.amount).lowercased()
                let amountMatch = amountPlain.contains(query) || amountFormatted.contains(query)
                return noteMatch || catMatch || amountMatch
            }

            return true
        }
    }

    public func totalIncome(in list: [Transaction]? = nil) -> Double {
        let source = list ?? transactions
        return source.reduce(0) { $0 + ($1.kind == .income ? $1.amount : 0) }
    }

    public func totalExpense(in list: [Transaction]? = nil) -> Double {
        let source = list ?? transactions
        return source.reduce(0) { $0 + ($1.kind == .expense ? $1.amount : 0) }
    }

    public func netBalance(in list: [Transaction]? = nil) -> Double {
        let source = list ?? transactions
        return totalIncome(in: source) - totalExpense(in: source)
    }

    // MARK: - Transaction CRUD
    public func addTransaction(_ transaction: Transaction) {
        var newTx = transaction
        newTx.updatedAt = Date()
        deletedTransactionIdSet.remove(newTx.id)
        transactions.insert(newTx, at: 0)
        transactions.sort { $0.date > $1.date }
        saveStoreData()
    }

    public func updateTransaction(_ transaction: Transaction) {
        guard let idx = transactions.firstIndex(where: { $0.id == transaction.id }) else { return }
        var updated = transaction
        updated.updatedAt = Date()
        transactions[idx] = updated
        transactions.sort { $0.date > $1.date }
        saveStoreData()
    }

    public func deleteTransaction(id: String) {
        transactions.removeAll(where: { $0.id == id })
        markDeletedTransaction(id)

        if let recurringIdx = recurringTransactions.firstIndex(where: { $0.linkedTransactionId == id }) {
            let recurringId = recurringTransactions[recurringIdx].id
            NotificationService.shared.cancelNotification(for: recurringId)
            recurringTransactions.remove(at: recurringIdx)
        }
        saveStoreData()
    }

    public func clearAllData() {
        for tx in transactions {
            markDeletedTransaction(tx.id)
        }
        transactions.removeAll()
        recurringTransactions.removeAll()
        NotificationService.shared.cancelAllNotifications()
        saveStoreData()
    }

    // MARK: - Recurring Transaction CRUD
    public func recurringTransaction(linkedTo transactionId: String) -> RecurringTransaction? {
        recurringTransactions.first(where: { $0.linkedTransactionId == transactionId })
    }

    public func addRecurringTransaction(_ recurring: RecurringTransaction) {
        recurringTransactions.append(recurring)
        saveStoreData()
        NotificationService.shared.scheduleRecurringNotification(
            for: recurring,
            currencySymbol: currencySymbol,
            isEnglish: language == .en
        )
    }

    public func updateRecurringTransaction(_ recurring: RecurringTransaction) {
        guard let idx = recurringTransactions.firstIndex(where: { $0.id == recurring.id }) else { return }
        recurringTransactions[idx] = recurring
        saveStoreData()
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

    public func deleteRecurringTransaction(id: UUID) {
        NotificationService.shared.cancelNotification(for: id)
        recurringTransactions.removeAll(where: { $0.id == id })
        saveStoreData()
    }

    // MARK: - Category CRUD
    @discardableResult
    public func addCategory(
        label: String,
        kind: TransactionKind = .expense,
        iconSymbol: String? = nil
    ) -> CategoryItem {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let slug = trimmed.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }

        var candidateId = slug.isEmpty ? UUID().uuidString : slug
        if categories.contains(where: { $0.id == candidateId }) {
            candidateId = "\(candidateId)-\(UUID().uuidString.prefix(4).lowercased())"
        }

        let item = CategoryItem(
            id: candidateId,
            label: trimmed.isEmpty ? label : trimmed,
            kind: kind,
            iconSymbol: iconSymbol,
            isDefault: false
        )
        deletedCategoryIdSet.remove(item.id)
        categories.append(item)
        saveStoreData()
        return item
    }

    public func updateCategory(id: String, newLabel: String) {
        guard let idx = categories.firstIndex(where: { $0.id == id }) else { return }
        categories[idx].label = newLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        saveStoreData()
    }

    public func updateCategory(id: String, label: String) {
        updateCategory(id: id, newLabel: label)
    }

    public func deleteCategory(id: String) {
        guard let cat = category(for: id), !cat.isDefault else { return }
        categories.removeAll(where: { $0.id == id })
        markDeletedCategory(id)
        saveStoreData()
    }

    // MARK: - Settings Updaters
    public func setLanguage(_ lang: Language) {
        language = lang
        UserDefaults.standard.set(lang.rawValue, forKey: langKey)
    }

    public func setCurrency(_ curr: Currency) {
        currency = curr
        UserDefaults.standard.set(curr.rawValue, forKey: currKey)
    }

    public func setAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: appearanceKey)
        applyAppearance(mode)
    }

    public func setDashboardViewMode(_ mode: DashboardViewMode) {
        dashboardViewMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: viewModeKey)
    }

    public func setAutoExtract(_ enabled: Bool) {
        autoExtractEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: autoExtractKey)
    }

    public func setAiChat(_ enabled: Bool) {
        aiChatEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: aiChatKey)
    }

    // MARK: - Sync & JSON Backup
    public var currentDeviceName: String {
        #if os(macOS)
        return Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        #elseif canImport(UIKit)
        return UIDevice.current.name
        #else
        return ProcessInfo.processInfo.hostName
        #endif
    }

    public func exportSyncPayload() -> SyncPayload {
        SyncPayload(
            app: "MDaily",
            version: "3.0",
            deviceName: currentDeviceName,
            timestamp: Date(),
            transactions: transactions,
            categories: categories,
            deletedTransactionIds: Array(deletedTransactionIdSet),
            deletedCategoryIds: Array(deletedCategoryIdSet)
        )
    }

    @discardableResult
    public func mergeSyncPayload(_ payload: SyncPayload) -> SyncMergeStats {
        var added = 0
        var updated = 0
        var deleted = 0

        // 1. Apply remote deletions
        for deletedId in payload.deletedTransactionIds {
            if transactions.contains(where: { $0.id == deletedId }) {
                transactions.removeAll(where: { $0.id == deletedId })
                deleted += 1
            }
            markDeletedTransaction(deletedId)
        }

        for deletedCatId in payload.deletedCategoryIds {
            if let existingCat = categories.first(where: { $0.id == deletedCatId }), !existingCat.isDefault {
                categories.removeAll(where: { $0.id == deletedCatId })
                markDeletedCategory(deletedCatId)
            }
        }

        // 2. Merge categories
        for incomingCat in payload.categories {
            guard !deletedCategoryIdSet.contains(incomingCat.id) else { continue }
            if !categories.contains(where: { $0.id == incomingCat.id }) {
                categories.append(incomingCat)
            }
        }

        // 3. Merge transactions (Last-Write-Wins via updatedAt)
        for incomingTx in payload.transactions {
            guard !deletedTransactionIdSet.contains(incomingTx.id) else { continue }
            if let idx = transactions.firstIndex(where: { $0.id == incomingTx.id }) {
                if incomingTx.updatedAt > transactions[idx].updatedAt {
                    transactions[idx] = incomingTx
                    updated += 1
                }
            } else {
                transactions.append(incomingTx)
                added += 1
            }
        }

        transactions.sort { $0.date > $1.date }
        ensureDefaultCategoriesPresent()
        saveStoreData()

        return SyncMergeStats(
            added: added,
            updated: updated,
            deleted: deleted,
            total: transactions.count
        )
    }

    public func exportJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(exportSyncPayload())
    }

    @discardableResult
    public func importJSONData(_ data: Data) throws -> SyncMergeStats {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let payload = try? decoder.decode(SyncPayload.self, from: data) {
            return mergeSyncPayload(payload)
        }

        let fallbackDecoder = JSONDecoder()
        if let payload = try? fallbackDecoder.decode(SyncPayload.self, from: data) {
            return mergeSyncPayload(payload)
        }

        if let rawTransactions = try? decoder.decode([Transaction].self, from: data) {
            let synthetic = SyncPayload(
                deviceName: "Imported Backup",
                transactions: rawTransactions,
                categories: []
            )
            return mergeSyncPayload(synthetic)
        }

        let payload = try decoder.decode(SyncPayload.self, from: data)
        return mergeSyncPayload(payload)
    }

    // MARK: - Internal Helpers
    private func markDeletedTransaction(_ id: String) {
        deletedTransactionIdSet.insert(id)
        if deletedTransactionIdSet.count > 1000 {
            deletedTransactionIdSet = Set(deletedTransactionIdSet.prefix(1000))
        }
    }

    private func markDeletedCategory(_ id: String) {
        deletedCategoryIdSet.insert(id)
        if deletedCategoryIdSet.count > 200 {
            deletedCategoryIdSet = Set(deletedCategoryIdSet.prefix(200))
        }
    }

    private func ensureDefaultCategoriesPresent() {
        for def in CategoryItem.defaults {
            if !categories.contains(where: { $0.id == def.id }) {
                categories.append(def)
            }
        }
    }

    private func applyAppearance(_ mode: AppearanceMode) {
        #if canImport(UIKit)
        let style: UIUserInterfaceStyle
        switch mode {
        case .light: style = .light
        case .dark: style = .dark
        case .system: style = .unspecified
        }
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = style
                }
            }
        }
        #elseif canImport(AppKit)
        let appearance: NSAppearance?
        switch mode {
        case .light: appearance = NSAppearance(named: .aqua)
        case .dark: appearance = NSAppearance(named: .darkAqua)
        case .system: appearance = nil
        }
        NSApp?.appearance = appearance
        #endif
    }

    // MARK: - Load & Save
    private func loadSettings() {
        if let langStr = UserDefaults.standard.string(forKey: langKey),
           let savedLang = Language(rawValue: langStr) {
            language = savedLang
        }
        if let currStr = UserDefaults.standard.string(forKey: currKey),
           let savedCurr = Currency(rawValue: currStr) {
            currency = savedCurr
        }
        if let appearanceStr = UserDefaults.standard.string(forKey: appearanceKey),
           let savedAppearance = AppearanceMode(rawValue: appearanceStr) {
            appearanceMode = savedAppearance
            applyAppearance(savedAppearance)
        }
        if let viewStr = UserDefaults.standard.string(forKey: viewModeKey),
           let savedView = DashboardViewMode(rawValue: viewStr) {
            dashboardViewMode = savedView
        }
        if UserDefaults.standard.object(forKey: autoExtractKey) != nil {
            autoExtractEnabled = UserDefaults.standard.bool(forKey: autoExtractKey)
        }
        if UserDefaults.standard.object(forKey: aiChatKey) != nil {
            aiChatEnabled = UserDefaults.standard.bool(forKey: aiChatKey)
        }
    }

    private func loadStoreData() {
        if FileManager.default.fileExists(atPath: dataFileURL.path),
           let data = try? Data(contentsOf: dataFileURL) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decoded = (try? decoder.decode(PersistedStoreData.self, from: data))
                ?? (try? JSONDecoder().decode(PersistedStoreData.self, from: data)) {
                transactions = decoded.transactions.sorted { $0.date > $1.date }
                categories = decoded.categories
                recurringTransactions = decoded.recurringTransactions
                deletedTransactionIdSet = Set(decoded.deletedTransactionIds)
                deletedCategoryIdSet = Set(decoded.deletedCategoryIds)
                ensureDefaultCategoriesPresent()
                return
            }
        }

        // One-time migration from legacy UserDefaults store
        if !UserDefaults.standard.bool(forKey: migratedFlagKey) {
            migrateLegacyUserDefaults()
            UserDefaults.standard.set(true, forKey: migratedFlagKey)
            return
        }

        categories = CategoryItem.defaults
        saveStoreData()
    }

    private func migrateLegacyUserDefaults() {
        let decoder = JSONDecoder()

        if let data = UserDefaults.standard.data(forKey: legacyExpensesKey),
           let legacyExpenses = try? decoder.decode([LegacyExpense].self, from: data) {
            transactions = legacyExpenses.map { exp in
                Transaction(
                    id: exp.id,
                    kind: .expense,
                    amount: exp.amount,
                    categoryId: exp.category,
                    date: exp.date,
                    note: exp.note,
                    photoData: exp.photoData,
                    isAiProcessed: exp.isAiProcessed,
                    updatedAt: exp.updatedAt
                )
            }.sorted { $0.date > $1.date }
        }

        if let data = UserDefaults.standard.data(forKey: legacyCategoriesKey),
           let legacyCats = try? decoder.decode([LegacyCategoryItem].self, from: data) {
            categories = legacyCats.map { cat in
                CategoryItem(
                    id: cat.id,
                    label: cat.label,
                    kind: .expense,
                    iconSymbol: nil,
                    isDefault: cat.isDefault
                )
            }
        } else {
            categories = CategoryItem.defaults
        }

        if let data = UserDefaults.standard.data(forKey: legacyRecurringKey),
           let legacyRec = try? decoder.decode([LegacyRecurringExpense].self, from: data) {
            recurringTransactions = legacyRec.map { rec in
                RecurringTransaction(
                    id: rec.id,
                    kind: .expense,
                    amount: rec.amount,
                    categoryId: rec.category,
                    note: rec.note,
                    reminderDate: rec.reminderDate,
                    repeatInterval: rec.repeatInterval,
                    isActive: rec.isActive,
                    linkedTransactionId: rec.linkedExpenseId
                )
            }
        }

        deletedTransactionIdSet = Set(UserDefaults.standard.stringArray(forKey: legacyDeletedExpenseIdsKey) ?? [])
        deletedCategoryIdSet = Set(UserDefaults.standard.stringArray(forKey: legacyDeletedCategoryValuesKey) ?? [])

        ensureDefaultCategoriesPresent()
        saveStoreData()
    }

    private func saveStoreData() {
        let snapshot = PersistedStoreData(
            transactions: transactions,
            categories: categories,
            recurringTransactions: recurringTransactions,
            deletedTransactionIds: Array(deletedTransactionIdSet),
            deletedCategoryIds: Array(deletedCategoryIdSet)
        )

        do {
            try FileManager.default.createDirectory(
                at: storeDirectoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            try data.write(to: dataFileURL, options: [.atomic])
        } catch {
            print("[FinanceStore] Failed to save data.json: \(error.localizedDescription)")
        }
    }
}
