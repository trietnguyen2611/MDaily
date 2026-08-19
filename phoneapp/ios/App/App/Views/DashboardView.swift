import SwiftUI

public struct DashboardView: View {
    @ObservedObject public var store: ExpenseStore
    public var expenses: [Expense]
    public var onSelectExpense: (Expense) -> Void

    @Environment(\.colorScheme) var colorScheme

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            if expenses.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.top, 60)

                    Text(store.t("no_expenses"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(expenses) { expense in
                        let catLabel = store.categoryLabel(for: expense.category)
                        let timeStr = formatTime(expense.date)
                        let hasNote = (expense.note?.isEmpty == false) && expense.note != "MDaily AI processed"

                        if let photoData = expense.photoData, let uiImage = UIImage(data: photoData) {
                            // Photo Card (3:4 Portrait Aspect Ratio)
                            Button {
                                onSelectExpense(expense)
                            } label: {
                                ZStack(alignment: .topLeading) {
                                    // Background Image
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .aspectRatio(3 / 4, contentMode: .fill)
                                        .clipped()

                                    // Dual Vignette Gradient Overlay
                                    LinearGradient(
                                        stops: [
                                            .init(color: Color.black.opacity(0.72), location: 0.0),
                                            .init(color: Color.black.opacity(0.18), location: 0.45),
                                            .init(color: Color.black.opacity(0.20), location: 0.65),
                                            .init(color: Color.black.opacity(0.75), location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )

                                    // Top Content: 1. Time -> 2. Category -> 3. Note
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(timeStr)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.85))
                                            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)

                                        Text(catLabel)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                            .shadow(color: .black.opacity(0.75), radius: 6, x: 0, y: 2)

                                        if hasNote, let note = expense.note {
                                            Text(note)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.white.opacity(0.88))
                                                .lineLimit(2)
                                                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)
                                        }

                                        Spacer()

                                        // Bottom Content: Amount & Delete Button
                                        HStack {
                                            Text(store.formatCurrency(expense.amount))
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.black.opacity(0.55))
                                                        .background(Capsule().fill(.ultraThinMaterial))
                                                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5))
                                                )

                                            Spacer()

                                            Button {
                                                store.deleteExpense(id: expense.id)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.red)
                                                    .frame(width: 32, height: 32)
                                                    .background(
                                                        Circle()
                                                            .fill(Color.black.opacity(0.55))
                                                            .background(Circle().fill(.ultraThinMaterial))
                                                            .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5))
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(14)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                                )
                                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        } else {
                            // Text Card
                            Button {
                                onSelectExpense(expense)
                            } label: {
                                VStack(alignment: .leading, spacing: 0) {
                                    // Top: Time
                                    Text(timeStr)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 4)

                                    // Category Title
                                    Text(catLabel)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .padding(.bottom, 2)

                                    // Note (if exists)
                                    if hasNote, let note = expense.note {
                                        Text(note)
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(.secondary)
                                            .lineLimit(3)
                                    }

                                    Spacer(minLength: 20)

                                    // Bottom: Amount & Delete
                                    HStack {
                                        Text(store.formatCurrency(expense.amount))
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)

                                        Spacer()

                                        Button {
                                            store.deleteExpense(id: expense.id)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.red)
                                                .frame(width: 32, height: 32)
                                                .background(
                                                    Circle()
                                                        .fill(Color.red.opacity(0.10))
                                                        .overlay(Circle().strokeBorder(Color.red.opacity(0.25), lineWidth: 0.5))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(18)
                                .frame(minHeight: 180)
                                .liquidGlass(cornerRadius: 28)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
}
