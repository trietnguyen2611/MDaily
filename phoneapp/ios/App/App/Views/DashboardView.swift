import SwiftUI

@MainActor
public struct DashboardView: View {
    @ObservedObject public var store: ExpenseStore
    public var expenses: [Expense]
    public var onSelectExpense: (Expense) -> Void
    public var onEditExpense: ((Expense) -> Void)?
    public var onShareExpense: ((Expense) -> Void)?

    @State private var expenseToDelete: Expense? = nil
    @State private var showDeleteConfirmation: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    // Computed amount range for dynamic card sizing
    private var amountRange: (min: Double, max: Double) {
        guard !expenses.isEmpty else { return (0, 1) }
        let amounts = expenses.map { $0.amount }
        let minAmt = amounts.min() ?? 0
        let maxAmt = amounts.max() ?? 1
        return (minAmt, max(minAmt + 1, maxAmt))
    }

    /// Dynamic card height based on expense amount relative to range
    private func cardHeight(for amount: Double) -> CGFloat {
        let range = amountRange
        let minHeight: CGFloat = 160
        let maxHeight: CGFloat = 320
        if range.max == range.min { return 200 }
        let ratio = (amount - range.min) / (range.max - range.min)
        return minHeight + CGFloat(ratio) * (maxHeight - minHeight)
    }

    /// Split expenses into two columns for waterfall layout
    private var waterfallColumns: ([Expense], [Expense]) {
        var leftColumn: [Expense] = []
        var rightColumn: [Expense] = []
        var leftHeight: CGFloat = 0
        var rightHeight: CGFloat = 0

        for expense in expenses {
            let h = cardHeight(for: expense.amount)
            if leftHeight <= rightHeight {
                leftColumn.append(expense)
                leftHeight += h + 14 // 14 = spacing
            } else {
                rightColumn.append(expense)
                rightHeight += h + 14
            }
        }
        return (leftColumn, rightColumn)
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            ScrollOffsetTracker()

            if expenses.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 84, height: 84)
                            .overlay(
                                Circle()
                                    .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.10), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.06), radius: 12, x: 0, y: 4)

                        Image(systemName: "receipt")
                            .font(.system(size: 38))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue, Color(red: 0, green: 0.7, blue: 0.95)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.top, 60)

                    Text(store.t("no_expenses"))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                // Waterfall / Pinterest-style 2-column layout
                let (leftCol, rightCol) = waterfallColumns

                HStack(alignment: .top, spacing: 14) {
                    // Left Column
                    VStack(spacing: 14) {
                        ForEach(leftCol, id: \.id) { expense in
                            expenseCard(for: expense)
                                .frame(height: cardHeight(for: expense.amount))
                                .id(expense.id)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                                    removal: .modifier(
                                        active: TelegramEvaporateModifier(isActive: true),
                                        identity: TelegramEvaporateModifier(isActive: false)
                                    )
                                ))
                        }
                    }

                    // Right Column
                    VStack(spacing: 14) {
                        ForEach(rightCol, id: \.id) { expense in
                            expenseCard(for: expense)
                                .frame(height: cardHeight(for: expense.amount))
                                .id(expense.id)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                                    removal: .modifier(
                                        active: TelegramEvaporateModifier(isActive: true),
                                        identity: TelegramEvaporateModifier(isActive: false)
                                    )
                                ))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 110)
            }
        }
        .coordinateSpace(name: "mdaily_scroll")
        .mask {
            VStack(spacing: 0) {
                // Top blur fade mask
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 14)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Rectangle()
                    .fill(Color.black)

                // Bottom blur fade mask
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 36)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0.0),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .alert(store.t("delete_confirm"), isPresented: $showDeleteConfirmation) {
            Button(store.t("delete"), role: .destructive) {
                if let exp = expenseToDelete {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        store.deleteExpense(id: exp.id)
                    }
                    expenseToDelete = nil
                }
            }
            Button(store.t("cancel"), role: .cancel) {
                expenseToDelete = nil
            }
        } message: {
            if let exp = expenseToDelete {
                Text("\(store.categoryLabel(for: exp.category)) • \(store.formatCurrency(exp.amount))")
            }
        }
    }

    @ViewBuilder
    private func expenseCard(for expense: Expense) -> some View {
        let isRecurring = store.recurringExpenses.contains(where: { $0.linkedExpenseId == expense.id && $0.isActive })

        if let photoData = expense.photoData, let uiImage = UIImage(data: photoData) {
            ExpensePhotoCard(
                expense: expense,
                uiImage: uiImage,
                store: store,
                isRecurring: isRecurring,
                onSelect: {
                    onSelectExpense(expense)
                },
                onDelete: {
                    expenseToDelete = expense
                    showDeleteConfirmation = true
                },
                onEdit: {
                    onEditExpense?(expense)
                },
                onShare: {
                    onShareExpense?(expense)
                }
            )
        } else {
            ExpenseTextCard(
                expense: expense,
                store: store,
                isRecurring: isRecurring,
                onSelect: {
                    onSelectExpense(expense)
                },
                onDelete: {
                    expenseToDelete = expense
                    showDeleteConfirmation = true
                },
                onEdit: {
                    onEditExpense?(expense)
                },
                onShare: {
                    onShareExpense?(expense)
                }
            )
        }
    }
}

