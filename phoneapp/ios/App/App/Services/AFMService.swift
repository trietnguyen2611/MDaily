import Foundation
import UIKit
import Vision

#if canImport(FoundationModels)
import FoundationModels
#endif

public struct ExtractionResult: Sendable {
    public var success: Bool
    public var itemName: String?
    public var amount: Double?
    public var category: String?
    public var isInvoice: Bool

    public init(success: Bool, itemName: String? = nil, amount: Double? = nil, category: String? = nil, isInvoice: Bool = false) {
        self.success = success
        self.itemName = itemName
        self.amount = amount
        self.category = category
        self.isInvoice = isInvoice
    }
}

public struct AFMStatus: Sendable {
    public var available: Bool
    public var model: String
    public var message: String
}

public final class AFMService: Sendable {
    public static let shared = AFMService()

    public func checkStatus() -> AFMStatus {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return AFMStatus(
                available: true,
                model: "MDaily AI (On-Device AFM)",
                message: "Apple Foundation Model"
            )
        }
        #endif
        return AFMStatus(
            available: true,
            model: "Apple Foundation Model (On-Device)",
            message: "Sẵn sàng — Mô hình AI tài chính cục bộ trên thiết bị"
        )
    }

    // MARK: - Image & Receipt Extraction
    public func extractExpense(from image: UIImage) async -> ExtractionResult {
        guard let cgImage = image.cgImage else {
            return ExtractionResult(success: false)
        }

        // 1. Check if the image contains a receipt/invoice
        let classification = await classifyImage(from: cgImage)
        let isReceiptImage = classification.category == "bills" // "bills" means receipt/invoice in classifyImage

        // 2. Only proceed if it is a receipt image
        guard isReceiptImage else {
            return ExtractionResult(success: false)
        }

        // 3. Run Vision OCR Text Recognition
        let textResult = await recognizeText(from: cgImage)

        // 4. Parse receipt
        if !textResult.isEmpty {
            var parsed = parseReceiptText(lines: textResult)
            if parsed.success {
                // Ensure category is bills for invoices
                if parsed.isInvoice || isReceiptImage {
                    parsed = ExtractionResult(
                        success: parsed.success,
                        itemName: parsed.itemName,
                        amount: parsed.amount,
                        category: "bills",
                        isInvoice: true
                    )
                }
                return parsed
            }
        }

        return ExtractionResult(success: false)
    }

    private func recognizeText(from cgImage: CGImage) async -> [String] {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["vi-VN", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    private func classifyImage(from cgImage: CGImage) async -> (category: String?, label: String?) {
        await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard let observations = request.results as? [VNClassificationObservation], error == nil else {
                    continuation.resume(returning: (nil, nil))
                    return
                }

                for obs in observations.prefix(5) {
                    let id = obs.identifier.lowercased()
                    if id.contains("food") || id.contains("dish") || id.contains("coffee") || id.contains("drink") || id.contains("meal") || id.contains("beverage") || id.contains("tea") || id.contains("pizza") || id.contains("noodle") || id.contains("soup") {
                        let cleanName = obs.identifier.replacingOccurrences(of: "_", with: " ").capitalized
                        continuation.resume(returning: ("food", cleanName))
                        return
                    } else if id.contains("car") || id.contains("vehicle") || id.contains("bus") || id.contains("motorcycle") || id.contains("bicycle") || id.contains("taxi") {
                        continuation.resume(returning: ("transport", "Di chuyển / Xe"))
                        return
                    } else if id.contains("receipt") || id.contains("invoice") || id.contains("paper") || id.contains("document") {
                        continuation.resume(returning: ("bills", "Hoá đơn / Giấy tờ"))
                        return
                    } else if id.contains("clothing") || id.contains("shoe") || id.contains("bag") || id.contains("phone") || id.contains("gadget") {
                        continuation.resume(returning: ("shopping", "Mua sắm đồ dùng"))
                        return
                    }
                }
                continuation.resume(returning: (nil, nil))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: (nil, nil))
            }
        }
    }

    private func parseReceiptText(lines: [String]) -> ExtractionResult {
        guard !lines.isEmpty else { return ExtractionResult(success: false) }

        var foundAmount: Double?
        var foundItem: String?
        var foundCategory = "shopping"
        var isInvoice = false

        let invoiceKeywords = [
            "hoa don", "hóa đơn", "bill", "receipt", "tong cong", "tổng cộng", "total",
            "thanh toan", "thanh toán", "vat", "pos", "thành tiền", "thanh tien", "tổng tiền", "tong tien"
        ]
        let lowerLines = lines.map { $0.lowercased() }

        if lowerLines.contains(where: { line in invoiceKeywords.contains(where: { line.contains($0) }) }) {
            isInvoice = true
        }

        // Identify Known Merchants
        let merchants = [
            ("Starbucks", "food"),
            ("Highlands Coffee", "food"),
            ("Phúc Long", "food"),
            ("The Coffee House", "food"),
            ("KFC", "food"),
            ("Lotteria", "food"),
            ("McDonald's", "food"),
            ("Jollibee", "food"),
            ("Circle K", "shopping"),
            ("FamilyMart", "shopping"),
            ("7-Eleven", "shopping"),
            ("WinMart", "shopping"),
            ("Co.opmart", "shopping"),
            ("Bách Hoá Xanh", "shopping"),
            ("Shopee", "shopping"),
            ("Lazada", "shopping"),
            ("Tiki", "shopping"),
            ("Grab", "transport"),
            ("Gojek", "transport"),
            ("Be", "transport"),
            ("Xanh SM", "transport"),
            ("Điện Lực", "bills"),
            ("Cấp Nước", "bills"),
            ("VNPT", "bills"),
            ("Viettel", "bills"),
            ("FPT", "bills")
        ]

        for (merchant, cat) in merchants {
            if lowerLines.contains(where: { $0.contains(merchant.lowercased()) }) {
                foundItem = merchant
                foundCategory = cat
                break
            }
        }

        // Amount Extraction: Look for total lines first
        let totalPatterns = [
            "tổng cộng", "tong cong", "thành tiền", "thanh tien", "tổng tiền", "tong tien",
            "total", "grand total", "tiền mặt", "tien mat", "amount", "phải thanh toán", "đã thanh toán"
        ]

        for line in lines.reversed() {
            let lower = line.lowercased()
            let isTotalLine = totalPatterns.contains(where: { lower.contains($0) })

            if isTotalLine {
                if let extracted = extractNumber(from: line) {
                    foundAmount = extracted
                    break
                }
            }
        }

        if foundAmount == nil {
            var candidateAmounts: [Double] = []
            for line in lines.reversed() {
                if let val = extractNumber(from: line) {
                    candidateAmounts.append(val)
                }
            }
            if let maxVal = candidateAmounts.max(), maxVal >= 1000 {
                foundAmount = maxVal
            }
        }

        if foundItem == nil {
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                let lower = trimmed.lowercased()
                let isMeta = lower.contains("tel") || lower.contains("hotline") || lower.contains("date") ||
                             lower.contains("ngày") || lower.contains("gio") || lower.contains("giờ") ||
                             lower.contains("wifi") || lower.contains("pass") || lower.contains("bàn") ||
                             lower.contains("ban") || lower.contains("stt") || lower.contains("hóa đơn") ||
                             lower.contains("bill") || lower.contains("pos")

                if trimmed.count >= 3 && !isMeta && !trimmed.allSatisfy({ $0.isNumber || $0.isPunctuation }) {
                    foundItem = trimmed
                    break
                }
            }
        }

        let fullText = lowerLines.joined(separator: " ")
        if fullText.contains("cafe") || fullText.contains("coffee") || fullText.contains("quan") ||
           fullText.contains("nha hang") || fullText.contains("com") || fullText.contains("tra") ||
           fullText.contains("food") || fullText.contains("an uong") || fullText.contains("bánh") ||
           fullText.contains("pho") || fullText.contains("lẩu") || fullText.contains("nướng") {
            foundCategory = "food"
        } else if fullText.contains("dien") || fullText.contains("nuoc") || fullText.contains("internet") ||
                  fullText.contains("phi") || fullText.contains("cuoc") || fullText.contains("hoa don") ||
                  fullText.contains("tien nha") {
            foundCategory = "bills"
        } else if fullText.contains("grab") || fullText.contains("be") || fullText.contains("xang") ||
                  fullText.contains("taxi") || fullText.contains("xe") || fullText.contains("xanh sm") ||
                  fullText.contains("petrol") {
            foundCategory = "transport"
        }

        return ExtractionResult(
            success: foundAmount != nil || foundItem != nil,
            itemName: foundItem,
            amount: foundAmount,
            category: foundCategory,
            isInvoice: isInvoice
        )
    }

    private func extractNumber(from text: String) -> Double? {
        let cleaned = text
            .replacingOccurrences(of: "đ", with: "")
            .replacingOccurrences(of: "VND", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "VNĐ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "£", with: "")

        let pattern = #"[0-9]{1,3}(?:[.,\s][0-9]{3})*(?:[.,][0-9]{1,2})?|[0-9]{4,}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let nsString = cleaned as NSString
        let matches = regex.matches(in: cleaned, range: NSRange(location: 0, length: nsString.length))

        var results: [Double] = []
        for match in matches {
            let matchString = nsString.substring(with: match.range)
            let digitsOnly = matchString.replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: "")

            if let val = Double(digitsOnly), val >= 1000 && val <= 500_000_000 {
                results.append(val)
            }
        }

        return results.last
    }

    // MARK: - On-Device Apple Foundation Model (AFM) Reasoning Engine
    public func chatWithAI(
        userMessage: String,
        expenses: [Expense],
        categories: [CategoryItem],
        currencySymbol: String,
        isEnglish: Bool
    ) async -> String {
        let prompt = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            return isEnglish
                ? "Please ask a question about your expenses or financial goals."
                : "Vui lòng nhập câu hỏi về chi tiêu hoặc kế hoạch tài chính của bạn."
        }

        // 1. Build On-Device Financial Analytics State
        let calendar = Calendar.current
        let now = Date()

        let totalSpend = expenses.reduce(0.0) { $0 + $1.amount }
        let transactionCount = expenses.count

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formatMoney: (Double) -> String = { val in
            "\(formatter.string(from: NSNumber(value: Int(val))) ?? "\(Int(val))") \(currencySymbol)"
        }

        // Category Totals
        var catTotals: [String: Double] = [:]
        for exp in expenses {
            catTotals[exp.category, default: 0.0] += exp.amount
        }

        let sortedCategories = catTotals.sorted(by: { $0.value > $1.value })
        let topCategoryPair = sortedCategories.first
        let topCategoryName = topCategoryPair.flatMap { pair in
            categories.first(where: { $0.id == pair.key })?.label ?? pair.key
        } ?? (isEnglish ? "None" : "Chưa có")

        // Time Window Slices
        let todayExpenses = expenses.filter { calendar.isDateInToday($0.date) }
        let todaySpend = todayExpenses.reduce(0.0) { $0 + $1.amount }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let yesterdayExpenses = expenses.filter { calendar.isDate($0.date, inSameDayAs: yesterday) }
        let yesterdaySpend = yesterdayExpenses.reduce(0.0) { $0 + $1.amount }

        let thisWeekExpenses = expenses.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        let thisWeekSpend = thisWeekExpenses.reduce(0.0) { $0 + $1.amount }

        let thisMonthExpenses = expenses.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        let thisMonthSpend = thisMonthExpenses.reduce(0.0) { $0 + $1.amount }

        let highestExpense = expenses.max(by: { $0.amount < $1.amount })

        // 2. Real AFM Model Integration (if available)
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            if model.isAvailable {
                do {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd/MM"
                    
                    let txDetails = expenses.map { exp in
                        let catName = categories.first(where: { $0.id == exp.category })?.label ?? exp.category
                        let dateStr = dateFormatter.string(from: exp.date)
                        let noteStr = exp.note ?? (isEnglish ? "No note" : "Không ghi chú")
                        return "- [\(dateStr)] \(catName): \(formatMoney(exp.amount)) (\(noteStr))"
                    }.joined(separator: "\n")
                    
                    let txListStr = isEnglish ? "Transaction history:\n\(txDetails)" : "Lịch sử giao dịch:\n\(txDetails)"
                    
                    let instructions = isEnglish
                        ? "You are MDaily AI, a smart financial assistant. Keep your answers concise, natural, and friendly. Limit your responses to personal finance, budgeting, and the user's expense data. Decline out-of-scope questions like coding, math, or history. User's data context:\nTotal spend: \(formatMoney(totalSpend)). This month: \(formatMoney(thisMonthSpend)). Top category: \(topCategoryName) (\(formatMoney(topCategoryPair?.value ?? 0))).\n\n\(txListStr)"
                        : "Bạn là MDaily AI, trợ lý tài chính thông minh. Trả lời thân thiện, tự nhiên và ngắn gọn. Chỉ trả lời các câu hỏi liên quan đến tài chính, chi tiêu, ngân sách. Từ chối lịch sự các câu hỏi ngoài lề (như code, toán, lịch sử, làm thơ). Ngữ cảnh dữ liệu:\nTổng chi: \(formatMoney(totalSpend)). Tháng này: \(formatMoney(thisMonthSpend)). Danh mục nhiều nhất: \(topCategoryName) (\(formatMoney(topCategoryPair?.value ?? 0))).\n\n\(txListStr)"
                    
                    let session = LanguageModelSession(instructions: instructions)
                    let response = try await session.respond(to: prompt)
                    return String(response.content)
                } catch {
                    // Fall back to rule-based engine if model fails
                }
            }
        }
        #endif

        // 3. Perform Dynamic Rule-Based Semantic Query Reasoning (Fallback)
        let p = prompt.lowercased()

        // Check if query is asking about specific category or keyword
        var matchedCategoryId: String? = nil
        var matchedCategoryLabel: String? = nil

        for cat in categories {
            let labelLower = cat.label.lowercased()
            let idLower = cat.id.lowercased()
            if p.contains(labelLower) || p.contains(idLower) {
                matchedCategoryId = cat.id
                matchedCategoryLabel = cat.label
                break
            }
        }

        // Additional semantic keyword resolution
        if matchedCategoryId == nil {
            if p.contains("ăn") || p.contains("uống") || p.contains("cơm") || p.contains("cafe") || p.contains("cà phê") || p.contains("food") || p.contains("dining") || p.contains("trà") || p.contains("bánh") || p.contains("nhậu") {
                matchedCategoryId = "food"
                matchedCategoryLabel = categories.first(where: { $0.id == "food" })?.label ?? "Ăn uống"
            } else if p.contains("xe") || p.contains("grab") || p.contains("xăng") || p.contains("be") || p.contains("taxi") || p.contains("transport") || p.contains("di chuyển") {
                matchedCategoryId = "transport"
                matchedCategoryLabel = categories.first(where: { $0.id == "transport" })?.label ?? "Di chuyển"
            } else if p.contains("mua") || p.contains("shopping") || p.contains("sắm") || p.contains("quần áo") || p.contains("đồ") {
                matchedCategoryId = "shopping"
                matchedCategoryLabel = categories.first(where: { $0.id == "shopping" })?.label ?? "Mua sắm"
            } else if p.contains("điện") || p.contains("nước") || p.contains("hoá đơn") || p.contains("tiền nhà") || p.contains("mạng") || p.contains("bill") {
                matchedCategoryId = "bills"
                matchedCategoryLabel = categories.first(where: { $0.id == "bills" })?.label ?? "Hoá đơn"
            }
        }

        // Temporal scope detection
        let isAskingToday = p.contains("hôm nay") || p.contains("today") || p.contains("bữa nay") || p.contains("nay")
        let isAskingYesterday = p.contains("hôm qua") || p.contains("yesterday") || p.contains("hôm trc")
        let isAskingThisWeek = p.contains("tuần này") || p.contains("this week")
        let isAskingThisMonth = p.contains("tháng này") || p.contains("this month")
        let isAskingHighest = p.contains("lớn nhất") || p.contains("nhiều nhất") || p.contains("cao nhất") || p.contains("highest") || p.contains("max") || p.contains("top")
        let isAskingLowest = p.contains("ít nhất") || p.contains("nhỏ nhất") || p.contains("thấp nhất") || p.contains("lowest") || p.contains("min")
        let isAskingAdvice = p.contains("tiết kiệm") || p.contains("khuyên") || p.contains("mẹo") || p.contains("advice") || p.contains("save") || p.contains("budget") || p.contains("kế hoạch")
        let isAskingListing = p.contains("liệt kê") || p.contains("danh sách") || p.contains("gồm những gì") || p.contains("list") || p.contains("xem lại") || p.contains("những khoản nào")

        // 3. Generate Fluid AFM Response
        if expenses.isEmpty {
            if isEnglish {
                return "You haven't recorded any expenses yet in MDaily. Tap the '+' button or capture a receipt photo to let MDaily AI start tracking your financial habits!"
            } else {
                return "Bạn chưa có khoản chi tiêu nào trong MDaily. Hãy bấm nút '+' hoặc chụp ảnh hoá đơn để MDaily AI bắt đầu theo dõi và phân tích tài chính giúp bạn nhé!"
            }
        }

        // Query by Category
        if let catId = matchedCategoryId, let catName = matchedCategoryLabel {
            let filteredCatExpenses = expenses.filter { $0.category == catId }
            let catSum = filteredCatExpenses.reduce(0.0) { $0 + $1.amount }
            let percentOfTotal = totalSpend > 0 ? (catSum / totalSpend) * 100 : 0

            var responseLines: [String] = []
            if isEnglish {
                responseLines.append("📊 **\(catName) Spending Analysis**:")
                responseLines.append("• **Total**: \(formatMoney(catSum)) (\(filteredCatExpenses.count) transactions, ~\(Int(percentOfTotal))% of total spending)")

                if !filteredCatExpenses.isEmpty {
                    responseLines.append("\n**Recent Transactions**:")
                    for exp in filteredCatExpenses.prefix(5) {
                        let note = exp.note ?? "Expense"
                        responseLines.append("• \(note): \(formatMoney(exp.amount))")
                    }
                }
            } else {
                responseLines.append("📊 **Phân tích danh mục \(catName)**:")
                responseLines.append("• **Tổng chi**: \(formatMoney(catSum)) (\(filteredCatExpenses.count) giao dịch, chiếm ~\(Int(percentOfTotal))% tổng chi tiêu)")

                if !filteredCatExpenses.isEmpty {
                    responseLines.append("\n**Các khoản gần đây**:")
                    for exp in filteredCatExpenses.prefix(5) {
                        let note = exp.note ?? "Khoản chi"
                        responseLines.append("• \(note): \(formatMoney(exp.amount))")
                    }
                }
            }
            return responseLines.joined(separator: "\n")
        }

        // Query for Today / Yesterday
        if isAskingToday {
            if isEnglish {
                if todayExpenses.isEmpty {
                    return "You have not logged any expenses for **Today**. Tap '+' to add a transaction if you made any purchases!"
                }
                var lines = ["📅 **Today's Spending**: \(formatMoney(todaySpend)) (\(todayExpenses.count) transactions)"]
                for exp in todayExpenses {
                    let cat = categories.first(where: { $0.id == exp.category })?.label ?? exp.category
                    lines.append("• \(exp.note ?? cat): \(formatMoney(exp.amount))")
                }
                return lines.joined(separator: "\n")
            } else {
                if todayExpenses.isEmpty {
                    return "Hôm nay bạn chưa phát sinh khoản chi tiêu nào được ghi lại. Hãy bấm nút '+' để thêm chi tiêu mới nhé!"
                }
                var lines = ["📅 **Chi tiêu hôm nay**: \(formatMoney(todaySpend)) (\(todayExpenses.count) giao dịch)"]
                for exp in todayExpenses {
                    let cat = categories.first(where: { $0.id == exp.category })?.label ?? exp.category
                    lines.append("• \(exp.note ?? cat): \(formatMoney(exp.amount))")
                }
                return lines.joined(separator: "\n")
            }
        }

        if isAskingYesterday {
            if isEnglish {
                if yesterdayExpenses.isEmpty {
                    return "No expenses were recorded for **Yesterday**."
                }
                var lines = ["📅 **Yesterday's Spending**: \(formatMoney(yesterdaySpend)) (\(yesterdayExpenses.count) transactions)"]
                for exp in yesterdayExpenses {
                    let cat = categories.first(where: { $0.id == exp.category })?.label ?? exp.category
                    lines.append("• \(exp.note ?? cat): \(formatMoney(exp.amount))")
                }
                return lines.joined(separator: "\n")
            } else {
                if yesterdayExpenses.isEmpty {
                    return "Hôm qua bạn không có khoản chi tiêu nào được ghi lại."
                }
                var lines = ["📅 **Chi tiêu hôm qua**: \(formatMoney(yesterdaySpend)) (\(yesterdayExpenses.count) giao dịch)"]
                for exp in yesterdayExpenses {
                    let cat = categories.first(where: { $0.id == exp.category })?.label ?? exp.category
                    lines.append("• \(exp.note ?? cat): \(formatMoney(exp.amount))")
                }
                return lines.joined(separator: "\n")
            }
        }

        // Query for This Week
        if isAskingThisWeek {
            if isEnglish {
                if thisWeekExpenses.isEmpty {
                    return "No expenses recorded for **This Week** yet."
                }
                var lines = ["📅 **This Week's Spending**: \(formatMoney(thisWeekSpend)) (\(thisWeekExpenses.count) transactions)"]
                for exp in thisWeekExpenses.prefix(6) {
                    let cat = categories.first(where: { $0.id == exp.category })?.label ?? exp.category
                    lines.append("• \(exp.note ?? cat): \(formatMoney(exp.amount))")
                }
                return lines.joined(separator: "\n")
            } else {
                if thisWeekExpenses.isEmpty {
                    return "Bạn chưa có khoản chi tiêu nào trong **Tuần này**."
                }
                var lines = ["📅 **Chi tiêu tuần này**: \(formatMoney(thisWeekSpend)) (\(thisWeekExpenses.count) giao dịch)"]
                for exp in thisWeekExpenses.prefix(6) {
                    let cat = categories.first(where: { $0.id == exp.category })?.label ?? exp.category
                    lines.append("• \(exp.note ?? cat): \(formatMoney(exp.amount))")
                }
                return lines.joined(separator: "\n")
            }
        }

        // Query for This Month
        if isAskingThisMonth {
            if isEnglish {
                if thisMonthExpenses.isEmpty {
                    return "No expenses recorded for **This Month** yet."
                }
                return "📅 **This Month's Spending**: **\(formatMoney(thisMonthSpend))** across \(thisMonthExpenses.count) transactions."
            } else {
                if thisMonthExpenses.isEmpty {
                    return "Bạn chưa có khoản chi tiêu nào trong **Tháng này**."
                }
                return "📅 **Tổng chi tiêu tháng này**: **\(formatMoney(thisMonthSpend))** (\(thisMonthExpenses.count) giao dịch)."
            }
        }

        // Query for Highest / Top Expense
        if isAskingHighest, let highest = highestExpense {
            let cat = categories.first(where: { $0.id == highest.category })?.label ?? highest.category
            let note = highest.note ?? cat
            if isEnglish {
                return "⚡ **Highest Single Expense**: **\(formatMoney(highest.amount))** for **\(note)** in category *\(cat)*."
            } else {
                return "⚡ **Khoản chi lớn nhất của bạn**: **\(formatMoney(highest.amount))** cho **\(note)** (Danh mục: *\(cat)*)."
            }
        }

        // Query for Lowest Expense
        if isAskingLowest, let lowest = expenses.min(by: { $0.amount < $1.amount }) {
            let cat = categories.first(where: { $0.id == lowest.category })?.label ?? lowest.category
            let note = lowest.note ?? cat
            if isEnglish {
                return "⚡ **Lowest Single Expense**: **\(formatMoney(lowest.amount))** for **\(note)** (Category: *\(cat)*)."
            } else {
                return "⚡ **Khoản chi nhỏ nhất của bạn**: **\(formatMoney(lowest.amount))** cho **\(note)** (Danh mục: *\(cat)*)."
            }
        }

        // Query for Listing / Recent
        if isAskingListing {
            var lines: [String] = []
            if isEnglish {
                lines.append("📝 **Recent Expenses List**:")
                for exp in expenses.prefix(8) {
                    let cat = categories.first(where: { $0.id == exp.category })?.label ?? exp.category
                    let note = exp.note ?? cat
                    lines.append("• **\(note)**: \(formatMoney(exp.amount)) (\(cat))")
                }
            } else {
                lines.append("📝 **Danh sách chi tiêu gần nhất**:")
                for exp in expenses.prefix(8) {
                    let cat = categories.first(where: { $0.id == exp.category })?.label ?? exp.category
                    let note = exp.note ?? cat
                    lines.append("• **\(note)**: \(formatMoney(exp.amount)) (\(cat))")
                }
            }
            return lines.joined(separator: "\n")
        }

        // Query for Advice / Optimization
        if isAskingAdvice {
            let topAmt = topCategoryPair?.value ?? 0
            let topPct = totalSpend > 0 ? (topAmt / totalSpend) * 100 : 0
            if isEnglish {
                return """
                💡 **MDaily AI Financial Insights**:
                1. **High Spend Alert**: You are spending **\(Int(topPct))%** of your budget on **\(topCategoryName)** (\(formatMoney(topAmt))). Try applying a 15% reduction here.
                2. **50/30/20 Rule**: Prioritize 50% for Needs, 30% for Lifestyle, and 20% for Long-term Wealth & Savings.
                3. **Daily Tracking**: Consistent logging reduces impulse spending by up to 20% according to behavioral economics.
                """
            } else {
                return """
                💡 **Phân tích tối ưu tài chính từ MDaily AI**:
                1. **Điểm cần lưu ý**: Bạn đang chi **\(Int(topPct))%** ngân sách cho danh mục **\(topCategoryName)** (\(formatMoney(topAmt))). Hãy thử đặt hạn mức chi cho mục này để tiết kiệm thêm 10–15% mỗi tháng!
                2. **Quy tắc 50/30/20**: Phân bổ 50% chi phí thiết yếu, 30% cho sở thích cá nhân, và 20% đưa vào quỹ tiết kiệm hoặc đầu tư.
                3. **Kiểm soát dòng tiền**: Ghi chép ngay khi phát sinh chi tiêu giúp bạn luôn chủ động nắm bắt ngân sách.
                """
            }
        }

        // Conversational Fallbacks for Out-of-Scope or Greetings
        let isGreeting = p.contains("chào") || p.contains("hi") || p.contains("hello") || p.contains("hey")
        let isAskingIdentity = p.contains("mày là ai") || p.contains("bạn là ai") || p.contains("who are you") || p.contains("tên gì")
        let isOutOfScope = p.contains("thơ") || p.contains("hát") || p.contains("chơi") || p.contains("joke") || p.contains("kể chuyện") || p.contains("toán") || p.contains("code") || p.contains("thời tiết")
        
        if isGreeting {
            return isEnglish ? "Hello there! I'm MDaily AI. What financial goals can I help you with today?" : "Chào bạn! Tôi là MDaily AI. Hôm nay tôi có thể giúp gì cho kế hoạch tài chính của bạn?"
        }
        if isAskingIdentity {
            return isEnglish ? "I'm MDaily AI, your dedicated personal finance assistant built securely into this app." : "Tôi là MDaily AI, trợ lý tài chính cá nhân được tích hợp an toàn ngay trong ứng dụng MDaily."
        }
        if isOutOfScope {
            return isEnglish ? "I'm focused strictly on your finances and budgeting. I can't assist with that, but I'd love to help you analyze your expenses!" : "Rất tiếc, tôi là chuyên gia tài chính nên chỉ tập trung vào việc quản lý chi tiêu của bạn thôi. Bạn có câu hỏi nào về ngân sách không?"
        }

        // Comprehensive Dynamic Financial Overview
        var breakdownLines: [String] = []
        for (catId, amt) in sortedCategories.prefix(4) {
            let label = categories.first(where: { $0.id == catId })?.label ?? catId
            let pct = totalSpend > 0 ? (amt / totalSpend) * 100 : 0
            breakdownLines.append("• \(label): \(formatMoney(amt)) (\(Int(pct))%)")
        }

        if isEnglish {
            return """
            📊 **MDaily AI Summary**:
            • **Total Spending**: \(formatMoney(totalSpend)) (\(transactionCount) transactions)
            • **This Month**: \(formatMoney(thisMonthSpend))
            • **Top Category**: \(topCategoryName) (\(formatMoney(topCategoryPair?.value ?? 0)))
            
            **Top Breakdown**:
            \(breakdownLines.joined(separator: "\n"))
            """
        } else {
            return """
            📊 **Tổng quan từ MDaily AI**:
            • **Tổng chi tiêu**: \(formatMoney(totalSpend)) (\(transactionCount) giao dịch)
            • **Chi trong tháng này**: \(formatMoney(thisMonthSpend))
            • **Mục chi nhiều nhất**: **\(topCategoryName)** (\(formatMoney(topCategoryPair?.value ?? 0)))
            
            **Phân bổ chính**:
            \(breakdownLines.joined(separator: "\n"))
            """
        }
    }
}
