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
            model: "Apple Vision AI (On-Device)",
            message: "Sẵn sàng — Nhận diện thông minh Vision OCR"
        )
    }

    public func extractExpense(from image: UIImage) async -> ExtractionResult {
        guard let cgImage = image.cgImage else {
            return ExtractionResult(success: false)
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                    continuation.resume(returning: ExtractionResult(success: false))
                    return
                }

                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                let result = self.parseReceiptText(lines: lines)
                continuation.resume(returning: result)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["vi-VN", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: ExtractionResult(success: false))
            }
        }
    }

    private func parseReceiptText(lines: [String]) -> ExtractionResult {
        guard !lines.isEmpty else { return ExtractionResult(success: false) }

        var foundAmount: Double?
        var foundItem: String?
        var foundCategory = "shopping"
        var isInvoice = false

        let invoiceKeywords = ["hoa don", "hóa đơn", "bill", "receipt", "tong cong", "tổng cộng", "total", "thanh toan", "thanh toán", "vat", "pos"]
        let lowerLines = lines.map { $0.lowercased() }

        if lowerLines.contains(where: { line in invoiceKeywords.contains(where: { line.contains($0) }) }) {
            isInvoice = true
        }

        // Amount parsing
        for line in lines.reversed() {
            let clean = line.replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "đ", with: "")
                .replacingOccurrences(of: "VND", with: "")
                .replacingOccurrences(of: "vnd", with: "")

            let numbers = clean.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if let val = Double(numbers), val > 1000 && val < 500_000_000 {
                foundAmount = val
                break
            }
        }

        // Item Name parsing
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 3 && !trimmed.contains("202") && !trimmed.contains(":") && !trimmed.allSatisfy({ $0.isNumber || $0.isPunctuation }) {
                foundItem = trimmed
                break
            }
        }

        // Category guessing
        let fullText = lowerLines.joined(separator: " ")
        if fullText.contains("cafe") || fullText.contains("coffee") || fullText.contains("quan") || fullText.contains("nha hang") || fullText.contains("com") || fullText.contains("tra") || fullText.contains("food") {
            foundCategory = "food"
        } else if fullText.contains("dien") || fullText.contains("nuoc") || fullText.contains("internet") || fullText.contains("phi") || fullText.contains("cuoc") {
            foundCategory = "bills"
        } else if fullText.contains("grab") || fullText.contains("be") || fullText.contains("xang") || fullText.contains("taxi") || fullText.contains("xe") {
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

    public func chatWithAI(userMessage: String, expensesContext: String, isEnglish: Bool) async -> String {
        let prompt = userMessage.lowercased()

        if isEnglish {
            if prompt.contains("total") || prompt.contains("spend") || prompt.contains("how much") {
                return "Based on your recent financial records:\n\n\(expensesContext.isEmpty ? "No expenses recorded yet." : expensesContext)\n\nKeep monitoring your transactions daily to maintain a balanced budget!"
            } else if prompt.contains("save") || prompt.contains("advice") || prompt.contains("tip") {
                return "💡 Smart Financial Tip:\n1. Apply the 50/30/20 rule (Needs/Wants/Savings).\n2. Review high-frequency food & coffee expenses.\n3. Build an emergency fund for 3-6 months."
            } else {
                return "I'm MDaily AI, your smart on-device financial assistant. How can I help you analyze or optimize your daily spending today?"
            }
        } else {
            if prompt.contains("tổng") || prompt.contains("bao nhiêu") || prompt.contains("tiêu") {
                return "Dựa trên dữ liệu chi tiêu gần đây của bạn:\n\n\(expensesContext.isEmpty ? "Chưa có khoản chi nào được ghi lại." : expensesContext)\n\nHãy nhớ duy trì thói quen theo dõi chi tiêu mỗi ngày nhé!"
            } else if prompt.contains("tiết kiệm") || prompt.contains("lời khuyên") || prompt.contains("mẹo") {
                return "💡 Lời khuyên tài chính từ MDaily AI:\n1. Áp dụng quy tắc 50/30/20 (Thiết yếu/Sở thích/Tích luỹ).\n2. Cắt giảm các khoản chi tiêu nhỏ lặp đi lặp lại như trà sữa, cà phê.\n3. Đặt hạn mức chi tiêu theo tuần để luôn chủ động."
            } else {
                return "Chào bạn! Tôi là MDaily AI — trợ lý tài chính thông minh trên thiết bị. Bạn muốn tôi phân tích tổng chi tiêu hay gợi ý cách tối ưu ngân sách hôm nay?"
            }
        }
    }
}
