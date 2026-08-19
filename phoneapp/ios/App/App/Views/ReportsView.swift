import SwiftUI

public struct ReportsView: View {
    @ObservedObject public var store: ExpenseStore
    public var expenses: [Expense]

    @State private var isAddingCategory: Bool = false
    @State private var newCategoryLabel: String = ""
    @State private var editingCategoryId: String? = nil
    @State private var editCategoryLabel: String = ""

    private let colors: [Color] = [
        .blue, .green, .orange, .red, .purple,
        .cyan, .pink, .yellow, .indigo, .teal
    ]

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // 1. Overview Donut Chart Card
                let total = expenses.reduce(0.0) { $0 + $1.amount }

                let categoryTotals: [(item: CategoryItem, total: Double, color: Color)] = store.categories.enumerated().map { idx, cat in
                    let catTotal = expenses.filter { $0.category == cat.id }.reduce(0.0) { $0 + $1.amount }
                    return (item: cat, total: catTotal, color: colors[idx % colors.count])
                }.filter { $0.total > 0 }.sorted(by: { $0.total > $1.total })

                VStack(spacing: 16) {
                    if total > 0 {
                        HStack(spacing: 20) {
                            // Donut Ring
                            ZStack {
                                Circle()
                                    .stroke(Color.secondary.opacity(0.15), lineWidth: 18)
                                    .frame(width: 120, height: 120)

                                ForEach(Array(categoryTotals.enumerated()), id: \.offset) { idx, catData in
                                    let percentage = total > 0 ? catData.total / total : 0
                                    let priorPercentage = categoryTotals[0..<idx].reduce(0.0) { $0 + ($1.total / total) }

                                    Circle()
                                        .trim(from: priorPercentage, to: priorPercentage + percentage)
                                        .stroke(catData.color, style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                                        .rotationEffect(.degrees(-90))
                                        .frame(width: 120, height: 120)
                                }

                                VStack(spacing: 2) {
                                    Text("\(Int(total))")
                                        .font(.system(size: 14, weight: .bold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    Text(store.currencySymbol)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                            }

                            // Stats text
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.t("chart_overview"))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)

                                Text(store.formatCurrency(total))
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.primary)

                                Text("\(expenses.count) \(store.t("transactions")) · \(categoryTotals.count) \(store.t("categories_count"))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "chart.pie")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text(store.t("no_data"))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 20)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .liquidGlass(cornerRadius: 28)

                // 2. Section Header with Add Category Action
                HStack {
                    Text(store.t("category_breakdown"))
                        .font(.system(size: 18, weight: .bold))

                    Spacer()

                    if !isAddingCategory {
                        Button {
                            isAddingCategory = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text(store.t("create_category"))
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .liquidGlassPill()
                        }
                    }
                }

                // Dedicated Add Category Card
                if isAddingCategory {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.blue)
                            Text(store.t("create_category"))
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                        }

                        TextField(store.t("cat_placeholder"), text: $newCategoryLabel)
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        HStack(spacing: 10) {
                            Button(store.t("cancel")) {
                                isAddingCategory = false
                                newCategoryLabel = ""
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .liquidGlass(cornerRadius: 14)

                            Button(store.t("save")) {
                                if !newCategoryLabel.trimmingCharacters(in: .whitespaces).isEmpty {
                                    store.addCategory(label: newCategoryLabel.trimmingCharacters(in: .whitespaces))
                                    newCategoryLabel = ""
                                    isAddingCategory = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(16)
                    .liquidGlass(cornerRadius: 24)
                }

                // 3. Category Breakdown List
                VStack(spacing: 12) {
                    ForEach(Array(store.categories.enumerated()), id: \.element.id) { idx, cat in
                        let catTotal = expenses.filter { $0.category == cat.id }.reduce(0.0) { $0 + $1.amount }
                        let count = expenses.filter { $0.category == cat.id }.count
                        let percent = total > 0 ? (catTotal / total) : 0.0
                        let color = colors[idx % colors.count]

                        VStack(spacing: 10) {
                            HStack {
                                Circle()
                                    .fill(color.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: "tag.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(color)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cat.label)
                                        .font(.system(size: 16, weight: .semibold))

                                    Text("\(count) \(store.t("transactions"))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(store.formatCurrency(catTotal))
                                        .font(.system(size: 15, weight: .bold))

                                    Text(String(format: "%.1f%%", percent * 100))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Progress Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.12))
                                        .frame(height: 6)

                                    Capsule()
                                        .fill(color)
                                        .frame(width: max(geo.size.width * CGFloat(percent), catTotal > 0 ? 6 : 0), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 22)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 100)
        }
    }
}
