import Foundation
import CoreGraphics
import ImageIO
import Vision

#if canImport(FoundationModels)
import FoundationModels
#endif

public struct ExtractionResult: Sendable {
    public var success: Bool
    public var kind: TransactionKind
    public var itemName: String?
    public var amount: Double?
    public var categoryId: String?
    public var isInvoice: Bool

    public var category: String? {
        get { categoryId }
        set { categoryId = newValue }
    }

    public init(
        success: Bool,
        kind: TransactionKind = .expense,
        itemName: String? = nil,
        amount: Double? = nil,
        categoryId: String? = nil,
        isInvoice: Bool = false
    ) {
        self.success = success
        self.kind = kind
        self.itemName = itemName
        self.amount = amount
        self.categoryId = categoryId
        self.isInvoice = isInvoice
    }
}

public struct AFMStatus: Sendable {
    public var available: Bool
    public var model: String
    public var message: String

    public init(available: Bool, model: String, message: String) {
        self.available = available
        self.model = model
        self.message = message
    }
}

private final class ExtractionCache: @unchecked Sendable {
    private var cache: [String: ExtractionResult] = [:]
    private let lock = NSLock()

    func get(forKey key: String) -> ExtractionResult? {
        lock.lock()
        defer { lock.unlock() }
        return cache[key]
    }

    func set(_ value: ExtractionResult, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        cache[key] = value
    }
}

public final class AFMService: Sendable {
    public static let shared = AFMService()
    private let cache = ExtractionCache()

    private init() {}

    private func cacheKey(for data: Data) -> String {
        let prefixHex = data.prefix(64).map { String(format: "%02x", $0) }.joined()
        return "\(data.count)_\(prefixHex)"
    }

    // MARK: - Status
    public func checkStatus(lang: Language = .vi) -> AFMStatus {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, iOS 26.0, *) {
            let model = SystemLanguageModel.default
            switch model.availability {
            case .available:
                return AFMStatus(
                    available: true,
                    model: "Apple Foundation Model (On-Device)",
                    message: lang == .en
                        ? "Ready — On-device Apple Intelligence & Vision OCR"
                        : "Sẵn sàng — Apple Intelligence & Vision OCR cục bộ"
                )
            case .unavailable(let reason):
                let detail: String
                switch reason {
                case .deviceNotEligible:
                    detail = lang == .en ? "Fallback active (device not eligible for AFM)" : "Chế độ cục bộ (thiết bị không hỗ trợ AFM)"
                case .appleIntelligenceNotEnabled:
                    detail = lang == .en ? "Fallback active (Apple Intelligence off)" : "Chế độ cục bộ (Apple Intelligence chưa bật)"
                case .modelNotReady:
                    detail = lang == .en ? "Model downloading — fallback active" : "Đang tải mô hình — đang dùng chế độ cục bộ"
                @unknown default:
                    detail = lang == .en ? "Fallback active" : "Đang dùng chế độ cục bộ"
                }
                return AFMStatus(
                    available: false,
                    model: "Vision OCR + Local Engine",
                    message: detail
                )
            @unknown default:
                break
            }
        }
        #endif

