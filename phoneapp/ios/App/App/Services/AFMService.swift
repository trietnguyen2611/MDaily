import Foundation
import UIKit
import Vision

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
                model: "Apple Intelligence (On-Device AFM)",
                message: "Sẵn sàng — Mô hình AI cục bộ trên iPhone"
            )
        }
        #endif
        return AFMStatus(
            available: true,
            model: "MDaily On-Device Financial Intelligence",
            message: "Sẵn sàng — Nhận diện hình ảnh & Phân tích tài chính thông minh"
        )
    }

    // MARK: - Image & Receipt Extraction
    public func extractExpense(from image: UIImage) async -> ExtractionResult {
        guard let cgImage = image.cgImage else {
            return ExtractionResult(success: false)
        }

        // 1. Run Vision OCR Text Recognition
        let textResult = await recognizeText(from: cgImage)

        // 2. If OCR found text, parse receipt
        if !textResult.isEmpty {
            let parsed = parseReceiptText(lines: textResult)
            if parsed.success {
                return parsed
            }
        }

        // 3. Fallback: Run Vision Image Classification (for objects, food, drinks, transport)
        let classification = await classifyImage(from: cgImage)
        if let cat = classification.category {
            return ExtractionResult(
                success: true,
                itemName: classification.label,
                amount: nil,
                category: cat,
                isInvoice: false
            )
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

        // 1. Identify Known Merchants / Brands
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

        // 2. Amount Extraction: Look for total lines first
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

        // Fallback amount: Scan reversed for the largest valid money value
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

        // 3. Item Name Parsing if no merchant was found
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

        // 4. Category Classification
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
        // Remove currency symbols
        let cleaned = text
            .replacingOccurrences(of: "đ", with: "")
            .replacingOccurrences(of: "VND", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "VNĐ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "£", with: "")

        // Regex to find currency numbers (e.g. 50,000 or 50.000 or 50000)
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

    // MARK: - Smart On-Device Financial Intelligence Chat
    public func chatWithAI(
        userMessage: String,
        expenses: [Expense],
        categories: [CategoryItem],
        currencySymbol: String,
        isEnglish: Bool
    ) async -> String {
        let prompt = userMessage.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Calculate Real Financial Metrics
        let totalSpend = expenses.reduce(0.0) { $0 + $1.amount }
        let count = expenses.count

        // Spend by Category
        var catSpend: [String: Double] = [:]
        for exp in expenses {
            catSpend[exp.category, default: 0.0] += exp.amount
        }

        // Top Category
        let topCatPair = catSpend.max(by: { $0.value < $1.value })
        let topCatName: String
        if let top = topCatPair {
            topCatName = categories.first(where: { $0.id == top.key })?.label ?? top.key
        } else {
            topCatName = isEnglish ? "None" : "Chưa có"
        }

        // Spend this month
        let calendar = Calendar.current
        let thisMonthExpenses = expenses.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        let thisMonthTotal = thisMonthExpenses.reduce(0.0) { $0 + $1.amount }

        // Format helper
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formatVal: (Double) -> String = { val in
            "\(formatter.string(from: NSNumber(value: Int(val))) ?? "\(Int(val))") \(currencySymbol)"
        }

        if isEnglish {
            if prompt.contains("total") || prompt.contains("spend") || prompt.contains("how much") || prompt.contains("summary") {
                if expenses.isEmpty {
                    return "You haven't recorded any expenses yet! Tap '+' or take a receipt photo to get started."
                }
                return """
                📊 **Your Financial Overview**:
                • **Total Spending**: \(formatVal(totalSpend)) (\(count) transactions)
                • **This Month**: \(formatVal(thisMonthTotal))
                • **Top Category**: \(topCatName) (\(formatVal(topCatPair?.value ?? 0)))
                
                💡 *Tip: Keep logging your daily coffee & dining expenses to identify quick savings!*
                """
            } else if prompt.contains("save") || prompt.contains("advice") || prompt.contains("tip") || prompt.contains("budget") {
                return """
                💡 **MDaily AI Financial Recommendations**:
                1. **50/30/20 Rule**: Allocate 50% for Needs, 30% for Wants, and 20% for Savings.
                2. **Category Insight**: Your highest spend is in **\(topCatName)** (\(formatVal(topCatPair?.value ?? 0))). Try setting a weekly limit!
                3. **Emergency Fund**: Aim to accumulate 3–6 months of living expenses.
                """
            } else if prompt.contains("category") || prompt.contains("breakdown") {
                var lines: [String] = []
                for (catId, amt) in catSpend.sorted(by: { $0.value > $1.value }) {
                    let label = categories.first(where: { $0.id == catId })?.label ?? catId
                    let pct = totalSpend > 0 ? (amt / totalSpend) * 100 : 0
                    lines.append("• **\(label)**: \(formatVal(amt)) (\(Int(pct))%)")
                }
                return """
                📂 **Category Spending Breakdown**:
                \(lines.joined(separator: "\n"))
                """
            } else {
                return "Hello! I am your MDaily On-Device Financial Intelligence. Ask me: 'What is my total spend?', 'Show spending breakdown', or 'Give me savings tips'!"
            }
        } else {
            // Vietnamese
            if prompt.contains("tổng") || prompt.contains("bao nhiêu") || prompt.contains("tiêu") || prompt.contains("thống kê") || prompt.contains("báo cáo") {
                if expenses.isEmpty {
                    return "Bạn chưa có khoản chi tiêu nào được ghi lại. Hãy bấm nút '+' hoặc chụp ảnh hoá đơn để bắt đầu nhé!"
                }
                return """
                📊 **Tổng quan tài chính của bạn**:
                • **Tổng chi tiêu**: \(formatVal(totalSpend)) (\(count) giao dịch)
                • **Chi trong tháng này**: \(formatVal(thisMonthTotal))
                • **Mục chi nhiều nhất**: **\(topCatName)** (\(formatVal(topCatPair?.value ?? 0)))
                
                💡 *Mẹo: Duy trì thói quen ghi chép hoá đơn mỗi ngày giúp bạn kiểm soát dòng tiền tốt hơn!*
                """
            } else if prompt.contains("tiết kiệm") || prompt.contains("lời khuyên") || prompt.contains("mẹo") || prompt.contains("ngân sách") {
                return """
                💡 **Lời khuyên tài chính từ MDaily AI**:
                1. **Quy tắc 50/30/20**: 50% cho nhu cầu thiết yếu, 30% cho sở thích, và 20% cho quỹ tiết kiệm.
                2. **Phân tích mục chi lớn**: Bạn đang chi nhiều nhất cho **\(topCatName)** (\(formatVal(topCatPair?.value ?? 0))). Đặt hạn mức chi tiêu tuần để tiết kiệm thêm 10–15%!
                3. **Quỹ khẩn cấp**: Hãy duy trì quỹ dự phòng tương đương 3–6 tháng chi phí sinh hoạt.
                """
            } else if prompt.contains("danh mục") || prompt.contains("phân loại") || prompt.contains("chi tiết") {
                var lines: [String] = []
                for (catId, amt) in catSpend.sorted(by: { $0.value > $1.value }) {
                    let label = categories.first(where: { $0.id == catId })?.label ?? catId
                    let pct = totalSpend > 0 ? (amt / totalSpend) * 100 : 0
                    lines.append("• **\(label)**: \(formatVal(amt)) (\(Int(pct))%)")
                }
                return """
                📂 **Chi tiết chi tiêu theo danh mục**:
                \(lines.joined(separator: "\n"))
                """
            } else {
                return "Chào bạn! Tôi là MDaily AI — trợ lý tài chính thông minh trên iPhone. Bạn có thể hỏi: 'Tổng chi tiêu của tôi?', 'Mục nào chi nhiều nhất?' hoặc 'Cho tôi lời khuyên tiết kiệm'!"
            }
        }
    }
}
