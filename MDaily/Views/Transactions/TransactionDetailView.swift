import SwiftUI

@MainActor
public struct TransactionDetailView: View {
    @ObservedObject public var store: FinanceStore
    public var transaction: Transaction
    public var onClose: () -> Void

    @State private var currentTransaction: Transaction
    @State private var isEditing: Bool = false

    @State private var editKind: TransactionKind = .expense
    @State private var editAmountText: String = ""
    @State private var editCategoryId: String = ""
    @State private var editDate: Date = Date()
    @State private var editNote: String = ""

    @State private var isRecurring: Bool = false
    @State private var reminderDate: Date = Date()
    @State private var repeatInterval: RepeatInterval = .monthly

    @State private var showAmountError: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var isFullscreenImage: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    public init(
        store: FinanceStore,
        transaction: Transaction,
        startInEditMode: Bool = false,
        onClose: @escaping () -> Void
    ) {
        self.store = store
        self.transaction = transaction
        self.onClose = onClose

        _currentTransaction = State(initialValue: transaction)
        _isEditing = State(initialValue: startInEditMode)
        _editKind = State(initialValue: transaction.kind)
        _editAmountText = State(initialValue: TransactionFormatHelper.formatEditableAmount("\(Int(transaction.amount.rounded()))"))
        _editCategoryId = State(initialValue: transaction.categoryId)
        _editDate = State(initialValue: transaction.date)
        _editNote = State(initialValue: transaction.note ?? "")

        let linked = store.recurringTransactions.first { $0.linkedTransactionId == transaction.id }
        _isRecurring = State(initialValue: linked != nil)
        _reminderDate = State(initialValue: linked?.reminderDate ?? Date())
        _repeatInterval = State(initialValue: linked?.repeatInterval ?? .monthly)
    }

    private var isEnglish: Bool { store.language == .en }

    private var filteredCategories: [CategoryItem] {
        store.categories.filter { $0.kind == editKind }
    }

    private var currentCategoryItem: CategoryItem? {
        store.categories.first { $0.id == currentTransaction.categoryId }
    }

    private var currentCategoryLabel: String {
        currentCategoryItem?.localizedLabel(lang: store.language) ?? currentTransaction.categoryId
    }