        return AFMStatus(
            available: false,
            model: "Vision OCR + Local Engine",
            message: lang == .en
                ? "On-device Vision OCR & Rule-Based Engine"
                : "Vision OCR & phân tích cục bộ trên thiết bị"
        )
    }

    // MARK: - Cross-Platform CGImage Decoding
    private func makeCGImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    // MARK: - Image & Receipt Extraction
    public func extractTransaction(from imageData: Data) async -> ExtractionResult {
        let key = cacheKey(for: imageData)
        if let cached = cache.get(forKey: key) {
            return cached
        }

        guard let cgImage = makeCGImage(from: imageData) else {
            let fail = ExtractionResult(success: false)
            cache.set(fail, forKey: key)
            return fail
        }

        let classification = await classifyImage(from: cgImage)
        let lines = await recognizeText(from: cgImage)

        guard !lines.isEmpty else {
            // Non-text image (e.g., food/item photo): provide light classification hint if confident
            if let clsCat = classification.category, clsCat != "bills" {
                let res = ExtractionResult(
                    success: true,
                    kind: .expense,
                    itemName: classification.label,
                    amount: nil,
                    categoryId: clsCat,
                    isInvoice: false
                )
                cache.set(res, forKey: key)
                return res
            }
            let fail = ExtractionResult(success: false)
            cache.set(fail, forKey: key)
            return fail
        }

        var parsed: ExtractionResult? = nil

        #if canImport(FoundationModels)
        if #available(macOS 26.0, iOS 26.0, *) {
            let model = SystemLanguageModel.default
            if model.isAvailable {
                let fullText = lines.joined(separator: "\n")
                let instructions = """
                You are an expert Vietnamese and English receipt, invoice, and bank transfer slip parser.
                Analyze the OCR text and return ONLY a single valid JSON object (no markdown, no backticks).

                Determine:
                - "kind": "income" if this is an incoming bank transfer, salary slip, bonus, dividend, or refund credit (e.g. "nhận tiền", "tiền vào", "+ ", "credit", "salary", "lương", "thưởng"); otherwise "expense".
                - "itemName": concise merchant, sender, or item name.
                - "amount": numeric total amount without currency symbols or separators (e.g. 50000).
                - "categoryId":
                  For expense: one of "food", "shopping", "transport", "bills", "health".
                  For income: one of "salary", "bonus", "investment", "freelance", "other_income".
                - "isInvoice": boolean, true if receipt/invoice/transfer slip.

                Vietnamese context:
                - Stores: WinMart, Bach Hoa Xanh, Circle K, GS25, Co.opmart, AEON, Shopee, Lazada -> shopping
                - Cafes/Restaurants: Highlands, Phuc Long, The Coffee House, Starbucks, KFC -> food
                - Rides: Grab, Xanh SM, Be -> transport
                - Utilities: EVN, Dien luc, Cap nuoc, VNPT, Viettel, FPT -> bills
                - Pharmacies/Hospitals: Long Chau, Pharmacity, An Khang -> health
                """
                let session = LanguageModelSession(instructions: instructions)
                if let response = try? await session.respond(to: fullText) {
                    let raw = String(response.content)
                        .replacingOccurrences(of: "```json", with: "")
                        .replacingOccurrences(of: "```", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if let start = raw.firstIndex(of: "{"),
                       let end = raw.lastIndex(of: "}") {
                        let jsonSlice = String(raw[start...end])
                        if let data = jsonSlice.data(using: .utf8),
                           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            let kindStr = (dict["kind"] as? String)?.lowercased() ?? "expense"
                            let kind: TransactionKind = (kindStr == "income") ? .income : .expense
                            let amountVal: Double? = (dict["amount"] as? Double)
                                ?? (dict["amount"] as? Int).map(Double.init)
                                ?? (dict["amount"] as? String).flatMap(Double.init)
                            let catId = (dict["categoryId"] as? String) ?? (dict["category"] as? String)
                            parsed = ExtractionResult(
                                success: true,
                                kind: kind,
                                itemName: dict["itemName"] as? String,
                                amount: (amountVal ?? 0) > 0 ? amountVal : nil,
                                categoryId: catId,
                                isInvoice: (dict["isInvoice"] as? Bool) ?? true
                            )
                        }
                    }
                }
            }
        }
        #endif

        if parsed == nil || parsed?.success == false {
            parsed = parseReceiptText(lines: lines, classifiedAsReceipt: classification.category == "bills")
        }

        let finalResult = parsed ?? ExtractionResult(success: false)
        cache.set(finalResult, forKey: key)
        return finalResult
    }

    private func recognizeText(from cgImage: CGImage) async -> [String] {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
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
                guard error == nil,
                      let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: (nil, nil))
                    return
                }

                for obs in observations.prefix(5) {
                    let id = obs.identifier.lowercased()
                    if id.contains("receipt") || id.contains("invoice") || id.contains("paper") || id.contains("document") {
                        continuation.resume(returning: ("bills", nil))
                        return
                    } else if id.contains("food") || id.contains("dish") || id.contains("coffee") || id.contains("drink") || id.contains("meal") || id.contains("beverage") || id.contains("tea") {
                        let cleanName = obs.identifier.replacingOccurrences(of: "_", with: " ").capitalized
                        continuation.resume(returning: ("food", cleanName))
                        return
                    } else if id.contains("car") || id.contains("vehicle") || id.contains("motorcycle") || id.contains("taxi") {
                        continuation.resume(returning: ("transport", nil))
                        return
                    } else if id.contains("clothing") || id.contains("shoe") || id.contains("bag") || id.contains("gadget") {
                        continuation.resume(returning: ("shopping", nil))
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

    private func parseReceiptText(lines: [String], classifiedAsReceipt: Bool) -> ExtractionResult {
        guard !lines.isEmpty else { return ExtractionResult(success: false) }

        let lowerLines = lines.map { $0.lowercased() }
        let fullText = lowerLines.joined(separator: " ")

        // Detect Income slips (salary / incoming transfer / bonus / dividend)
        let incomeKeywords = [
            "biến động số dư", "bien dong so du", "nhận tiền", "nhan tien",
            "tiền vào", "tien vao", "chuyển khoản đến", "chuyen khoan den",
            "salary", "lương", "luong", "thưởng", "thuong", "bonus",
            "cổ tức", "dividend", "credited", "incoming transfer"
        ]
        let isLikelyIncome = incomeKeywords.contains(where: { fullText.contains($0) })
            || fullText.contains("+") && (fullText.contains("vnd") || fullText.contains("đ"))

        let invoiceKeywords = [
            "hoa don", "hóa đơn", "bill", "receipt", "tong cong", "tổng cộng", "total",
            "thanh toan", "thanh toán", "vat", "pos", "thành tiền", "thanh tien",
            "tổng tiền", "tong tien", "t.cộng", "t.cong", "tạm tính", "tam tinh",
            "sub total", "payment", "giao dịch", "chuyển khoản"
        ]
        let isInvoice = classifiedAsReceipt
            || lowerLines.contains(where: { line in invoiceKeywords.contains(where: { line.contains($0) }) })

        var foundAmount: Double?
        var foundItem: String?
        let foundKind: TransactionKind = isLikelyIncome ? .income : .expense
        var foundCategoryId = foundKind == .income ? "other_income" : "shopping"

        if foundKind == .income {
            if fullText.contains("lương") || fullText.contains("luong") || fullText.contains("salary") {
                foundCategoryId = "salary"
            } else if fullText.contains("thưởng") || fullText.contains("thuong") || fullText.contains("bonus") {
                foundCategoryId = "bonus"
            } else if fullText.contains("cổ tức") || fullText.contains("lãi") || fullText.contains("dividend") || fullText.contains("invest") {
                foundCategoryId = "investment"
            } else if fullText.contains("freelance") || fullText.contains("dự án") {
                foundCategoryId = "freelance"
            }
        } else {
            let merchants: [(String, String)] = [
                ("Starbucks", "food"), ("Highlands Coffee", "food"), ("Phúc Long", "food"),
                ("The Coffee House", "food"), ("KFC", "food"), ("Lotteria", "food"),
                ("McDonald's", "food"), ("Jollibee", "food"), ("Pizza Hut", "food"),
                ("Circle K", "shopping"), ("FamilyMart", "shopping"), ("7-Eleven", "shopping"),
                ("Ministop", "shopping"), ("GS25", "shopping"), ("WinMart", "shopping"),
                ("Co.opmart", "shopping"), ("Bách Hoá Xanh", "shopping"), ("Bach Hoa Xanh", "shopping"),
                ("Big C", "shopping"), ("Lotte Mart", "shopping"), ("AEON", "shopping"),
                ("Shopee", "shopping"), ("Lazada", "shopping"), ("Tiki", "shopping"),
                ("Grab", "transport"), ("Gojek", "transport"), ("Xanh SM", "transport"),
                ("Điện Lực", "bills"), ("EVN", "bills"), ("Cấp Nước", "bills"),
                ("VNPT", "bills"), ("Viettel", "bills"), ("FPT Telecom", "bills"),
                ("Long Châu", "health"), ("FPT Long Châu", "health"), ("An Khang", "health"),
                ("Pharmacity", "health"), ("Guardian", "health"), ("Bệnh Viện", "health")
            ]

            for (merchant, cat) in merchants {
                if lowerLines.contains(where: { $0.contains(merchant.lowercased()) }) {
                    foundItem = merchant
                    foundCategoryId = cat
                    break
                }
            }

            if foundItem == nil {
                if fullText.contains("thuốc") || fullText.contains("pharmacy") || fullText.contains("bệnh viện") || fullText.contains("khám") {
                    foundCategoryId = "health"
                } else if fullText.contains("cafe") || fullText.contains("coffee") || fullText.contains("nhà hàng") || fullText.contains("quán") || fullText.contains("bún") || fullText.contains("phở") || fullText.contains("cơm") || fullText.contains("trà") {
                    foundCategoryId = "food"
                } else if fullText.contains("điện") || fullText.contains("nước") || fullText.contains("internet") || fullText.contains("hoá đơn") || fullText.contains("hóa đơn") {
                    foundCategoryId = "bills"
                } else if fullText.contains("grab") || fullText.contains("taxi") || fullText.contains("xăng") || fullText.contains("gửi xe") {
                    foundCategoryId = "transport"
                }
            }
        }

        // Amount extraction
        let totalPatterns = [
            "tổng cộng", "tong cong", "thành tiền", "thanh tien", "tổng tiền", "tong tien",
            "total", "grand total", "tiền mặt", "amount", "phải thanh toán", "đã thanh toán",
            "t.cộng", "t.cong", "tạm tính", "payment", "net amount", "số tiền", "so tien", "cộng"
        ]

        for line in lines.reversed() {
            let lower = line.lowercased()
            if totalPatterns.contains(where: { lower.contains($0) }),
               let extracted = extractNumber(from: line) {
                foundAmount = extracted
                break
            }
        }

        if foundAmount == nil {
            let candidates = lines.reversed().compactMap { extractNumber(from: $0) }
            if let maxVal = candidates.max(), maxVal >= 1000 {
                foundAmount = maxVal
            }
        }

        if foundItem == nil {
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                let lower = trimmed.lowercased()
                let isMeta = lower.contains("tel") || lower.contains("hotline") || lower.contains("date")
                    || lower.contains("ngày") || lower.contains("giờ") || lower.contains("wifi")
                    || lower.contains("pass") || lower.contains("bàn") || lower.contains("stt")
                    || lower.contains("hóa đơn") || lower.contains("bill") || lower.contains("pos")
                if trimmed.count >= 3 && !isMeta && !trimmed.allSatisfy({ $0.isNumber || $0.isPunctuation }) {
                    foundItem = trimmed
                    break
                }
            }
        }

        return ExtractionResult(
            success: foundAmount != nil || foundItem != nil,
            kind: foundKind,
            itemName: foundItem,
            amount: foundAmount,
            categoryId: foundCategoryId,
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
            let digitsOnly = matchString
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: "")
            if let val = Double(digitsOnly), val >= 1000 && val <= 500_000_000 {
                results.append(val)
            }
        }
        return results.last
    }

    // MARK: - On-Device AI Financial Chat (Expense + Income)
    public func chatWithAI(
        userMessage: String,
        chatHistory: [ChatMessageSwift],
        transactions: [Transaction],
        categories: [CategoryItem],
        currencySymbol: String,
        isEnglish: Bool
    ) async -> String {
        let prompt = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            return isEnglish
                ? "Please ask a question about your income, expenses, or financial goals."
                : "Vui lòng nhập câu hỏi về thu nhập, chi tiêu hoặc kế hoạch tài chính của bạn."
        }

        let calendar = Calendar.current
        let now = Date()
        let lang: Language = isEnglish ? .en : .vi

        let expenses = transactions.filter { $0.kind == .expense }
        let incomes = transactions.filter { $0.kind == .income }

        let totalExpense = expenses.reduce(0.0) { $0 + $1.amount }
        let totalIncome = incomes.reduce(0.0) { $0 + $1.amount }
        let netBalance = totalIncome - totalExpense

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formatMoney: (Double) -> String = { val in
            let sign = val < 0 ? "-" : ""
            let num = formatter.string(from: NSNumber(value: Int(abs(val)))) ?? "\(Int(abs(val)))"
            return "\(sign)\(num) \(currencySymbol)"
        }

        var expenseCatTotals: [String: Double] = [:]
        for tx in expenses { expenseCatTotals[tx.categoryId, default: 0] += tx.amount }
        let sortedExpenseCats = expenseCatTotals.sorted { $0.value > $1.value }

        var incomeCatTotals: [String: Double] = [:]
        for tx in incomes { incomeCatTotals[tx.categoryId, default: 0] += tx.amount }
        let sortedIncomeCats = incomeCatTotals.sorted { $0.value > $1.value }

        let categoryLabel: (String) -> String = { id in
            categories.first(where: { $0.id == id })?.localizedLabel(lang: lang) ?? id
        }

        let topExpensePair = sortedExpenseCats.first
        let topExpenseName = topExpensePair.map { categoryLabel($0.key) } ?? (isEnglish ? "None" : "Chưa có")
        let topIncomePair = sortedIncomeCats.first
        let topIncomeName = topIncomePair.map { categoryLabel($0.key) } ?? (isEnglish ? "None" : "Chưa có")

        let todayTx = transactions.filter { calendar.isDateInToday($0.date) }
        let todayExpense = todayTx.filter { $0.kind == .expense }.reduce(0.0) { $0 + $1.amount }
        let todayIncome = todayTx.filter { $0.kind == .income }.reduce(0.0) { $0 + $1.amount }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let yesterdayTx = transactions.filter { calendar.isDate($0.date, inSameDayAs: yesterday) }
        let yesterdayExpense = yesterdayTx.filter { $0.kind == .expense }.reduce(0.0) { $0 + $1.amount }
        let yesterdayIncome = yesterdayTx.filter { $0.kind == .income }.reduce(0.0) { $0 + $1.amount }

        let thisWeekTx = transactions.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        let thisWeekExpense = thisWeekTx.filter { $0.kind == .expense }.reduce(0.0) { $0 + $1.amount }
        let thisWeekIncome = thisWeekTx.filter { $0.kind == .income }.reduce(0.0) { $0 + $1.amount }

        let thisMonthTx = transactions.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        let thisMonthExpense = thisMonthTx.filter { $0.kind == .expense }.reduce(0.0) { $0 + $1.amount }
        let thisMonthIncome = thisMonthTx.filter { $0.kind == .income }.reduce(0.0) { $0 + $1.amount }

        // 1. Apple Foundation Model (On-Device) when available
        #if canImport(FoundationModels)
        if #available(macOS 26.0, iOS 26.0, *) {
            let model = SystemLanguageModel.default
            if model.isAvailable {
                do {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd/MM"

                    let txDetails = transactions.prefix(100).map { tx in
                        let catName = categoryLabel(tx.categoryId)
                        let dateStr = dateFormatter.string(from: tx.date)
                        let sign = tx.kind == .income ? "+" : "-"
                        let noteStr = tx.note ?? (isEnglish ? "No note" : "Không ghi chú")
                        return "- [\(dateStr)] [\(tx.kind.rawValue)] \(catName): \(sign)\(formatMoney(tx.amount)) (\(noteStr))"
                    }.joined(separator: "\n")

                    let instructions = isEnglish
                        ? """
                        You are MDaily AI, a concise, helpful personal finance assistant.
                        Only discuss personal finance, income, expenses, cashflow, and budgeting based on the user's data. Decline unrelated topics politely.
                        Pay attention to the conversation history for follow-up questions.

                        Financial Summary:
                        - Net Balance: \(formatMoney(netBalance))
                        - Total Income: \(formatMoney(totalIncome)) (This month: \(formatMoney(thisMonthIncome)), Today: \(formatMoney(todayIncome)))
                        - Total Expense: \(formatMoney(totalExpense)) (This month: \(formatMoney(thisMonthExpense)), Today: \(formatMoney(todayExpense)))
                        - Top Expense Category: \(topExpenseName) (\(formatMoney(topExpensePair?.value ?? 0)))
                        - Top Income Source: \(topIncomeName) (\(formatMoney(topIncomePair?.value ?? 0)))

                        Recent Transactions:
                        \(txDetails)
                        """
                        : """
                        Bạn là MDaily AI, trợ lý tài chính cá nhân thông minh, ngắn gọn và thân thiện.
                        Chỉ trả lời các câu hỏi về tài chính cá nhân, thu nhập, chi tiêu, dòng tiền và ngân sách dựa trên dữ liệu người dùng. Từ chối lịch sự các chủ đề ngoài lề.
                        Hãy tham chiếu lịch sử hội thoại khi người dùng hỏi nối tiếp.

                        Tổng hợp tài chính:
                        - Số dư ròng: \(formatMoney(netBalance))
                        - Tổng thu: \(formatMoney(totalIncome)) (Tháng này: \(formatMoney(thisMonthIncome)), Hôm nay: \(formatMoney(todayIncome)))
                        - Tổng chi: \(formatMoney(totalExpense)) (Tháng này: \(formatMoney(thisMonthExpense)), Hôm nay: \(formatMoney(todayExpense)))
                        - Danh mục chi nhiều nhất: \(topExpenseName) (\(formatMoney(topExpensePair?.value ?? 0)))
                        - Nguồn thu lớn nhất: \(topIncomeName) (\(formatMoney(topIncomePair?.value ?? 0)))

                        Giao dịch gần đây:
                        \(txDetails)
                        """

                    let validHistory = chatHistory.dropLast(1).suffix(20)
                    let historyContext = validHistory.map { msg in
                        let roleName = msg.role == "user" ? (isEnglish ? "User" : "Người dùng") : "MDaily AI"
                        return "[\(roleName)]: \(msg.content)"
                    }.joined(separator: "\n---\n")

                    let fullPrompt = historyContext.isEmpty
                        ? prompt
                        : (isEnglish
                            ? "=== CONVERSATION HISTORY ===\n\(historyContext)\n=== END HISTORY ===\n\nUser's current message: \(prompt)"
                            : "=== LỊCH SỬ HỘI THOẠI ===\n\(historyContext)\n=== KẾT THÚC LỊCH SỬ ===\n\nTin nhắn hiện tại: \(prompt)")

                    let session = LanguageModelSession(instructions: instructions)
                    let response = try await session.respond(to: fullPrompt)
                    return String(response.content)
                } catch {
                    // Fall back to deterministic rule-based analytics below
                }
            }
        }
        #endif

        // 2. Smart Rule-Based Financial Fallback
        let p = prompt.lowercased()

        let isGreeting = p.contains("chào") || p == "hi" || p.contains("hello") || p.contains("hey")
        if isGreeting {
            return isEnglish
                ? "Hello! I'm MDaily AI. Ask me about your income, spending, net cashflow, or savings tips."
                : "Chào bạn! Tôi là MDaily AI. Hãy hỏi tôi về thu nhập, chi tiêu, dòng tiền ròng hoặc mẹo tiết kiệm nhé."
        }

        let isOutOfScope = p.contains("thơ") || p.contains("joke") || p.contains("toán") || p.contains("code") || p.contains("thời tiết") || p.contains("weather")
        if isOutOfScope {
            return isEnglish
                ? "I focus strictly on your personal finances and budgeting. Feel free to ask about your income, expenses, or savings!"
                : "Tôi chỉ tập trung hỗ trợ tài chính cá nhân và ngân sách của bạn. Bạn muốn xem phân tích thu chi hoặc tiết kiệm không?"
        }

        if transactions.isEmpty {
            return isEnglish
                ? "You haven't recorded any transactions yet. Add an expense or income to start tracking your cashflow!"
                : "Bạn chưa ghi nhận giao dịch nào. Hãy thêm khoản thu hoặc chi đầu tiên để MDaily AI phân tích giúp bạn nhé!"
        }

        // Category match
        for cat in categories {
            let labelLower = cat.localizedLabel(lang: lang).lowercased()
            let rawLower = cat.label.lowercased()
            let idLower = cat.id.lowercased()
            if p.contains(labelLower) || p.contains(rawLower) || p.contains(idLower) {
                let matching = transactions.filter { $0.categoryId == cat.id }
                let sum = matching.reduce(0.0) { $0 + $1.amount }
                let denominator = cat.kind == .income ? totalIncome : totalExpense
                let pct = denominator > 0 ? Int((sum / denominator) * 100) : 0
                let catTitle = cat.localizedLabel(lang: lang)

                if isEnglish {
                    var lines = ["**\(catTitle)** (\(cat.kind.title(lang: .en))): **\(formatMoney(sum))** (\(matching.count) transactions, ~\(pct)%)"]
                    for tx in matching.prefix(5) {
                        lines.append("• \(tx.note ?? catTitle): \(tx.kind.signPrefix)\(formatMoney(tx.amount))")
                    }
                    return lines.joined(separator: "\n")
                } else {
                    var lines = ["**\(catTitle)** (\(cat.kind.title(lang: .vi))): **\(formatMoney(sum))** (\(matching.count) giao dịch, ~\(pct)%)"]
                    for tx in matching.prefix(5) {
                        lines.append("• \(tx.note ?? catTitle): \(tx.kind.signPrefix)\(formatMoney(tx.amount))")
                    }
                    return lines.joined(separator: "\n")
                }
            }
        }

        let isAskingIncome = p.contains("thu nhập") || p.contains("thu") || p.contains("lương") || p.contains("income") || p.contains("salary") || p.contains("earned")
        let isAskingExpense = p.contains("chi") || p.contains("tiêu") || p.contains("expense") || p.contains("spend")
        let isAskingNet = p.contains("số dư") || p.contains("ròng") || p.contains("dòng tiền") || p.contains("cashflow") || p.contains("net") || p.contains("balance")

        let isAskingToday = p.contains("hôm nay") || p.contains("today")
        let isAskingYesterday = p.contains("hôm qua") || p.contains("yesterday")
        let isAskingThisWeek = p.contains("tuần này") || p.contains("this week")
        let isAskingThisMonth = p.contains("tháng này") || p.contains("this month")
        let isAskingHighest = p.contains("lớn nhất") || p.contains("nhiều nhất") || p.contains("cao nhất") || p.contains("tốn nhất") || p.contains("highest") || p.contains("top")
        let isAskingAdvice = p.contains("tiết kiệm") || p.contains("khuyên") || p.contains("mẹo") || p.contains("advice") || p.contains("save") || p.contains("budget")

        if isAskingToday {
            return isEnglish
                ? "**Today**: Income **+\(formatMoney(todayIncome))** | Expense **-\(formatMoney(todayExpense))** | Net **\(formatMoney(todayIncome - todayExpense))** (\(todayTx.count) transactions)."
                : "**Hôm nay**: Thu **+\(formatMoney(todayIncome))** | Chi **-\(formatMoney(todayExpense))** | Ròng **\(formatMoney(todayIncome - todayExpense))** (\(todayTx.count) giao dịch)."
        }

        if isAskingYesterday {
            return isEnglish
                ? "**Yesterday**: Income **+\(formatMoney(yesterdayIncome))** | Expense **-\(formatMoney(yesterdayExpense))** (\(yesterdayTx.count) transactions)."
                : "**Hôm qua**: Thu **+\(formatMoney(yesterdayIncome))** | Chi **-\(formatMoney(yesterdayExpense))** (\(yesterdayTx.count) giao dịch)."
        }

        if isAskingThisWeek {
            return isEnglish
                ? "**This Week**: Income **+\(formatMoney(thisWeekIncome))** | Expense **-\(formatMoney(thisWeekExpense))** | Net **\(formatMoney(thisWeekIncome - thisWeekExpense))**."
                : "**Tuần này**: Thu **+\(formatMoney(thisWeekIncome))** | Chi **-\(formatMoney(thisWeekExpense))** | Ròng **\(formatMoney(thisWeekIncome - thisWeekExpense))**."
        }

        if isAskingThisMonth {
            return isEnglish
                ? "**This Month**: Income **+\(formatMoney(thisMonthIncome))** | Expense **-\(formatMoney(thisMonthExpense))** | Net **\(formatMoney(thisMonthIncome - thisMonthExpense))** (\(thisMonthTx.count) transactions)."
                : "**Tháng này**: Thu **+\(formatMoney(thisMonthIncome))** | Chi **-\(formatMoney(thisMonthExpense))** | Ròng **\(formatMoney(thisMonthIncome - thisMonthExpense))** (\(thisMonthTx.count) giao dịch)."
        }

        if isAskingHighest {
            if isAskingIncome && !isAskingExpense, let top = topIncomePair {
                return isEnglish
                    ? "Top income category: **\(topIncomeName)** (**+\(formatMoney(top.value))**)."
                    : "Nguồn thu lớn nhất: **\(topIncomeName)** (**+\(formatMoney(top.value))**)."
            }
            if let top = topExpensePair {
                let pct = totalExpense > 0 ? Int((top.value / totalExpense) * 100) : 0
                return isEnglish
                    ? "Highest spending category: **\(topExpenseName)** (**-\(formatMoney(top.value))**, \(pct)% of expenses)."
                    : "Danh mục chi nhiều nhất: **\(topExpenseName)** (**-\(formatMoney(top.value))**, chiếm \(pct)% tổng chi)."
            }
        }

        if isAskingAdvice {
            let savingsRate = totalIncome > 0 ? Int(((totalIncome - totalExpense) / totalIncome) * 100) : 0
            let topAmt = topExpensePair?.value ?? 0
            let topPct = totalExpense > 0 ? Int((topAmt / totalExpense) * 100) : 0
            if isEnglish {
                return """
                **MDaily AI Insights**:
                1. **Top Expense**: **\(topExpenseName)** accounts for **\(topPct)%** of spending (\(formatMoney(topAmt))). Trimming 10–15% here boosts savings quickly.
                2. **Cashflow Rate**: Your current net balance is **\(formatMoney(netBalance))**\(totalIncome > 0 ? " (~\(savingsRate)% savings rate)" : "").
                3. **50/30/20 Guideline**: Aim for 50% essentials, 30% lifestyle, and 20% savings/investments.
                """
            } else {
                return """
                **Gợi ý tối ưu từ MDaily AI**:
                1. **Khoản chi lớn nhất**: **\(topExpenseName)** đang chiếm **\(topPct)%** tổng chi (\(formatMoney(topAmt))). Thử giảm 10–15% ở mục này nhé.
                2. **Dòng tiền hiện tại**: Số dư ròng là **\(formatMoney(netBalance))**\(totalIncome > 0 ? " (tỷ lệ giữ lại ~\(savingsRate)%)" : "").
                3. **Quy tắc 50/30/20**: 50% thiết yếu, 30% cá nhân, 20% tiết kiệm & đầu tư.
                """
            }
        }

        if isAskingNet || (isAskingIncome && !isAskingExpense) {
            return isEnglish
                ? "**Cashflow Overview**: Income **+\(formatMoney(totalIncome))** | Expense **-\(formatMoney(totalExpense))** | Net Balance **\(formatMoney(netBalance))**."
                : "**Tổng quan dòng tiền**: Tổng thu **+\(formatMoney(totalIncome))** | Tổng chi **-\(formatMoney(totalExpense))** | Số dư ròng **\(formatMoney(netBalance))**."
        }

        // General overview fallback
        var topLines: [String] = []
        for (catId, amt) in sortedExpenseCats.prefix(3) {
            let pct = totalExpense > 0 ? Int((amt / totalExpense) * 100) : 0
            topLines.append("• \(categoryLabel(catId)): -\(formatMoney(amt)) (\(pct)%)")
        }

        if isEnglish {
            return """
            **MDaily AI Summary** (\(transactions.count) transactions):
            • **Total Income**: +\(formatMoney(totalIncome))
            • **Total Expense**: -\(formatMoney(totalExpense))
            • **Net Balance**: \(formatMoney(netBalance))
            \(topLines.isEmpty ? "" : "\n**Top Expenses**:\n\(topLines.joined(separator: "\n"))")
            """
        } else {
            return """
            **Tổng quan tài chính** (\(transactions.count) giao dịch):
            • **Tổng thu**: +\(formatMoney(totalIncome))
            • **Tổng chi**: -\(formatMoney(totalExpense))
            • **Số dư ròng**: \(formatMoney(netBalance))
            \(topLines.isEmpty ? "" : "\n**Chi tiêu nổi bật**:\n\(topLines.joined(separator: "\n"))")
            """
        }
    }
}
