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
    @State private var extractResultText: String? = nil

    // Recurring expense fields
    @State private var isRecurring: Bool = false
    @State private var reminderDate: Date = Date()
    @State private var repeatInterval: RepeatInterval = .monthly

    private enum FormField {
        case amount, newCategory, note
    }
    @FocusState private var focusedField: FormField?

    @State private var isAddingCategory: Bool = false
    @State private var newCategoryName: String = ""
    @State private var showPhotoSourceDialog: Bool = false
    @State private var showCameraPicker: Bool = false
    @State private var showLibraryPicker: Bool = false
    @State private var showAmountError: Bool = false
    @State private var isFullscreenImage: Bool = false

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

    public func resetForm() {
        amountText = ""
        noteText = ""
        photoData = nil
        extractResultText = nil
        showAmountError = false
        isAddingCategory = false
        newCategoryName = ""
        isRecurring = false
        reminderDate = Date()
        repeatInterval = .monthly
    }

    private func formatAmountString(_ input: String) -> String {
        let cleanDigits = input.filter { $0.isNumber }
        guard !cleanDigits.isEmpty, let num = Double(cleanDigits) else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: num)) ?? cleanDigits
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
                            self.amountText = formatAmountString("\(Int(amount))")
                        }
                        // Auto-switch to bills category if invoice detected
                        if result.isInvoice {
                            self.selectedCategory = "bills"
                        } else if let cat = result.category {
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

        // Create recurring expense if enabled
        if isRecurring {
            let recurring = RecurringExpense(
                amount: amount,
                category: selectedCategory,
                note: cleanNote.isEmpty ? nil : cleanNote,
                photoData: photoData,
                reminderDate: reminderDate,
                repeatInterval: repeatInterval,
                isActive: true,
                linkedExpenseId: expense.id
            )
            store.addRecurringExpense(recurring)

            // Request notification permission if needed
            Task {
                let _ = await NotificationService.shared.requestPermission()
            }
        }

        resetForm()
        onSave()
    }

    public var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(showsIndicators: false) {
                ScrollOffsetTracker()

                VStack(spacing: 20) {
                    // Photo Upload / Preview Hero Card (Optimized for Portrait & Receipts)
                    if let photoData, let uiImage = UIImage(data: photoData) {
                        photoPreviewCard(uiImage: uiImage)
                    } else {
                        photoPlaceholderCard
                    }

                    // Inset Grouped Form
                    VStack(spacing: 16) {
                        // Amount Field
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(store.t("amount")) (\(store.currencySymbol))")
                                    .font(.appFont(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)

                                Spacer()

                                if showAmountError {
                                    Text(store.t("invalid_amount"))
                                        .font(.appFont(size: 12, weight: .medium))
                                        .foregroundColor(.red)
                                }
                            }

                            HStack {
                                TextField("0", text: $amountText)
                                    .keyboardType(.numberPad)
                                    .font(.appFont(size: 24, weight: .bold))
                                    .onChange(of: amountText) { _, newValue in
                                        showAmountError = false
                                        let formatted = formatAmountString(newValue)
                                        if formatted != newValue {
                                            amountText = formatted
                                        }
                                    }
                                    .focused($focusedField, equals: .amount)
                                    .id(FormField.amount)

                                Text(store.currencySymbol)
                                    .font(.appFont(size: 20, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        // Category Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text(store.t("category"))
                                .font(.appFont(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            Picker("Category", selection: $selectedCategory) {
                                ForEach(store.categories) { cat in
                                    Text(cat.localizedLabel(lang: store.language)).tag(cat.id)
                                }
                            }
                            .font(.appFont(size: 15, weight: .medium))
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
                                    .font(.appFont(size: 13, weight: .semibold))
                                    .foregroundColor(.blue)
                                }
                                .padding(.top, 2)
                            } else {
                                HStack {
                                    TextField(store.t("new_cat_placeholder"), text: $newCategoryName)
                                        .font(.appFont(size: 14, weight: .regular))
                                        .padding(10)
                                        .background(Color(.tertiarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .focused($focusedField, equals: .newCategory)
                                        .id(FormField.newCategory)

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
                                    .font(.appFont(size: 14, weight: .semibold))
                                    .buttonStyle(.borderedProminent)

                                    LiquidGlassCloseButton(size: 28) {
                                        isAddingCategory = false
                                        newCategoryName = ""
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }

                        // Note Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text(store.t("note"))
                                .font(.appFont(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            TextField(store.t("note_placeholder"), text: $noteText)
                                .font(.appFont(size: 15, weight: .regular))
                                .padding(14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .focused($focusedField, equals: .note)
                                .id(FormField.note)
                        }

                        // Recurring Payment Toggle
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $isRecurring) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bell.badge.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 16))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(store.t("recurring_reminder"))
                                            .font(.appFont(size: 15, weight: .medium))
                                        Text(store.t("recurring_reminder_desc"))
                                            .font(.appFont(size: 11, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(.orange)

                            if isRecurring {
                                VStack(spacing: 10) {
                                    // Reminder Date
                                    HStack {
                                        Text(store.t("reminder_date"))
                                            .font(.appFont(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        DatePicker("", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                            .environment(\.locale, Locale(identifier: store.language == .en ? "en_US" : "vi_VN"))
                                    }
                                    .padding(12)
                                    .background(Color(.tertiarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                    // Repeat Interval
                                    HStack {
                                        Text(store.t("repeat_interval"))
                                            .font(.appFont(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Picker("", selection: $repeatInterval) {
                                            ForEach(RepeatInterval.allCases) { interval in
                                                Text(interval.title(lang: store.language)).tag(interval)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }
                                    .padding(12)
                                    .background(Color(.tertiarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.top, 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isRecurring)
                    }
                    .padding(20)
                    .liquidGlass(cornerRadius: 28)

                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(store.t("cancel")) {
                            resetForm()
                            onCancel()
                        }
                        .font(.appFont(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .liquidGlass(cornerRadius: 22)
                        .liquidGlassButton()

                        Button(store.t("save_expense")) {
                            saveExpense()
                        }
                        .font(.appFont(size: 16, weight: .semibold))
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

                    // Extra bottom padding for keyboard
                    Color.clear.frame(height: 40)
                        .id("bottomAnchor")
                }
                .padding(16)
                .padding(.top, 12)
                .padding(.bottom, 110)
            }
            .coordinateSpace(name: "mdaily_scroll")
            .mask {
                VStack(spacing: 0) {
                    // Top Scroll Soft Fade Mask
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 14)

                    Rectangle()
                        .fill(Color.black)

                    // Bottom Scroll Soft Fade Mask
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 36)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .hideKeyboardOnTap()
            .onChange(of: focusedField) { _, newValue in
                if let field = newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            scrollProxy.scrollTo(field, anchor: .center)
                        }
                    }
                }
            }
        }
        .confirmationDialog(store.t("add_expense_photo"), isPresented: $showPhotoSourceDialog, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(store.t("take_photo_camera")) {
                    showCameraPicker = true
                }
            }
            Button(store.t("choose_from_library")) {
                showLibraryPicker = true
            }
            Button(store.t("cancel"), role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            QuickCameraView(
                onPhotoCaptured: { data in
                    processPhoto(data)
                },
                onDismiss: {
                    showCameraPicker = false
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showLibraryPicker) {
            ImagePickerView(sourceType: .photoLibrary) { image in
                if let data = image.jpegData(compressionQuality: 0.85) {
                    processPhoto(data)
                }
            }
        }
        .fullScreenCover(isPresented: $isFullscreenImage) {
            if let photoData, let uiImage = UIImage(data: photoData) {
                FullScreenImageViewer(uiImage: uiImage) {
                    isFullscreenImage = false
                }
            }
        }
        .onAppear {
            if let initialPhotoData, photoData == nil {
                processPhoto(initialPhotoData)
            }
        }
        .onDisappear {
            resetForm()
        }
        .onChange(of: initialPhotoData) { _, newData in
            if let newData {
                processPhoto(newData)
            }
        }
    }

    // MARK: - Subviews
    @ViewBuilder
    private func photoPreviewCard(uiImage: UIImage) -> some View {
        let isVertical = uiImage.size.height >= uiImage.size.width
        let previewHeight: CGFloat = isVertical ? 320 : 220

        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                // 1. Ambient Blurred Backdrop to fill card gracefully
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: previewHeight)
                    .blur(radius: 28)
                    .opacity(0.38)
                    .clipped()

                // 2. Optical Glass Tint Layer
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.30))
                    .frame(height: previewHeight)

                // 3. Foreground Uncropped High-Res Image (Preserves full vertical receipt / bill)
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: previewHeight - 24)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
                    .padding(12)

                // 4. Action Controls Bar (Zoom, Retake, Remove)
                HStack(spacing: 12) {
                    Button {
                        isFullscreenImage = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 38, height: 38)
                            .background(.thickMaterial)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }

                    Button {
                        showPhotoSourceDialog = true
                    } label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 38, height: 38)
                            .background(.thickMaterial)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            self.photoData = nil
                            self.extractResultText = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.red)
                            .frame(width: 38, height: 38)
                            .background(.thickMaterial)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(16)

                // 5. AI Extraction Loading Status
                if isExtracting {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .background(Color.black.opacity(0.35))

                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text(store.t("ai_recognizing"))
                                .font(.appFont(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.65)))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: previewHeight)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.75)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
            .contentShape(Rectangle())
            .onTapGesture {
                isFullscreenImage = true
            }

            if extractResultText != nil {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                    Text(store.t("ai_recognized_by"))
                        .font(.appFont(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .liquidGlassPill()
            }
        }
    }

    private var photoPlaceholderCard: some View {
        Button {
            showPhotoSourceDialog = true
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: "camera.badge.ellipsis")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.blue)
                }

                Text(store.t("add_photo"))
                    .font(.appFont(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(store.autoExtractEnabled ? store.t("ai_auto_extract") : store.t("take_photo"))
                    .font(.appFont(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 125)
            .liquidGlass(cornerRadius: 24)
        }
        .liquidGlassButton()
    }
}
