import Foundation
import CoreGraphics
import ImageIO
import Vision

#if canImport(FoundationModels)
import FoundationModels
#endif

struct ReceiptResult {
    let isReceipt: Bool
    let amount: Int
    let engine: String
}

@main
struct ReceiptAnalyzer {
    static func main() async {
        while let line = readLine(),
              let inputData = line.data(using: .utf8),
              let input = try? JSONSerialization.jsonObject(with: inputData) as? [String: Any],
              let imageBase64 = input["imageBase64"] as? String {
            let result = await analyze(imageBase64: imageBase64)
            let output: [String: Any] = [
                "isReceipt": result.isReceipt,
                "amount": result.amount,
                "engine": result.engine
            ]
            if let outputData = try? JSONSerialization.data(withJSONObject: output),
               let outputString = String(data: outputData, encoding: .utf8) {
                FileHandle.standardOutput.write(Data((outputString + "\n").utf8))
            }
        }
    }

    static func analyze(imageBase64: String) async -> ReceiptResult {
        guard let imageData = decodeImageData(imageBase64),
              let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return ReceiptResult(isReceipt: false, amount: 0, engine: "Vision unavailable")
        }

        let text = recognizeText(from: image)
        guard !text.isEmpty else {
            return ReceiptResult(isReceipt: false, amount: 0, engine: "Vision OCR")
        }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            if model.isAvailable {
                let result = await analyzeWithFoundationModel(text: text)
                if result.isReceipt {
                    return result
                }
            }
        }
        #endif

        let localResult = parseReceiptText(text)
        return ReceiptResult(isReceipt: localResult.isReceipt, amount: localResult.amount, engine: "Vision OCR")
    }

    static func decodeImageData(_ value: String) -> Data? {
        let cleanValue = value.contains(",") ? String(value.split(separator: ",", maxSplits: 1).last ?? "") : value
        return Data(base64Encoded: cleanValue, options: .ignoreUnknownCharacters)
    }

    static func recognizeText(from image: CGImage) -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["vi-VN", "en-US"]
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([request])
            return (request.results ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
        } catch {
            return ""
        }
    }

    static func parseReceiptText(_ text: String) -> (isReceipt: Bool, amount: Int) {
        let normalized = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let signals = [
            "hoa don", "invoice", "receipt", "bill",
            "tong tien", "tong cong", "thanh tien", "total", "subtotal", "grand total",
            "don gia", "so luong", "qty", "vat", "tax", "cashier", "payment", "thanh toan"
        ]
        let signalCount = signals.filter { normalized.contains($0) }.count
        let amount = extractTotalAmount(from: text) ?? extractAmount(from: text)
        let isReceipt = amount > 0 && (signalCount >= 2 || ["hoa don", "invoice", "receipt", "grand total"].contains { normalized.contains($0) })
        return (isReceipt, amount)
    }

    static func extractTotalAmount(from text: String) -> Int? {
        let totalMarkers = ["tong tien", "tong cong", "thanh tien", "grand total", "total"]
        for line in text.components(separatedBy: .newlines).reversed() {
            let normalizedLine = line.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            let amount = extractAmount(from: line)
            if totalMarkers.contains(where: { normalizedLine.contains($0) }), amount > 0 {
                return amount
            }
        }
        return nil
    }

    static func extractAmount(from text: String) -> Int {
        let pattern = #"\b(?:\d{1,3}(?:[.,\s]\d{3})+|\d{4,8})(?:\s*(?:k|đ|vnd|vnđ))?\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return 0 }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        let values = matches.compactMap { match -> Int? in
            guard let matchRange = Range(match.range, in: text) else { return nil }
            let value = String(text[matchRange])
            let digits = value.filter { $0.isNumber }
            guard let number = Int(digits), number >= 1000, number <= 500_000_000 else { return nil }
            return value.lowercased().contains("k") ? number * 1000 : number
        }
        return values.max() ?? 0
    }

    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    static func analyzeWithFoundationModel(text: String) async -> ReceiptResult {
        let session = LanguageModelSession(instructions: """
        Bạn là bộ nhận diện hóa đơn. Chỉ trả về JSON hợp lệ dạng {\"isReceipt\":true/false,\"amount\":số nguyên}.
        Chỉ isReceipt=true khi văn bản thực sự là hóa đơn hoặc biên lai và amount là tổng tiền cuối cùng.
        Nếu không phải hóa đơn, trả về isReceipt=false và amount=0.
        """)
        do {
            let response = try await session.respond(to: "Phân tích văn bản OCR sau:\n\n\(text)")
            let responseText = String(response.content)
            guard let start = responseText.firstIndex(of: "{"),
                  let end = responseText.lastIndex(of: "}"),
                  let data = String(responseText[start...end]).data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return ReceiptResult(isReceipt: false, amount: 0, engine: "Apple Intelligence")
            }
            let isReceipt = json["isReceipt"] as? Bool ?? false
            let amount = json["amount"] as? Int ?? Int(json["amount"] as? Double ?? 0)
            return ReceiptResult(isReceipt: isReceipt && amount > 0, amount: max(0, amount), engine: "Apple Intelligence")
        } catch {
            return ReceiptResult(isReceipt: false, amount: 0, engine: "Apple Intelligence unavailable")
        }
    }
    #endif
}