// MARK: - Expense Photo Card Subview
private struct ExpensePhotoCard: View {
    let expense: Expense
    let uiImage: UIImage
    let store: ExpenseStore
    let isRecurring: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onShare: () -> Void

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd/MM/yyyy"
        return formatter.string(from: date)
    }

    private func categoryIconName(for id: String) -> String {
        switch id {
        case "bills": return "doc.text.fill"
        case "shopping": return "bag.fill"
        case "food": return "fork.knife"
        case "transport": return "car.fill"
        case "health": return "cross.case.fill"
        default: return "tag.fill"
        }
    }

    var body: some View {
        let catLabel = store.categoryLabel(for: expense.category)
        let timeStr = formatTime(expense.date)
        let hasNote = (expense.note?.isEmpty == false) && expense.note != "MDaily AI processed"

        ZStack(alignment: .topLeading) {
            // 1. Full Image Cover
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()

            // 2. Dual-Layer Vignette Gradient Overlay
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.70), location: 0.0),
                    .init(color: Color.black.opacity(0.15), location: 0.35),
                    .init(color: Color.black.opacity(0.20), location: 0.65),
                    .init(color: Color.black.opacity(0.80), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // 3. Top-right badges
            VStack {
                HStack(spacing: 6) {
                    Spacer()

                    // Recurring badge
                    if isRecurring {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.yellow)
                            .frame(width: 26, height: 26)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.50))
                                    .overlay(Circle().strokeBorder(Color.yellow.opacity(0.40), lineWidth: 0.5))
                            )
                    }

                    // Category icon
                    Image(systemName: categoryIconName(for: expense.category))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.50))
                                .overlay(Circle().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.5))
                        )
                }
                Spacer()
            }
            .padding(12)

            // 4. Card Content
            VStack(alignment: .leading, spacing: 2) {
                Text(timeStr)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)

                Text(catLabel)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)

                if hasNote, let note = expense.note {
                    FadingHorizontalText(
                        note,
                        font: .system(size: 13, weight: .regular, design: .rounded),
                        color: .white.opacity(0.92),
                        textShadow: true
                    )
                    .padding(.top, 1)
                }

                Spacer(minLength: 16)

                // Bottom: Amount Pill
                HStack(spacing: 8) {
                    Text(store.formatCurrency(expense.amount))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.62))
                        )

                    Spacer(minLength: 4)
                }
            }
            .padding(14)
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            Button {
                onSelect()
            } label: {
                Label(store.t("view_details"), systemImage: "eye")
            }

            Button {
                onEdit()
            } label: {
                Label(store.t("edit"), systemImage: "pencil")
            }

            Button {
                onShare()
            } label: {
                Label(store.t("share_image"), systemImage: "square.and.arrow.up")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(store.t("delete"), systemImage: "trash")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Expense Text Card Subview
private struct ExpenseTextCard: View {
    let expense: Expense
    let store: ExpenseStore
    let isRecurring: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onShare: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd/MM/yyyy"
        return formatter.string(from: date)
    }

    private func categoryIconName(for id: String) -> String {
        switch id {
        case "bills": return "doc.text.fill"
        case "shopping": return "bag.fill"
        case "food": return "fork.knife"
        case "transport": return "car.fill"
        case "health": return "cross.case.fill"
        default: return "tag.fill"
        }
    }

    var body: some View {
        let catLabel = store.categoryLabel(for: expense.category)
        let timeStr = formatTime(expense.date)
        let hasNote = (expense.note?.isEmpty == false) && expense.note != "MDaily AI processed"

        VStack(alignment: .leading, spacing: 0) {
            // Top: Time & badges
            HStack(spacing: 4) {
                Text(timeStr)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                Spacer()

                if isRecurring {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.orange)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.orange.opacity(0.14)))
                }

                Image(systemName: categoryIconName(for: expense.category))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.blue.opacity(0.14)))
            }
            .padding(.bottom, 6)

            // Category Title
            Text(catLabel)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .padding(.bottom, 2)

            // Note (Auto-Scrolling Marquee if long)
            if hasNote, let note = expense.note {
                FadingHorizontalText(
                    note,
                    font: .system(size: 13, weight: .regular, design: .rounded),
                    color: .secondary,
                    textShadow: false
                )
                .padding(.top, 1)
            }

            Spacer(minLength: 18)

            // Bottom: Amount
            HStack(spacing: 6) {
                Text(store.formatCurrency(expense.amount))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)

                Spacer(minLength: 4)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(colorScheme == .dark ? Color(white: 0.12).opacity(0.85) : Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05), radius: 10, x: 0, y: 4)
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            Button {
                onSelect()
            } label: {
                Label(store.t("view_details"), systemImage: "eye")
            }

            Button {
                onEdit()
            } label: {
                Label(store.t("edit"), systemImage: "pencil")
            }

            Button {
                onShare()
            } label: {
                Label(store.t("share_image"), systemImage: "square.and.arrow.up")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(store.t("delete"), systemImage: "trash")
            }
        }
    }
}

// MARK: - Custom Transitions
private struct TelegramEvaporateModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 0.75 : 1.0)
            .blur(radius: isActive ? 12 : 0)
            .opacity(isActive ? 0.0 : 1.0)
            .offset(y: isActive ? -25 : 0) // Float up slightly like dust
    }
}
