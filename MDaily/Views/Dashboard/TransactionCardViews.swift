import SwiftUI

// MARK: - Shared Formatting Helpers for Dashboard & Transaction Views

enum TransactionFormatHelper {
    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm dd/MM/yyyy"
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM HH:mm"
        return f
    }()

    private static let timeOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    static func fullDateTime(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    static func shortDateTime(_ date: Date) -> String {
        shortDateFormatter.string(from: date)
    }

    static func timeOnly(_ date: Date) -> String {
        timeOnlyFormatter.string(from: date)
    }

    static func formatEditableAmount(_ input: String) -> String {
        let cleanDigits = input.filter { $0.isNumber }
        guard !cleanDigits.isEmpty, let num = Double(cleanDigits) else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: num)) ?? cleanDigits
    }

    static func parseEditableAmount(_ input: String) -> Double? {
        let clean = input
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(clean), value > 0 else { return nil }
        return value
    }

    static func signedPrefix(for kind: TransactionKind) -> String {
        kind == .income ? "+" : "−"
    }
}

// MARK: - Transaction Photo Card (Waterfall)

public struct TransactionPhotoCard: View {
    public let transaction: Transaction
    public let photoData: Data
    @ObservedObject public var store: FinanceStore
    public let isRecurring: Bool
    public let onSelect: () -> Void
    public let onEdit: () -> Void
    public let onDelete: () -> Void

    public init(
        transaction: Transaction,
        photoData: Data,
        store: FinanceStore,
        isRecurring: Bool,
        onSelect: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.transaction = transaction
        self.photoData = photoData
        self.store = store
        self.isRecurring = isRecurring
        self.onSelect = onSelect
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    private var categoryItem: CategoryItem? {
        store.categories.first { $0.id == transaction.categoryId }
    }

    private var categoryLabel: String {
        categoryItem?.localizedLabel(lang: store.language) ?? transaction.categoryId
    }

    private var categoryIcon: String {
        categoryItem?.resolvedIconName ?? (transaction.kind == .income ? "arrow.down.left.circle.fill" : "tag.fill")
    }

    private var cleanNote: String? {
        guard let note = transaction.note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !note.isEmpty,
              note != "MDaily AI processed" else {
            return nil
        }
        return note
    }

    public var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .bottomLeading) {
                if let image = Image(platformImageData: photoData) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.mdailyParchment)
                }

                // Minimal legibility scrim over bottom photography edge
                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.28), location: 0.0),
                        .init(color: Color.black.opacity(0.04), location: 0.40),
                        .init(color: Color.black.opacity(0.24), location: 0.62),
                        .init(color: Color.black.opacity(0.82), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 0) {
                    // Top row: Category glass chip + AI/Recurring badges
                    HStack(alignment: .top, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: categoryIcon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(categoryLabel)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .mdailyGlassPill(interactive: false, tint: .black.opacity(0.25))

                        Spacer(minLength: 4)

                        if transaction.isAiProcessed {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .mdailyGlassSurface(in: Circle(), interactive: false, tint: Color.mdailyActionBlue.opacity(0.4))
                        }

                        if isRecurring {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .mdailyGlassSurface(in: Circle(), interactive: false, tint: Color.orange.opacity(0.4))
                        }
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(TransactionFormatHelper.signedPrefix(for: transaction.kind))\(store.formatCurrency(transaction.amount))")
                            .font(.system(size: 18, weight: .semibold))
                            .tracking(-0.3)
                            .foregroundStyle(transaction.kind == .income ? Color.mdailyIncomeGreen : Color.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        if let note = cleanNote {
                            Text(note)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.9))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        Text(TransactionFormatHelper.shortDateTime(transaction.date))
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.72))
                            .lineLimit(1)
                    }
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .mdailyCard(cornerRadius: 18)
        }
        .buttonStyle(MDailyPressButtonStyle())
        .contextMenu {
            TransactionContextMenuItems(
                lang: store.language,
                onView: onSelect,
                onEdit: onEdit,
                onDelete: onDelete
            )
        }
    }
}

// MARK: - Transaction Text Card (Waterfall)

public struct TransactionTextCard: View {
    public let transaction: Transaction
    @ObservedObject public var store: FinanceStore
    public let isRecurring: Bool
    public let onSelect: () -> Void
    public let onEdit: () -> Void
    public let onDelete: () -> Void

