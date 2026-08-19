import SwiftUI

@MainActor
public struct ExpenseDetailSheet: View {
    @ObservedObject public var store: ExpenseStore
    @Binding public var expense: Expense?
    public var onClose: () -> Void

    @State private var isEditing: Bool = false
    @State private var editAmountText: String = ""
    @State private var editCategory: String = ""
    @State private var editNote: String = ""
    @State private var isFullscreenImage: Bool = false
    @State private var showDeleteAlert: Bool = false

    private func setupInitialState(for exp: Expense) {
        editAmountText = "\(Int(exp.amount))"
        editCategory = exp.category
        editNote = exp.note ?? ""
        isEditing = false
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy · HH:mm"
        return formatter.string(from: date)
    }

    public var body: some View {
        if let currentExpense = expense {
            NavigationView {
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
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .font(.system(size: 11))
                                            Text(store.t("view_full"))
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(Color.black.opacity(0.6)))
                                        .padding(12)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .liquidGlass(cornerRadius: 24)
                            .onTapGesture {
                                isFullscreenImage = true
                            }
                        }

                        // Hero Amount Display / Edit
                        VStack(spacing: 6) {
                            Text(store.t("expense_amount"))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)

                            if isEditing {
                                HStack {
                                    TextField("0", text: $editAmountText)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 32, weight: .bold))
                                        .multilineTextAlignment(.center)
                                    Text(store.currencySymbol)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(store.formatCurrency(currentExpense.amount))
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)

                        // Inset Grouped Section
                        VStack(spacing: 0) {
                            // Category Row
                            HStack {
                                Label {
                                    Text(store.t("category"))
                                        .font(.system(size: 16))
                                } icon: {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(.blue)
                                }

                                Spacer()

                                if isEditing {
                                    Picker("", selection: $editCategory) {
                                        ForEach(store.categories) { cat in
                                            Text(cat.label).tag(cat.id)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                } else {
                                    Text(store.categoryLabel(for: currentExpense.category))
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)

                            Divider().padding(.leading, 44)

                            // Date Row
                            HStack {
                                Label {
                                    Text(store.t("time"))
                                        .font(.system(size: 16))
                                } icon: {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.orange)
                                }

                                Spacer()

                                Text(formatDate(currentExpense.date))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)

                            Divider().padding(.leading, 44)

                            // Note Row
                            HStack {
                                Label {
                                    Text(store.t("note"))
                                        .font(.system(size: 16))
                                } icon: {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.purple)
                                }

                                Spacer()

                                if isEditing {
                                    TextField(store.t("note_placeholder"), text: $editNote)
                                        .multilineTextAlignment(.trailing)
                                } else {
                                    Text(currentExpense.note ?? store.t("no_note"))
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                        }
                        .liquidGlass(cornerRadius: 24)

                        // Danger Zone Delete Button
                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text(store.t("delete_this_expense"))
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .padding(.top, 10)
                    }
                    .padding(16)
                }
                .navigationTitle(isEditing ? store.t("edit_expense") : store.t("expense_details"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        if isEditing {
                            Button(store.t("cancel")) {
                                setupInitialState(for: currentExpense)
                            }
                        } else {
                            Button {
                                onClose()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        if isEditing {
                            Button(store.t("done")) {
                                if let amount = Double(editAmountText.replacingOccurrences(of: ",", with: "")), amount > 0 {
                                    var updated = currentExpense
                                    updated.amount = amount
                                    updated.category = editCategory
                                    updated.note = editNote.trimmingCharacters(in: .whitespaces).isEmpty ? nil : editNote.trimmingCharacters(in: .whitespaces)
                                    store.updateExpense(updated)
                                    self.expense = updated
                                    isEditing = false
                                }
                            }
                            .fontWeight(.semibold)
                        } else {
                            Button(store.t("edit")) {
                                isEditing = true
                            }
                        }
                    }
                }
                .alert(store.t("delete_confirm"), isPresented: $showDeleteAlert) {
                    Button(store.t("delete"), role: .destructive) {
                        store.deleteExpense(id: currentExpense.id)
                        onClose()
                    }
                    Button(store.t("cancel"), role: .cancel) {}
                }
                .fullScreenCover(isPresented: $isFullscreenImage) {
                    if let photoData = currentExpense.photoData, let uiImage = UIImage(data: photoData) {
                        ZStack(alignment: .topTrailing) {
                            Color.black.ignoresSafeArea()

                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                            Button {
                                isFullscreenImage = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(24)
                            }
                        }
                    }
                }
            }
            .onAppear {
                setupInitialState(for: currentExpense)
            }
        }
    }
}