    public var body: some View {
        VStack(spacing: 0) {
            topNavigationBar
            Divider().overlay(Color.mdailyHairline)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    if let photoData = currentTransaction.photoData,
                       let image = Image(platformImageData: photoData) {
                        photoHeroSection(image: image)
                    }

                    amountHeaderSection
                    detailsFormCard
                    footerActionsSection
                }
                .padding(18)
            }
        }
        .background(Color.mdailyCanvas.ignoresSafeArea())
        .onChange(of: transaction.id) { _, _ in
            syncState(from: transaction)
        }
        .onChange(of: editKind) { _, _ in
            if !filteredCategories.contains(where: { $0.id == editCategoryId }),
               let first = filteredCategories.first {
                editCategoryId = first.id
            }
        }
        .sheet(isPresented: $isFullscreenImage) {
            if let photoData = currentTransaction.photoData {
                ReceiptImagePreviewSheet(photoData: photoData) {
                    isFullscreenImage = false
                }
            }
        }
        .alert(
            isEnglish ? "Delete Transaction?" : "Xoá giao dịch này?",
            isPresented: $showDeleteConfirmation
        ) {
            Button(isEnglish ? "Delete" : "Xoá", role: .destructive) {
                store.deleteTransaction(id: currentTransaction.id)
                onClose()
            }
            Button(isEnglish ? "Cancel" : "Huỷ", role: .cancel) {}
        } message: {
            Text("\(currentCategoryLabel) · \(TransactionFormatHelper.signedPrefix(for: currentTransaction.kind))\(store.formatCurrency(currentTransaction.amount))")
        }
    }

    // MARK: - Top Bar

    private var topNavigationBar: some View {
        HStack(spacing: 12) {
            if isEditing {
                Button {
                    syncState(from: currentTransaction)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing = false
                    }
                } label: {
                    Text(isEnglish ? "Cancel" : "Huỷ")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Text(isEnglish ? "Details" : "Chi tiết")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            if isEditing {
                Button {
                    saveEdits()
                } label: {
                    Text(isEnglish ? "Save" : "Lưu")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.mdailyActionBlue, in: Capsule())
                }
                .buttonStyle(MDailyPressButtonStyle())
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing = true
                    }
                } label: {
                    Text(isEnglish ? "Edit" : "Sửa")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.mdailyActionBlue)
                }
                .buttonStyle(.plain)

                MDailyCloseButton(action: onClose)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    // MARK: - Photo Hero

    private func photoHeroSection(image: Image) -> some View {
        ZStack(alignment: .bottomTrailing) {
            image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onTapGesture {
                    isFullscreenImage = true
                }

            Button {
                isFullscreenImage = true
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.58), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .padding(10)
        .mdailyCard(cornerRadius: 18)
    }

    // MARK: - Amount & Kind Header

    private var amountHeaderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isEditing {
                HStack(spacing: 4) {
                    ForEach(TransactionKind.allCases) { kind in
                        let isSelected = editKind == kind
                        let activeColor: Color = kind == .income ? Color.mdailyIncomeGreen : Color.mdailyActionBlue
                        Button {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                editKind = kind
                            }
                        } label: {
                            Text(kind == .expense
                                 ? (isEnglish ? "Expense" : "Chi tiêu")
                                 : (isEnglish ? "Income" : "Thu nhập"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(isSelected ? Color.white : Color.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(isSelected ? activeColor : Color.clear, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color.mdailyParchment, in: Capsule())

                VStack(alignment: .leading, spacing: 4) {
                    if showAmountError {
                        Text(isEnglish ? "Enter a valid amount" : "Số tiền không hợp lệ")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.red)
                    }

                    HStack(spacing: 8) {
                        TextField("0", text: $editAmountText)
                            .platformNumericKeyboard()
                            .font(.system(size: 28, weight: .semibold))
                            .monospacedDigit()
                            .textFieldStyle(.plain)
                            .onChange(of: editAmountText) { _, newValue in
                                showAmountError = false
                                let formatted = TransactionFormatHelper.formatEditableAmount(newValue)
                                if formatted != newValue {
                                    editAmountText = formatted
                                }
                            }

                        Text(store.currency.symbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.mdailyParchment, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            } else {
                HStack(spacing: 8) {
                    let isIncome = currentTransaction.kind == .income
                    Text(isIncome
                         ? (isEnglish ? "Income" : "Thu nhập")
                         : (isEnglish ? "Expense" : "Chi tiêu"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isIncome ? Color.mdailyIncomeGreen : Color.mdailyActionBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            (isIncome ? Color.mdailyIncomeGreen : Color.mdailyActionBlue).opacity(0.12),
                            in: Capsule()
                        )

                    if currentTransaction.isAiProcessed {
                        Label("MDaily AI", systemImage: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.mdailyActionBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.mdailyActionBlue.opacity(0.12), in: Capsule())
                    }
                }

                let amountColor: Color = currentTransaction.kind == .income
                    ? Color.mdailyIncomeGreen
                    : (colorScheme == .dark ? .white : Color(red: 0.114, green: 0.114, blue: 0.122))

                Text("\(TransactionFormatHelper.signedPrefix(for: currentTransaction.kind))\(store.formatCurrency(currentTransaction.amount))")
                    .font(.system(size: 34, weight: .semibold))
                    .tracking(-0.4)
                    .monospacedDigit()
                    .foregroundStyle(amountColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .mdailyCard(cornerRadius: 18)
    }

    // MARK: - Details / Edit Card

    private var detailsFormCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Category Row
            HStack {
                Label {
                    Text(isEnglish ? "Category" : "Danh mục")
                        .font(.system(size: 14, weight: .semibold))
                } icon: {
                    Image(systemName: currentCategoryItem?.resolvedIconName ?? "tag.fill")
                        .foregroundStyle(Color.mdailyActionBlue)
                }

                Spacer()

                if isEditing {
                    Picker("", selection: $editCategoryId) {
                        ForEach(filteredCategories) { cat in
                            Text(cat.localizedLabel(lang: store.language)).tag(cat.id)
                        }
                    }
                    .pickerStyle(.menu)
                } else {
                    Text(currentCategoryLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }

            Divider().overlay(Color.mdailyHairline)

            // Date Row
            HStack {
                Label {
                    Text(isEnglish ? "Time" : "Thời gian")
                        .font(.system(size: 14, weight: .semibold))
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.mdailyActionBlue)
                }

                Spacer()

                if isEditing {
                    DatePicker(
                        "",
                        selection: $editDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                } else {
                    Text(TransactionFormatHelper.fullDateTime(currentTransaction.date))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }

            Divider().overlay(Color.mdailyHairline)

            // Note Row
            VStack(alignment: .leading, spacing: 6) {
                Label {
                    Text(isEnglish ? "Note" : "Ghi chú")
                        .font(.system(size: 14, weight: .semibold))
                } icon: {
                    Image(systemName: "note.text")
                        .foregroundStyle(Color.mdailyActionBlue)
                }

                if isEditing {
                    TextField(
                        isEnglish ? "Add a note…" : "Nhập ghi chú…",
                        text: $editNote
                    )
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.mdailyParchment, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    Text(currentTransaction.note?.isEmpty == false ? (currentTransaction.note ?? "") : (isEnglish ? "No note" : "Không có ghi chú"))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(currentTransaction.note?.isEmpty == false ? .primary : .tertiary)
                }
            }

            Divider().overlay(Color.mdailyHairline)

            // Recurring Reminder Row
            if isEditing {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $isRecurring) {
                        Label {
                            Text(isEnglish ? "Recurring Reminder" : "Nhắc lịch định kỳ")
                                .font(.system(size: 14, weight: .semibold))
                        } icon: {
                            Image(systemName: "bell.badge")
                                .foregroundStyle(Color.orange)
                        }
                    }
                    .tint(Color.mdailyActionBlue)

                    if isRecurring {
                        HStack {
                            Text(isEnglish ? "Repeat" : "Lặp lại")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Picker("", selection: $repeatInterval) {
                                ForEach(RepeatInterval.allCases.filter { $0 != .none }) { interval in
                                    Text(interval.title(lang: store.language)).tag(interval)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        DatePicker(
                            isEnglish ? "Next Reminder" : "Nhắc tiếp theo",
                            selection: $reminderDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .font(.system(size: 13))
                    }
                }
            } else {
                HStack {
                    Label {
                        Text(isEnglish ? "Reminder" : "Nhắc lịch")
                            .font(.system(size: 14, weight: .semibold))
                    } icon: {
                        Image(systemName: "bell")
                            .foregroundStyle(isRecurring ? Color.orange : Color.secondary)
                    }

                    Spacer()

                    if isRecurring {
                        Text("\(repeatInterval.title(lang: store.language)) · \(TransactionFormatHelper.shortDateTime(reminderDate))")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(isEnglish ? "Off" : "Tắt")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(16)
        .mdailyCard(cornerRadius: 18)
    }

    // MARK: - Footer Actions

    private var footerActionsSection: some View {
        VStack(spacing: 10) {
            if !isEditing {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(
                        isEnglish ? "Delete Transaction" : "Xoá giao dịch",
                        systemImage: "trash"
                    )
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.08), in: Capsule())
                }
                .buttonStyle(MDailyPressButtonStyle())
            }
        }
    }

    // MARK: - Sync & Save

    private func syncState(from tx: Transaction) {
        currentTransaction = tx
        editKind = tx.kind
        editAmountText = TransactionFormatHelper.formatEditableAmount("\(Int(tx.amount.rounded()))")
        editCategoryId = tx.categoryId
        editDate = tx.date
        editNote = tx.note ?? ""

        let linked = store.recurringTransactions.first { $0.linkedTransactionId == tx.id }
        isRecurring = linked != nil
        reminderDate = linked?.reminderDate ?? Date()
        repeatInterval = linked?.repeatInterval ?? .monthly
        showAmountError = false
    }

    private func saveEdits() {
        guard let amount = TransactionFormatHelper.parseEditableAmount(editAmountText) else {
            showAmountError = true
            return
        }

        let cleanNote = editNote.trimmingCharacters(in: .whitespacesAndNewlines)
        var updated = currentTransaction
        updated.kind = editKind
        updated.amount = amount
        updated.categoryId = editCategoryId
        updated.date = editDate
        updated.note = cleanNote.isEmpty ? nil : cleanNote
        updated.updatedAt = Date()

        store.updateTransaction(updated)
        currentTransaction = updated

        // Sync linked recurring reminder
        let existingLinked = store.recurringTransactions.first { $0.linkedTransactionId == updated.id }
        if isRecurring {
            let recurring = RecurringTransaction(
                id: existingLinked?.id ?? UUID(),
                kind: updated.kind,
                amount: updated.amount,
                categoryId: updated.categoryId,
                note: updated.note,
                reminderDate: reminderDate,
                repeatInterval: repeatInterval,
                isActive: true,
                linkedTransactionId: updated.id
            )
            if existingLinked != nil {
                store.updateRecurringTransaction(recurring)
            } else {
                store.addRecurringTransaction(recurring)
            }
            Task {
                _ = await NotificationService.shared.requestPermission()
            }
        } else if let existing = existingLinked {
            store.deleteRecurringTransaction(id: existing.id)
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing = false
        }
    }
}
