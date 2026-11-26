import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

@MainActor
public struct AddTransactionView: View {
    @ObservedObject public var store: FinanceStore
    public var initialPhotoData: Data?
    public var layoutProfile: AdaptiveLayoutProfile
    public var onSave: () -> Void
    public var onCancel: () -> Void

    @State private var selectedKind: TransactionKind = .expense
    @State private var amountText: String = ""
    @State private var selectedCategoryId: String = "shopping"
    @State private var selectedDate: Date = Date()
    @State private var noteText: String = ""
    @State private var photoData: Data?

    @State private var isExtracting: Bool = false
    @State private var aiExtractedLabel: String? = nil

    // Inline Category Creation
    @State private var isAddingCategory: Bool = false
    @State private var newCategoryName: String = ""

    // Recurring reminder
    @State private var isRecurring: Bool = false
    @State private var reminderDate: Date = Date()
    @State private var repeatInterval: RepeatInterval = .monthly

    // Pickers & Validation
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showCameraCapture: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var isDropTargeted: Bool = false
    @State private var showAmountError: Bool = false
    @State private var showFullscreenImage: Bool = false

    @FocusState private var focusedField: FormField?

    private enum FormField: Hashable {
        case amount, newCategory, note
    }

    public init(
        store: FinanceStore,
        initialPhotoData: Data? = nil,
        layoutProfile: AdaptiveLayoutProfile,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.store = store
        self.initialPhotoData = initialPhotoData
        self.layoutProfile = layoutProfile
        self.onSave = onSave
        self.onCancel = onCancel
    }

    private var isEnglish: Bool { store.language == .en }

    private var filteredCategories: [CategoryItem] {
        store.categories.filter { $0.kind == selectedKind }
    }

