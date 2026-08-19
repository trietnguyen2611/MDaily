import SwiftUI

@MainActor
public struct DashboardView: View {
    @ObservedObject public var store: ExpenseStore
    public var expenses: [Expense]
    public var onSelectExpense: (Expense) -> Void

    @State private var expenseToDelete: Expense? = nil
    @State private var showDeleteConfirmation: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public var body: some View {
        ScrollView(showsIndicators: false) {
            if expenses.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 84, height: 84)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.3 : 0.8), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)

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
                    .padding(.top, 70)

                    Text(store.t("no_expenses"))
                        .font(.appFont(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(expenses, id: \.id) { expense in
                        if let photoData = expense.photoData, let uiImage = UIImage(data: photoData) {
                            ExpensePhotoCard(
                                expense: expense,
                                uiImage: uiImage,
                                store: store,
                                onSelect: {
                                    onSelectExpense(expense)
                                },
                                onDelete: {
                                    expenseToDelete = expense
                                    showDeleteConfirmation = true
                                }
                            )
                            .id(expense.id)
                        } else {
                            ExpenseTextCard(
                                expense: expense,
                                store: store,
                                onSelect: {
                                    onSelectExpense(expense)
                                },
                                onDelete: {
                                    expenseToDelete = expense
                                    showDeleteConfirmation = true
                                }
                            )
                            .id(expense.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 110)
            }
        }
        .alert(store.t("delete_confirm"), isPresented: $showDeleteConfirmation) {
            Button(store.t("delete"), role: .destructive) {
                if let exp = expenseToDelete {
                    store.deleteExpense(id: exp.id)
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
}

// MARK: - Expense Photo Card Subview
private struct ExpensePhotoCard: View {
    let expense: Expense
    let uiImage: UIImage
    let store: ExpenseStore
    let onSelect: () -> Void
    let onDelete: () -> Void

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var body: some View {
        let catLabel = store.categoryLabel(for: expense.category)
        let timeStr = formatTime(expense.date)
        let hasNote = (expense.note?.isEmpty == false) && expense.note != "MDaily AI processed"

        ZStack(alignment: .topLeading) {
            // 1. High-Res Image
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(3 / 4, contentMode: .fill)
                .clipped()

            // 2. Dual-Layer Vignette Gradient Overlay
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.72), location: 0.0),
                    .init(color: Color.black.opacity(0.15), location: 0.42),
                    .init(color: Color.black.opacity(0.20), location: 0.65),
                    .init(color: Color.black.opacity(0.78), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // 3. AI Badge
            if expense.isAiProcessed {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 9, weight: .bold))
                            Text("AI")
                                .font(.appFont(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.blue.opacity(0.85)))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5))
                        .shadow(radius: 4)
                        .padding(10)
                    }
                    Spacer()
                }
            }

            // 4. Content Hierarchy: Time -> Category -> Note -> Amount Pill
            VStack(alignment: .leading, spacing: 2) {
                Text(timeStr)
                    .font(.appFont(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)

                Text(catLabel)
                    .font(.appFont(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.75), radius: 6, x: 0, y: 2)

                if hasNote, let note = expense.note {
                    Text(note)
                        .font(.appFont(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.90))
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)
                }

                Spacer()

                // Bottom: Amount Glass Capsule & Delete
                HStack {
                    Text(store.formatCurrency(expense.amount))
                        .font(.appFont(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.50))
                                .background(Capsule().fill(.ultraThinMaterial))
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5))
                        )

                    Spacer()

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.50))
                                    .background(Circle().fill(.ultraThinMaterial))
                                    .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
        }
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture {
            onSelect()
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.40),
                            Color.white.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.65
                )
        )
        .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 5)
    }
}

// MARK: - Expense Text Card Subview
private struct ExpenseTextCard: View {
    let expense: Expense
    let store: ExpenseStore
    let onSelect: () -> Void
    let onDelete: () -> Void

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func categoryIconName(for id: String) -> String {
        switch id {
        case "bills": return "doc.text.fill"
        case "shopping": return "bag.fill"
        case "food": return "fork.knife"
        case "transport": return "car.fill"
        default: return "tag.fill"
        }
    }

    var body: some View {
        let catLabel = store.categoryLabel(for: expense.category)
        let timeStr = formatTime(expense.date)
        let hasNote = (expense.note?.isEmpty == false) && expense.note != "MDaily AI processed"

        VStack(alignment: .leading, spacing: 0) {
            // Top: Time & Category Icon
            HStack(spacing: 4) {
                Text(timeStr)
                    .font(.appFont(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Image(systemName: categoryIconName(for: expense.category))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.blue.opacity(0.12)))
            }
            .padding(.bottom, 6)

            // Category Title
            Text(catLabel)
                .font(.appFont(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .padding(.bottom, 2)

            // Note (if exists)
            if hasNote, let note = expense.note {
                Text(note)
                    .font(.appFont(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 22)

            // Bottom: Amount & Delete
            HStack {
                Text(store.formatCurrency(expense.amount))
                    .font(.appFont(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.10))
                                .overlay(Circle().strokeBorder(Color.red.opacity(0.20), lineWidth: 0.5))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .frame(minHeight: 180)
        .liquidGlass(cornerRadius: 28)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture {
            onSelect()
        }
    }
}
