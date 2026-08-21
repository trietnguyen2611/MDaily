import SwiftUI

@MainActor
public struct ExpenseDetailSheet: View {
    @ObservedObject public var store: ExpenseStore
    public var expense: Expense
    public var onClose: () -> Void

    @State private var currentExpense: Expense
    @State private var isEditing: Bool = false
    @State private var editAmountText: String = ""
    @State private var editCategory: String = ""
    @State private var editNote: String = ""
    @State private var editDate: Date
    @State private var isFullscreenImage: Bool = false
    @State private var showDeleteModal: Bool = false

    private enum EditField: Hashable {
        case amount, note
    }
    @FocusState private var focusedEditField: EditField?

    private static func formatAmountString(_ input: String) -> String {
        let cleanDigits = input.filter { $0.isNumber }
        guard !cleanDigits.isEmpty, let num = Double(cleanDigits) else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: num)) ?? cleanDigits
    }

    public init(
        store: ExpenseStore,
        expense: Expense,
        startInEditMode: Bool = false,
        onClose: @escaping () -> Void
    ) {
        self.store = store
        self.expense = expense
        self.onClose = onClose

        _isEditing = State(initialValue: startInEditMode)
        _currentExpense = State(initialValue: expense)
        _editAmountText = State(initialValue: ExpenseDetailSheet.formatAmountString("\(Int(expense.amount))"))
        _editCategory = State(initialValue: expense.category)
        _editNote = State(initialValue: expense.note ?? "")
        _editDate = State(initialValue: expense.date)
    }

    private func syncState(from exp: Expense) {
        currentExpense = exp
        editAmountText = ExpenseDetailSheet.formatAmountString("\(Int(exp.amount))")
        editCategory = exp.category
        editNote = exp.note ?? ""
        editDate = exp.date
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd/MM/yyyy"
        return formatter.string(from: date)
    }

    public var body: some View {
        NavigationView {
            ZStack {
                ScrollViewReader { scrollProxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Full-Height Uncropped Photo with Ambient Blur
                            if let photoData = currentExpense.photoData, let uiImage = UIImage(data: photoData) {
                                ZStack {
                                    // Ambient blurred backdrop
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 240)
                                        .blur(radius: 25)
                                        .opacity(0.4)
                                        .clipped()

                                    // Foreground uncropped image
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 240)
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)

                                    // Tap hint
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Button {
                                                isFullscreenImage = true
                                            } label: {
                                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.primary)
                                                    .frame(width: 36, height: 36)
                                                    .background(.ultraThinMaterial)
                                                    .clipShape(Circle())
                                                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                                            }
                                            .padding(12)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .liquidGlass(cornerRadius: 24)
                            }

                            // Hero Amount Display / Edit
                            VStack(spacing: 6) {
                                Text(store.t("expense_amount"))
                                    .font(.appFont(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)

                                if isEditing {
                                    HStack {
                                        TextField("0", text: $editAmountText)
                                            .keyboardType(.numberPad)
                                            .font(.appFont(size: 32, weight: .bold))
                                            .multilineTextAlignment(.center)
                                            .focused($focusedEditField, equals: .amount)
                                            .onChange(of: editAmountText) { _, newValue in
                                                let formatted = ExpenseDetailSheet.formatAmountString(newValue)
                                                if formatted != newValue {
                                                    editAmountText = formatted
                                                }
                                            }
                                        Text(store.currencySymbol)
                                            .font(.appFont(size: 24, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                    .id(EditField.amount)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                } else {
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text(store.formatCurrency(currentExpense.amount))
                                            .font(.appFont(size: 34, weight: .bold))
                                            .foregroundColor(.primary)
                                    }
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isEditing)

                            // Inset Grouped Section
                            VStack(spacing: 0) {
                                // Category Row
                                HStack {
                                    Label {
                                        Text(store.t("category"))
                                            .font(.appFont(size: 16, weight: .medium))
                                    } icon: {
                                        Image(systemName: "tag.fill")
                                            .foregroundColor(.blue)
                                    }

                                    Spacer()

                                    if isEditing {
                                        Picker("", selection: $editCategory) {
                                            ForEach(store.categories) { cat in
                                                Text(cat.localizedLabel(lang: store.language)).tag(cat.id)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .transition(.opacity)
                                    } else {
                                        Text(store.categoryLabel(for: currentExpense.category))
                                            .font(.appFont(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .transition(.opacity)
                                    }
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isEditing)

                                Divider()
                                    .padding(.leading, 44)

                                // Time Row (editable with DatePicker)
                                HStack {
                                    Label {
                                        Text(store.t("time"))
                                            .font(.appFont(size: 16, weight: .medium))
                                    } icon: {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.blue)
                                    }

                                    Spacer()

                                    if isEditing {
                                        DatePicker(
                                            "",
                                            selection: $editDate,
                                            displayedComponents: [.date, .hourAndMinute]
                                        )
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .environment(\.locale, Locale(identifier: store.language == .en ? "en_US" : "vi_VN"))
                                        .transition(.opacity)
                                    } else {
                                        Text(formatDate(currentExpense.date))
                                            .font(.appFont(size: 15, weight: .regular))
                                            .foregroundColor(.secondary)
                                            .transition(.opacity)
                                    }
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isEditing)

                                Divider()
                                    .padding(.leading, 44)

                                // AI Processed Badge (if applicable)
                                if currentExpense.isAiProcessed {
                                    HStack {
                                        Label {
                                            Text(store.t("ai_recognized_by"))
                                                .font(.appFont(size: 16, weight: .medium))
                                        } icon: {
                                            Image(systemName: "sparkles")
                                                .foregroundColor(.purple)
                                        }

                                        Spacer()

                                        Text("MDaily AI")
                                            .font(.appFont(size: 13, weight: .semibold))
                                            .foregroundColor(.purple)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.purple.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)

                                    Divider()
                                        .padding(.leading, 44)
                                }

                                // Note Row
                                HStack(alignment: isEditing ? .top : .center) {
                                    Label {
                                        Text(store.t("note"))
                                            .font(.appFont(size: 16, weight: .medium))
                                    } icon: {
                                        Image(systemName: "note.text")
                                            .foregroundColor(.blue)
                                    }

                                    Spacer()

                                    if isEditing {
                                        TextField(store.t("note_placeholder"), text: $editNote)
                                            .font(.appFont(size: 15, weight: .regular))
                                            .multilineTextAlignment(.trailing)
                                            .focused($focusedEditField, equals: .note)
                                            .transition(.opacity)
                                    } else {
                                        Text(currentExpense.note ?? store.t("no_note"))
                                            .font(.appFont(size: 15, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                            .transition(.opacity)
                                    }
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .id(EditField.note)
                                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isEditing)
                            }
                            .liquidGlass(cornerRadius: 24)

                            // Danger Zone Delete Button
                            Button {
                                showDeleteModal = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text(store.t("delete_this_expense"))
                                }
                                .font(.appFont(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.red.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                            .padding(.top, 10)

                            // Extra bottom padding for keyboard
                            Color.clear.frame(height: 120)
                                .id("bottomAnchor")
                        }
                        .padding(16)
                    }
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .black, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 12)

                            Rectangle()
                                .fill(Color.black)

                            LinearGradient(
                                stops: [
                                    .init(color: .black, location: 0.0),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 24)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .hideKeyboardOnTap()
                    .onChange(of: focusedEditField) { _, newField in
                        guard let field = newField else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                scrollProxy.scrollTo(field, anchor: .center)
                            }
                        }
                    }
                }
            }
            .alert(store.t("delete_confirm"), isPresented: $showDeleteModal) {
                Button(store.t("delete"), role: .destructive) {
                    store.deleteExpense(id: currentExpense.id)
                    onClose()
                }
                Button(store.t("cancel"), role: .cancel) {}
            } message: {
                Text("\(store.categoryLabel(for: currentExpense.category)) • \(store.formatCurrency(currentExpense.amount))")
            }
            .navigationTitle(isEditing ? store.t("edit_expense") : store.t("expense_details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // LEFT: Edit button when viewing / Cancel button when editing
                ToolbarItem(placement: .cancellationAction) {
                    if isEditing {
                        Button(store.t("cancel")) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                focusedEditField = nil
                                syncState(from: currentExpense)
                                isEditing = false
                            }
                        }
                        .font(.appFont(size: 16, weight: .regular))
                    } else {
                        Button(store.t("edit")) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                isEditing = true
                            }
                        }
                        .font(.appFont(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                    }
                }

                // RIGHT: Close (X) when viewing / Done (Save) when editing
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button(store.t("done")) {
                            let cleanDigits = editAmountText.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ".", with: "")
                            if let amount = Double(cleanDigits), amount > 0 {
                                var updated = currentExpense
                                updated.amount = amount
                                updated.category = editCategory
                                updated.note = editNote.trimmingCharacters(in: .whitespaces).isEmpty ? nil : editNote.trimmingCharacters(in: .whitespaces)
                                updated.date = editDate
                                store.updateExpense(updated)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    focusedEditField = nil
                                    currentExpense = updated
                                    isEditing = false
                                }
                            }
                        }
                        .font(.appFont(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                    } else {
                        LiquidGlassCloseButton(size: 32) {
                            onClose()
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $isFullscreenImage) {
                if let photoData = currentExpense.photoData, let uiImage = UIImage(data: photoData) {
                    FullScreenImageViewer(uiImage: uiImage) {
                        isFullscreenImage = false
                    }
                }
            }
        }
        .onAppear {
            syncState(from: expense)
        }
    }
}