    public init(
        transaction: Transaction,
        store: FinanceStore,
        isRecurring: Bool,
        onSelect: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.transaction = transaction
        self.store = store
        self.isRecurring = isRecurring
        self.onSelect = onSelect
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    private var categoryItem: CategoryItem? {
        store.categories.first { $0.id == transaction.categoryId }
    }

    private var categoryLabel: String {
        categoryItem?.localizedLabel(lang: store.language) ?? transaction.categoryId
    }

    private var categoryIcon: String {
        categoryItem?.resolvedIconName ?? (transaction.kind == .income ? "arrow.down.left.circle.fill" : "tag.fill")
    }

    private var cleanNote: String? {
        guard let note = transaction.note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !note.isEmpty,
              note != "MDaily AI processed" else {
            return nil
        }
        return note
    }

    private var amountColor: Color {
        transaction.kind == .income ? Color.mdailyIncomeGreen : Color.mdailyInk
    }

    private var kindBadgeTint: Color {
        transaction.kind == .income ? Color.mdailyIncomeGreen : Color.mdailyActionBlue
    }

    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                // Top row: Category Icon + Badges
                HStack(alignment: .center, spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(kindBadgeTint.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: categoryIcon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(kindBadgeTint)
                    }

                    Spacer(minLength: 4)

                    if transaction.isAiProcessed {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.mdailyActionBlue)
                            .frame(width: 24, height: 24)
                            .background(Color.mdailyActionBlue.opacity(0.12), in: Circle())
                    }

                    if isRecurring {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.orange)
                            .frame(width: 24, height: 24)
                            .background(Color.orange.opacity(0.14), in: Circle())
                    }
                }

                Text(categoryLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("\(TransactionFormatHelper.signedPrefix(for: transaction.kind))\(store.formatCurrency(transaction.amount))")
                    .font(.system(size: 20, weight: .semibold))
                    .tracking(-0.35)
                    .foregroundStyle(amountColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if let note = cleanNote {
                    Text(note)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 2)

                Text(TransactionFormatHelper.shortDateTime(transaction.date))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(14)
            .mdailyCard(cornerRadius: 18)
        }
        .buttonStyle(MDailyPressButtonStyle())
        .contextMenu {
            TransactionContextMenuItems(
                lang: store.language,
                onView: onSelect,
                onEdit: onEdit,
                onDelete: onDelete
            )
        }
    }
}

// MARK: - Transaction Compact Row (List Mode)

public struct TransactionCompactRow: View {
    public let transaction: Transaction
    @ObservedObject public var store: FinanceStore
    public let isRecurring: Bool
    public let onSelect: () -> Void
    public let onEdit: () -> Void
    public let onDelete: () -> Void

    public init(
        transaction: Transaction,
        store: FinanceStore,
        isRecurring: Bool,
        onSelect: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.transaction = transaction
        self.store = store
        self.isRecurring = isRecurring
        self.onSelect = onSelect
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    private var categoryItem: CategoryItem? {
        store.categories.first { $0.id == transaction.categoryId }
    }

    private var categoryLabel: String {
        categoryItem?.localizedLabel(lang: store.language) ?? transaction.categoryId
    }

    private var categoryIcon: String {
        categoryItem?.resolvedIconName ?? (transaction.kind == .income ? "arrow.down.left.circle.fill" : "tag.fill")
    }

    private var cleanNote: String? {
        guard let note = transaction.note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !note.isEmpty,
              note != "MDaily AI processed" else {
            return nil
        }
        return note
    }

    private var amountColor: Color {
        transaction.kind == .income ? Color.mdailyIncomeGreen : Color.mdailyInk
    }

    private var iconTint: Color {
        transaction.kind == .income ? Color.mdailyIncomeGreen : Color.mdailyActionBlue
    }

    public var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(iconTint.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: categoryIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(iconTint)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(categoryLabel)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            if transaction.photoData != nil {
                                Image(systemName: "photo")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            if transaction.isAiProcessed {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.mdailyActionBlue)
                            }
                            if isRecurring {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.orange)
                            }
                        }

                        HStack(spacing: 6) {
                            if let note = cleanNote {
                                Text(note)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Text("·")
                                    .foregroundStyle(.tertiary)
                            }

                            Text(TransactionFormatHelper.timeOnly(transaction.date))
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    Text("\(TransactionFormatHelper.signedPrefix(for: transaction.kind))\(store.formatCurrency(transaction.amount))")
                        .font(.system(size: 15, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(amountColor)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                TransactionContextMenuItems(
                    lang: store.language,
                    onView: onSelect,
                    onEdit: onEdit,
                    onDelete: onDelete
                )
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(store.language == .en ? "Actions" : "Thao tác")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contextMenu {
            TransactionContextMenuItems(
                lang: store.language,
                onView: onSelect,
                onEdit: onEdit,
                onDelete: onDelete
            )
        }
    }
}

// MARK: - Shared Context Menu Items

private struct TransactionContextMenuItems: View {
    let lang: Language
    let onView: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button {
            onView()
        } label: {
            Label(lang == .en ? "View Details" : "Xem chi tiết", systemImage: "eye")
        }

        Button {
            onEdit()
        } label: {
            Label(lang == .en ? "Edit" : "Chỉnh sửa", systemImage: "pencil")
        }

        Divider()

        Button(role: .destructive) {
            onDelete()
        } label: {
            Label(lang == .en ? "Delete" : "Xoá", systemImage: "trash")
        }
    }
}
