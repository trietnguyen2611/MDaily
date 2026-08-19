import SwiftUI
import PhotosUI

@MainActor
public struct AddExpenseView: View {
    @ObservedObject public var store: ExpenseStore
    public var initialPhotoData: Data?
    public var onSave: () -> Void
    public var onCancel: () -> Void

    @State private var amountText: String = ""
    @State private var selectedCategory: String = "shopping"
    @State private var noteText: String = ""
    @State private var photoData: Data?
    @State private var isExtracting: Bool = false
    @State private var extractResultText: String?
    @State private var isAddingCategory: Bool = false
    @State private var newCategoryName: String = ""
    @State private var showPhotoSourceDialog: Bool = false
    @State private var showCameraPicker: Bool = false
    @State private var showLibraryPicker: Bool = false
    @State private var showAmountError: Bool = false

    public init(
        store: ExpenseStore,
        initialPhotoData: Data? = nil,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.store = store
        self.initialPhotoData = initialPhotoData
        self.onSave = onSave
        self.onCancel = onCancel
    }

    private func processPhoto(_ data: Data) {
        self.photoData = data
        guard let uiImage = UIImage(data: data) else { return }

        if store.autoExtractEnabled {
            isExtracting = true
            extractResultText = nil

            Task {
                let result = await AFMService.shared.extractExpense(from: uiImage)
                await MainActor.run {
                    self.isExtracting = false
                    if result.success {
                        if let item = result.itemName, !item.isEmpty {
                            self.noteText = item
                        }
                        if let amount = result.amount, amount > 0 {
                            self.amountText = "\(Int(amount))"
                        }
                        if let cat = result.category {
                            if store.categories.contains(where: { $0.id == cat }) {
                                self.selectedCategory = cat
                            }
                        }
                        if let item = result.itemName {
                            self.extractResultText = "✨ \(item)"
                        }
                    }
                }
            }
        }
    }

    private func saveExpense() {
        let cleanDigits = amountText
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let amount = Double(cleanDigits), amount > 0 else {
            showAmountError = true
            return
        }

        let cleanNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let expense = Expense(
            amount: amount,
            category: selectedCategory,
            date: Date(),
            note: cleanNote.isEmpty ? nil : cleanNote,
            photoData: photoData,
            isAiProcessed: extractResultText != nil
        )

        store.addExpense(expense)

        // Reset state
        amountText = ""
        noteText = ""
        photoData = nil
        extractResultText = nil
        showAmountError = false

        onSave()
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Photo Upload / Preview Hero Card
                if let photoData, let uiImage = UIImage(data: photoData) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                        Button {
                            self.photoData = nil
                            self.extractResultText = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(12)

                        if isExtracting {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.black.opacity(0.6))
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(.white)
                                    Text("AI đang nhận diện...")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .liquidGlass(cornerRadius: 24)

                    if let extractResultText {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                            Text(extractResultText)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .liquidGlassPill()
                    }
                } else {
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showPhotoSourceDialog = true
                        } else {
                            showLibraryPicker = true
                        }
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.badge.ellipsis")
                                .font(.system(size: 36))
                                .foregroundColor(.blue)

                            Text(store.t("add_photo"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            Text(store.autoExtractEnabled ? store.t("ai_auto_extract") : store.t("take_photo"))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 130)
                        .liquidGlass(cornerRadius: 24)
                    }
                    .liquidGlassButton()
                }

                // Inset Grouped Form
                VStack(spacing: 16) {
                    // Amount Field
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(store.t("amount")) (\(store.currencySymbol))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            Spacer()

                            if showAmountError {
                                Text("Vui lòng nhập số tiền hợp lệ")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.red)
                            }
                        }

                        HStack {
                            TextField("0", text: $amountText)
                                .keyboardType(.numberPad)
                                .font(.system(size: 24, weight: .bold))
                                .onChange(of: amountText) { _, _ in
                                    showAmountError = false
                                }

                            Text(store.currencySymbol)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    // Category Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.t("category"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Picker("Category", selection: $selectedCategory) {
                            ForEach(store.categories) { cat in
                                Text(cat.label).tag(cat.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        if !isAddingCategory {
                            Button {
                                isAddingCategory = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text(store.t("add_new_category"))
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.blue)
                            }
                            .padding(.top, 2)
                        } else {
                            HStack {
                                TextField(store.t("new_cat_placeholder"), text: $newCategoryName)
                                    .padding(10)
                                    .background(Color(.tertiarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                Button(store.t("save")) {
                                    let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                                    if !trimmed.isEmpty {
                                        store.addCategory(label: trimmed)
                                        if let last = store.categories.last {
                                            selectedCategory = last.id
                                        }
                                        newCategoryName = ""
                                        isAddingCategory = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)

                                Button {
                                    isAddingCategory = false
                                    newCategoryName = ""
                                } label: {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }

                    // Note Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.t("note"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        TextField(store.t("note_placeholder"), text: $noteText)
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(20)
                .liquidGlass(cornerRadius: 28)

                // Action Buttons
                HStack(spacing: 12) {
                    Button(store.t("cancel")) {
                        onCancel()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .liquidGlass(cornerRadius: 22)
                    .liquidGlassButton()

                    Button(store.t("save_expense")) {
                        saveExpense()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color(red: 0, green: 0.45, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color.blue.opacity(0.35), radius: 10, x: 0, y: 4)
                    .liquidGlassButton()
                }
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .confirmationDialog("Thêm ảnh chi tiêu", isPresented: $showPhotoSourceDialog, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Chụp ảnh từ Máy ảnh") {
                    showCameraPicker = true
                }
            }
            Button("Chọn từ Thư viện ảnh") {
                showLibraryPicker = true
            }
            Button("Huỷ", role: .cancel) {}
        }
        .sheet(isPresented: $showCameraPicker) {
            ImagePickerView(sourceType: .camera) { image in
                if let data = image.jpegData(compressionQuality: 0.85) {
                    processPhoto(data)
                }
            }
        }
        .sheet(isPresented: $showLibraryPicker) {
            ImagePickerView(sourceType: .photoLibrary) { image in
                if let data = image.jpegData(compressionQuality: 0.85) {
                    processPhoto(data)
                }
            }
        }
        .onAppear {
            if let initialPhotoData {
                processPhoto(initialPhotoData)
            }
        }
    }
}
