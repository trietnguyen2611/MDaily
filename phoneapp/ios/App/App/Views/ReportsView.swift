import SwiftUI

@MainActor
public struct ReportsView: View {
    @ObservedObject public var store: ExpenseStore
    public var expenses: [Expense]

    @State private var selectedSegment: Int = 0 // 0: Overview, 1: Category Manager
    @State private var isAddingCategory: Bool = false
    @State private var newCategoryLabel: String = ""
    @State private var editingCategoryId: String? = nil
    @State private var editCategoryLabel: String = ""
    @State private var categoryToDelete: CategoryItem? = nil
    @State private var showDeleteCategoryAlert: Bool = false

    private let colors: [Color] = [
        .blue, .purple, .orange, .green, .pink,
        .cyan, .yellow, .indigo, .teal, .red
    ]

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                // Top Segmented Bar (Liquid Glass Style)
                HStack(spacing: 6) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedSegment = 0
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.pie.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text(store.language == .en ? "Spending Analytics" : "Báo cáo chi tiêu")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(selectedSegment == 0 ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if selectedSegment == 0 {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color(red: 0, green: 0.7, blue: 0.95)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.blue.opacity(0.35), radius: 6, x: 0, y: 2)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedSegment = 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text(store.language == .en ? "Categories" : "Quản lý phân loại")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(selectedSegment == 1 ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if selectedSegment == 1 {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color(red: 0, green: 0.7, blue: 0.95)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.blue.opacity(0.35), radius: 6, x: 0, y: 2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(4)
                .liquidGlass(cornerRadius: 24)

                if selectedSegment == 0 {
                    // MARK: - Spending Analytics View
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
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(store.t("chart_overview"))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)

                                    Text(store.formatCurrency(total))
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.primary)

                                    Text("\(expenses.count) \(store.t("expenses_count"))")
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
                                Text(store.t("no_expenses"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                    }
                    .padding(20)
                    .liquidGlass(cornerRadius: 28)

                    // Category Breakdown Cards
                    if !categoryTotals.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(categoryTotals, id: \.item.id) { catData in
                                let percentage = total > 0 ? (catData.total / total) * 100 : 0
                                VStack(spacing: 8) {
                                    HStack {
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(catData.color)
                                                .frame(width: 10, height: 10)
                                            Image(systemName: catData.item.iconName)
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                            Text(catData.item.label)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.primary)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(store.formatCurrency(catData.total))
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.primary)
                                            Text(String(format: "%.1f%%", percentage))
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    // Progress Bar
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.secondary.opacity(0.15))
                                                .frame(height: 6)

                                            Capsule()
                                                .fill(catData.color)
                                                .frame(width: max(6, geo.size.width * CGFloat(percentage / 100)), height: 6)
                                        }
                                    }
                                    .frame(height: 6)
                                }
                                .padding(16)
                                .liquidGlass(cornerRadius: 20)
                            }
                        }
                    }
                } else {
                    // MARK: - Category Management View
                    VStack(spacing: 16) {
                        // Add New Category Card
                        if !isAddingCategory {
                            Button {
                                isAddingCategory = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                    Text(store.t("add_new_category"))
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                .padding(16)
                                .liquidGlass(cornerRadius: 20)
                            }
                            .liquidGlassButton()
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(store.t("add_new_category"))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primary)

                                HStack(spacing: 10) {
                                    TextField(store.t("new_cat_placeholder"), text: $newCategoryLabel)
                                        .padding(12)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))

                                    Button(store.t("save")) {
                                        let trimmed = newCategoryLabel.trimmingCharacters(in: .whitespaces)
                                        if !trimmed.isEmpty {
                                            store.addCategory(label: trimmed)
                                            newCategoryLabel = ""
                                            isAddingCategory = false
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button {
                                        isAddingCategory = false
                                        newCategoryLabel = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(18)
                            .liquidGlass(cornerRadius: 24)
                        }

                        // Category List
                        VStack(spacing: 12) {
                            ForEach(store.categories) { cat in
                                let count = expenses.filter { $0.category == cat.id }.count
                                let catTotal = expenses.filter { $0.category == cat.id }.reduce(0.0) { $0 + $1.amount }

                                if editingCategoryId == cat.id {
                                    // Editing Row
                                    HStack(spacing: 10) {
                                        TextField("Tên danh mục", text: $editCategoryLabel)
                                            .padding(10)
                                            .background(Color(.secondarySystemBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))

                                        Button(store.t("save")) {
                                            let trimmed = editCategoryLabel.trimmingCharacters(in: .whitespaces)
                                            if !trimmed.isEmpty {
                                                store.updateCategory(id: cat.id, label: trimmed)
                                                editingCategoryId = nil
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)

                                        Button {
                                            editingCategoryId = nil
                                        } label: {
                                            Image(systemName: "xmark")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(16)
                                    .liquidGlass(cornerRadius: 20)
                                } else {
                                    // Regular Display Row
                                    HStack {
                                        HStack(spacing: 12) {
                                            Image(systemName: cat.iconName)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.blue)
                                                .frame(width: 36, height: 36)
                                                .background(Circle().fill(Color.blue.opacity(0.12)))

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(cat.label)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.primary)

                                                Text("\(count) giao dịch • \(store.formatCurrency(catTotal))")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                        }

                                        Spacer()

                                        HStack(spacing: 8) {
                                            // Edit Button
                                            Button {
                                                editingCategoryId = cat.id
                                                editCategoryLabel = cat.label
                                            } label: {
                                                Image(systemName: "pencil")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(.blue)
                                                    .frame(width: 32, height: 32)
                                                    .background(Circle().fill(Color.blue.opacity(0.10)))
                                            }
                                            .buttonStyle(.plain)

                                            // Delete Button (only for custom categories)
                                            if !cat.isDefault {
                                                Button {
                                                    categoryToDelete = cat
                                                    showDeleteCategoryAlert = true
                                                } label: {
                                                    Image(systemName: "trash")
                                                        .font(.system(size: 13, weight: .semibold))
                                                        .foregroundColor(.red)
                                                        .frame(width: 32, height: 32)
                                                        .background(Circle().fill(Color.red.opacity(0.10)))
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    .padding(16)
                                    .liquidGlass(cornerRadius: 20)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .confirmationDialog(
            "Bạn có chắc muốn xoá phân loại này không?",
            isPresented: $showDeleteCategoryAlert,
            titleVisibility: .visible
        ) {
            Button("Xoá phân loại", role: .destructive) {
                if let cat = categoryToDelete {
                    store.deleteCategory(id: cat.id)
                    categoryToDelete = nil
                }
            }
            Button("Huỷ", role: .cancel) {
                categoryToDelete = nil
            }
        }
    }
}