    private var horizontalPadding: CGFloat {
        switch layoutProfile {
        case .iPhoneDuoFolded: return 14
        case .standardPhone: return 16
        case .iPhoneDuoUnfolded, .pad, .mac: return 24
        }
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                headerRow
                kindToggleSection
                photoSection
                formCardSection
                actionButtonsRow
            }
            .frame(maxWidth: 700, alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, layoutProfile == .standardPhone ? 104 : 36)
        }
        .mdailySoftScrollEdges()
        .background(Color.mdailyCanvas.ignoresSafeArea())
        #if os(iOS)
        .scrollDismissesKeyboard(.interactively)
        #endif
        .onAppear {
            syncCategoryForCurrentKind()
            if let initialPhotoData, photoData == nil {
                processPhoto(initialPhotoData)
            }
        }
        .onChange(of: initialPhotoData) { _, newData in
            if let newData {
                processPhoto(newData)
            }
        }
        .onChange(of: selectedKind) { _, _ in
            syncCategoryForCurrentKind()
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        processPhoto(data)
                        selectedPhotoItem = nil
                    }
                }
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showCameraCapture) {
            QuickCaptureView(
                store: store,
                onPhotoCaptured: { data in
                    processPhoto(data)
                },
                onDismiss: {
                    showCameraCapture = false
                }
            )
        }
        #endif
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                let needsAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if needsAccess { url.stopAccessingSecurityScopedResource() }
                }
                if let data = try? Data(contentsOf: url) {
                    processPhoto(data)
                }
            }
        }
        .sheet(isPresented: $showFullscreenImage) {
            if let photoData {
                ReceiptImagePreviewSheet(photoData: photoData) {
                    showFullscreenImage = false
                }
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text(isEnglish ? "New Transaction" : "Thêm giao dịch")
                .font(.system(size: layoutProfile == .iPhoneDuoFolded ? 26 : 32, weight: .semibold))
                .tracking(-0.37)

            Spacer()

            Button {
                resetForm()
                onCancel()
            } label: {
                Text(isEnglish ? "Cancel" : "Huỷ")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 6)
            }
            .buttonBorderShape(.capsule)
            .mdailyGlassButton(prominent: false)
        }
    }

    // MARK: - Kind Segmented Toggle

    private var kindToggleSection: some View {
        HStack(spacing: 4) {
            ForEach(TransactionKind.allCases) { kind in
                let isSelected = selectedKind == kind
                let activeColor: Color = kind == .income ? Color.mdailyIncomeGreen : Color.mdailyActionBlue

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedKind = kind
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: kind == .income ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(kind.title(lang: store.language))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        isSelected ? activeColor : Color.clear,
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .mdailyGlassPill(interactive: true)
    }

    // MARK: - Photo & Receipt Section

    @ViewBuilder
    private var photoSection: some View {
        let english = isEnglish
        if let photoData, let image = Image(platformImageData: photoData) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .onTapGesture {
                            showFullscreenImage = true
                        }

                    HStack(spacing: 6) {
                        Button {
                            showFullscreenImage = true
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 28, height: 28)
                        }
                        .buttonBorderShape(.circle)
                        .mdailyGlassButton(prominent: false)

                        Button {
                            withAnimation {
                                self.photoData = nil
                                self.aiExtractedLabel = nil
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 28, height: 28)
                        }
                        .buttonBorderShape(.circle)
                        .mdailyGlassButton(prominent: false)
                    }
                    .padding(8)
                }

                HStack(spacing: 8) {
                    if isExtracting {
                        ProgressView()
                            .controlSize(.small)
                        Text(english ? "Extracting…" : "Đang nhận diện…")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                    } else if let label = aiExtractedLabel {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.mdailyActionBlue)
                        Text(label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.mdailyActionBlue)
                            .lineLimit(1)
                    } else {
                        Button {
                            processPhoto(photoData, forceExtract: true)
                        } label: {
                            Label(english ? "AI Extract" : "Nhận diện AI", systemImage: "sparkles")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .buttonBorderShape(.capsule)
                        .mdailyGlassButton(prominent: false)
                    }

                    Spacer()
                }
            }
            .padding(14)
            .mdailyCard(cornerRadius: 18)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(Color.mdailyActionBlue)

                Text(english ? "Receipt Photo" : "Ảnh hoá đơn")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 10) {
                    #if os(iOS)
                    Button {
                        showCameraCapture = true
                    } label: {
                        Label(english ? "Camera" : "Chụp ảnh", systemImage: "camera")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonBorderShape(.capsule)
                    .mdailyGlassButton(prominent: true)
                    #endif

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(english ? "Library" : "Thư viện", systemImage: "photo.on.rectangle")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonBorderShape(.capsule)
                    .mdailyGlassButton(prominent: false)

                    #if os(macOS)
                    Button {
                        showFileImporter = true
                    } label: {
                        Label(english ? "File…" : "Tệp…", systemImage: "folder")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonBorderShape(.capsule)
                    .mdailyGlassButton(prominent: false)
                    #endif
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .mdailyCard(cornerRadius: 18)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isDropTargeted ? Color.mdailyActionBlue : Color.clear,
                        lineWidth: 2
                    )
            )
            .dropDestination(for: Data.self) { items, _ in
                guard let data = items.first, Image(platformImageData: data) != nil else {
                    return false
                }
                processPhoto(data)
                return true
            } isTargeted: { targeted in
                isDropTargeted = targeted
            }
        }
    }

    // MARK: - Form Card

    private var formCardSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Amount
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(isEnglish ? "Amount" : "Số tiền") (\(store.currency.symbol))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if showAmountError {
                        Text(isEnglish ? "Invalid amount" : "Số tiền không hợp lệ")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                }

                HStack(spacing: 8) {
                    TextField("0", text: $amountText)
                        .platformNumericKeyboard()
                        .font(.system(size: 28, weight: .semibold))
                        .monospacedDigit()
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .amount)
                        .onChange(of: amountText) { _, newValue in
                            showAmountError = false
                            let formatted = TransactionFormatHelper.formatEditableAmount(newValue)
                            if formatted != newValue {
                                amountText = formatted
                            }
                        }

                    Text(store.currency.symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .mdailyGlassSurface(in: RoundedRectangle(cornerRadius: 12, style: .continuous), interactive: true)
            }

            Divider().overlay(Color.mdailyHairline)

            // Category + Inline Add
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(isEnglish ? "Category" : "Danh mục")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isAddingCategory.toggle()
                        }
                    } label: {
                        Image(systemName: isAddingCategory ? "xmark" : "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonBorderShape(.circle)
                    .mdailyGlassButton(prominent: false)
                }

                if isAddingCategory {
                    HStack(spacing: 8) {
                        TextField(
                            isEnglish ? "Category name…" : "Tên danh mục…",
                            text: $newCategoryName
                        )
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .focused($focusedField, equals: .newCategory)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .mdailyGlassSurface(in: RoundedRectangle(cornerRadius: 10, style: .continuous), interactive: true)

                        Button {
                            createInlineCategory()
                        } label: {
                            Text(isEnglish ? "Add" : "Tạo")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .buttonBorderShape(.capsule)
                        .mdailyGlassButton(prominent: true)
                    }
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 112), spacing: 8)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(filteredCategories) { cat in
                        let isSelected = selectedCategoryId == cat.id
                        let tint: Color = selectedKind == .income ? Color.mdailyIncomeGreen : Color.mdailyActionBlue

                        Button {
                            selectedCategoryId = cat.id
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: cat.resolvedIconName)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(cat.localizedLabel(lang: store.language))
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .mdailyGlassSurface(
                                in: RoundedRectangle(cornerRadius: 11, style: .continuous),
                                interactive: true,
                                tint: isSelected ? tint : nil
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().overlay(Color.mdailyHairline)

            // Date & Time
            HStack {
                Label {
                    Text(isEnglish ? "Date & Time" : "Thời gian")
                        .font(.system(size: 14, weight: .semibold))
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.mdailyActionBlue)
                }

                Spacer()

                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.compact)
            }

            Divider().overlay(Color.mdailyHairline)

            // Note
            VStack(alignment: .leading, spacing: 6) {
                Text(isEnglish ? "Note" : "Ghi chú")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField(
                    isEnglish ? "Note…" : "Ghi chú…",
                    text: $noteText
                )
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .regular))
                .focused($focusedField, equals: .note)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .mdailyGlassSurface(in: RoundedRectangle(cornerRadius: 12, style: .continuous), interactive: true)
            }

            Divider().overlay(Color.mdailyHairline)

            // Recurring Reminder
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $isRecurring) {
                    Label {
                        Text(isEnglish ? "Recurring" : "Định kỳ")
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
                            .font(.system(size: 14))
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
                    .font(.system(size: 14))
                }
            }
        }
        .padding(16)
        .mdailyCard(cornerRadius: 18)
    }

    // MARK: - Action Buttons

    private var actionButtonsRow: some View {
        HStack(spacing: 12) {
            Button {
                resetForm()
                onCancel()
            } label: {
                Text(isEnglish ? "Cancel" : "Huỷ")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonBorderShape(.capsule)
            .mdailyGlassButton(prominent: false)

            Button {
                saveTransaction()
            } label: {
                Text(isEnglish ? "Save" : "Lưu")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonBorderShape(.capsule)
            .mdailyGlassButton(prominent: true)
        }
    }

    // MARK: - Logic

    private func syncCategoryForCurrentKind() {
        if !filteredCategories.contains(where: { $0.id == selectedCategoryId }) {
            if let first = filteredCategories.first {
                selectedCategoryId = first.id
            }
        }
    }

    private func createInlineCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let created = store.addCategory(
            label: trimmed,
            kind: selectedKind,
            iconSymbol: selectedKind == .income ? "plus.circle.fill" : "tag.fill"
        )
        selectedCategoryId = created.id
        newCategoryName = ""
        isAddingCategory = false
    }

    private func processPhoto(_ data: Data, forceExtract: Bool = false) {
        photoData = data
        guard store.autoExtractEnabled || forceExtract else { return }

        isExtracting = true
        aiExtractedLabel = nil

        Task {
            let result = await AFMService.shared.extractTransaction(from: data)
            await MainActor.run {
                self.isExtracting = false
                if result.success {
                    self.selectedKind = result.kind
                    if let amount = result.amount, amount > 0 {
                        self.amountText = TransactionFormatHelper.formatEditableAmount("\(Int(amount.rounded()))")
                    }
                    if result.isInvoice,
                       result.kind == .expense,
                       result.categoryId == nil,
                       store.categories.contains(where: { $0.id == "bills" }) {
                        self.selectedCategoryId = "bills"
                    } else if let catId = result.categoryId,
                              let cat = store.categories.first(where: { $0.id == catId }) {
                        self.selectedKind = cat.kind
                        self.selectedCategoryId = cat.id
                    } else {
                        self.syncCategoryForCurrentKind()
                    }
                    if let itemName = result.itemName, !itemName.isEmpty, self.noteText.isEmpty {
                        self.noteText = itemName
                    }
                    self.aiExtractedLabel = result.itemName ?? "MDaily AI"
                }
            }
        }
    }

    private func saveTransaction() {
        guard let amount = TransactionFormatHelper.parseEditableAmount(amountText) else {
            showAmountError = true
            focusedField = .amount
            return
        }

        let cleanNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let tx = Transaction(
            kind: selectedKind,
            amount: amount,
            categoryId: selectedCategoryId,
            date: selectedDate,
            note: cleanNote.isEmpty ? nil : cleanNote,
            photoData: photoData,
            isAiProcessed: aiExtractedLabel != nil
        )

        store.addTransaction(tx)

        if isRecurring {
            let recurring = RecurringTransaction(
                kind: selectedKind,
                amount: amount,
                categoryId: selectedCategoryId,
                note: cleanNote.isEmpty ? nil : cleanNote,
                reminderDate: reminderDate,
                repeatInterval: repeatInterval,
                isActive: true,
                linkedTransactionId: tx.id
            )
            store.addRecurringTransaction(recurring)
            Task {
                _ = await NotificationService.shared.requestPermission()
            }
        }

        resetForm()
        onSave()
    }

    private func resetForm() {
        amountText = ""
        noteText = ""
        photoData = nil
        aiExtractedLabel = nil
        showAmountError = false
        isAddingCategory = false
        newCategoryName = ""
        isRecurring = false
        reminderDate = Date()
        repeatInterval = .monthly
        selectedDate = Date()
    }
}

// MARK: - Cross-Platform Fullscreen Image Sheet

struct ReceiptImagePreviewSheet: View {
    let photoData: Data
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let image = Image(platformImageData: photoData) {
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                scale = max(1.0, min(4.0, value.magnification))
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if scale < 1.05 { scale = 1.0 }
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            scale = scale > 1.1 ? 1.0 : 2.2
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(16)
            }

            MDailyCloseButton(action: onDismiss)
                .padding(18)
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 520)
        #endif
    }
}
