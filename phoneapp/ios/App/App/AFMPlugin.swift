import Foundation
import Capacitor
import CoreImage
import Vision
import UIKit
import UniformTypeIdentifiers

#if canImport(FoundationModels)
import FoundationModels
#endif

@objc(AFMPlugin)
public class AFMPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "AFMPlugin"
    public let jsName = "AFMPlugin"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isAFMAvailable", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateText", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "extractFromImage", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "chooseSyncFile", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "ensureSyncFile", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "readSyncFile", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "writeSyncFile", returnType: CAPPluginReturnPromise)
    ]

    private var pendingFileCall: CAPPluginCall?
    private let syncBookmarkKey = "mdaily.sync-file-bookmark"

    // MARK: - iCloud Drive file sync
    @objc func chooseSyncFile(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.pendingFileCall = call
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json], asCopy: false)
            picker.allowsMultipleSelection = false
            picker.delegate = self
            self.bridge?.viewController?.present(picker, animated: true)
        }
    }

    @objc func ensureSyncFile(_ call: CAPPluginCall) {
        if withSyncFileURL({ $0.path }) != nil {
            call.resolve(["configured": true])
            return
        }
        DispatchQueue.main.async {
            self.pendingFileCall = call
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("MDaily.sync.json")
            let initial = "{\"version\":1,\"updatedAt\":\(Int(Date().timeIntervalSince1970 * 1000)),\"expenses\":[],\"categories\":[],\"deletedExpenseIds\":[],\"deletedCategoryValues\":[]}"
            try? initial.data(using: .utf8)?.write(to: tempURL)
            let picker = UIDocumentPickerViewController(forExporting: [tempURL], asCopy: true)
            picker.delegate = self
            self.bridge?.viewController?.present(picker, animated: true)
        }
    }

    @objc func readSyncFile(_ call: CAPPluginCall) {
        var name = ""
        let data = self.withSyncFileURL({ url in
            name = url.lastPathComponent
            return try? Data(contentsOf: url)
        })
        guard let fileData = data else {
            call.resolve(["configured": false])
            return
        }
        call.resolve(["configured": true, "name": name, "contents": String(data: fileData, encoding: .utf8) ?? ""])
    }

    @objc func writeSyncFile(_ call: CAPPluginCall) {
        guard let contents = call.getString("contents"),
              let data = contents.data(using: .utf8) else {
            call.reject("Sync file contents are required")
            return
        }
        guard let result = withSyncFileURL({
            do {
                try data.write(to: $0, options: .atomic)
                return true
            } catch {
                return false
            }
        }), result else {
            call.resolve(["success": false, "configured": false])
            return
        }
        call.resolve(["success": true, "configured": true])
    }

    private func withSyncFileURL<T>(_ body: (URL) -> T?) -> T? {
        guard let bookmark = UserDefaults.standard.data(forKey: syncBookmarkKey) else { return nil }
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale),
              url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        
        if isStale {
            if let freshBookmark = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                UserDefaults.standard.set(freshBookmark, forKey: syncBookmarkKey)
            }
        }
        
        if let values = try? url.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey]),
           values.isUbiquitousItem == true,
           values.ubiquitousItemDownloadingStatus != .current {
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        }
        
        return body(url)
    }

    // MARK: - isAFMAvailable
    @objc func isAFMAvailable(_ call: CAPPluginCall) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default

            switch model.availability {
            case .available:
                call.resolve([
                    "available": true,
                    "model": "Apple Foundation Model (On-Device)",
                    "canExtractImage": true
                ])
                return
            case .unavailable(let reason):
                var reasonText = "Không khả dụng"
                switch reason {
                case .deviceNotEligible:
                    reasonText = "Thiết bị không hỗ trợ MDaily AI"
                case .appleIntelligenceNotEnabled:
                    reasonText = "MDaily AI chưa được bật trong Cài đặt"
                case .modelNotReady:
                    reasonText = "Model đang tải xuống, vui lòng thử lại sau"
                @unknown default:
                    reasonText = "Không khả dụng (lý do không xác định)"
                }
                call.resolve([
                    "available": false,
                    "model": reasonText,
                    "canExtractImage": false
                ])
                return
            @unknown default:
                break
            }
        }
        #endif

        call.resolve([
            "available": false,
            "model": "Cần iOS 26+ và thiết bị hỗ trợ MDaily AI",
            "canExtractImage": false
        ])
    }

    // MARK: - generateText
    @objc func generateText(_ call: CAPPluginCall) {
        guard let prompt = call.getString("prompt") else {
            call.reject("Prompt is required")
            return
        }
        let systemPrompt = call.getString("systemPrompt") ?? ""
        let context = call.getString("context") ?? ""

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.isAvailable else {
                let reply = self.localFallback(prompt: prompt, context: context)
                call.resolve(["text": reply, "engine": "Local Fallback"])
                return
            }

            Task {
                do {
                    var instructions = systemPrompt
                    if !context.isEmpty {
                        instructions += "\n\nDữ liệu chi tiêu của người dùng:\n\(context)"
                    }

                    let session = LanguageModelSession(instructions: instructions)
                    let response = try await session.respond(to: prompt)
                    let text = String(response.content)

                    await MainActor.run {
                        call.resolve([
                            "text": text,
                            "engine": "Apple Foundation Model (On-Device)"
                        ])
                    }
                } catch {
                    let reply = self.localFallback(prompt: prompt, context: context)
                    await MainActor.run {
                        call.resolve([
                            "text": reply,
                            "engine": "Local Fallback (AFM error: \(error.localizedDescription))"
                        ])
                    }
                }
            }
            return
        }
        #endif

        DispatchQueue.global(qos: .userInitiated).async {
            let reply = self.localFallback(prompt: prompt, context: context)
            DispatchQueue.main.async {
                call.resolve(["text": reply, "engine": "Local Fallback"])
            }
        }
    }

    // MARK: - extractFromImage (Vision OCR + AFM analysis)
    @objc func extractFromImage(_ call: CAPPluginCall) {
        guard let base64String = call.getString("imageBase64") else {
            call.reject("imageBase64 is required")
            return
        }

        // Strip data URL prefix if present
        let cleanBase64 = base64String.contains(",")
            ? String(base64String.split(separator: ",").last ?? "")
            : base64String

        guard let imageData = Data(base64Encoded: cleanBase64, options: .ignoreUnknownCharacters),
              let ciImage = CIImage(data: imageData) else {
            call.resolve([
                "success": false,
                "error": "Không thể đọc ảnh. Vui lòng thử ảnh khác."
            ])
            return
        }

        // Step 1: Use Vision framework to extract text (OCR)
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["vi-VN", "en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    call.resolve([
                        "success": false,
                        "error": "Lỗi Vision OCR: \(error.localizedDescription)"
                    ])
                }
                return
            }

            let observations = request.results ?? []
            let extractedText = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            if extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // No text found — likely a product photo, not an invoice
                self?.analyzeWithAFM(
                    ocrText: nil,
                    isLikelyInvoice: false,
                    call: call
                )
            } else {
                // Text found — likely an invoice/receipt
                self?.analyzeWithAFM(
                    ocrText: extractedText,
                    isLikelyInvoice: true,
                    call: call
                )
            }
        }
    }

    // Step 2: Use AFM to analyze OCR text or describe the image
    private func analyzeWithAFM(ocrText: String?, isLikelyInvoice: Bool, call: CAPPluginCall) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            if model.isAvailable {
                Task {
                    do {
                        let session = LanguageModelSession(instructions: """
                        Bạn là trợ lý trích xuất thông tin chi tiêu. Phân tích dữ liệu và trả lời theo đúng format JSON.

                        QUY TẮC:
                        1. Nếu dữ liệu là văn bản HOÁ ĐƠN: Trích xuất tên cửa hàng/dịch vụ, tổng số tiền, mô tả.
                        2. Nếu không có văn bản (ảnh đồ vật): CHỈ trả tên đồ vật, amount = 0.
                        3. Phân loại: food (ăn uống), shopping (mua sắm), transport (di chuyển), bills (hoá đơn), other (khác).

                        Trả lời CHÍNH XÁC theo format (không thêm text khác):
                        {"itemName": "tên", "amount": số_hoặc_0, "category": "loại", "isInvoice": true/false, "description": "mô tả"}
                        """)

                        let prompt: String
                        if let text = ocrText, !text.isEmpty {
                            prompt = "Đây là văn bản OCR từ hoá đơn/receipt. Trích xuất thông tin chi tiêu:\n\n\(text)"
                        } else {
                            prompt = "Không có văn bản OCR. Đây là ảnh đồ vật/món hàng. Hãy mô tả đồ vật chung chung và trả JSON với amount = 0."
                        }

                        let response = try await session.respond(to: prompt)
                        let responseText = String(response.content).trimmingCharacters(in: .whitespacesAndNewlines)

                        // Parse JSON from response
                        if let jsonStart = responseText.firstIndex(of: "{"),
                           let jsonEnd = responseText.lastIndex(of: "}") {
                            let jsonStr = String(responseText[jsonStart...jsonEnd])
                            if let jsonData = jsonStr.data(using: .utf8),
                               let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                let result: [String: Any] = [
                                    "success": true,
                                    "itemName": parsed["itemName"] as? String ?? "",
                                    "amount": parsed["amount"] as? Double ?? 0,
                                    "category": parsed["category"] as? String ?? "other",
                                    "isInvoice": parsed["isInvoice"] as? Bool ?? isLikelyInvoice,
                                    "description": parsed["description"] as? String ?? "",
                                    "engine": "MDaily AI (Vision + AFM)"
                                ]
                                await MainActor.run { call.resolve(result) }
                                return
                            }
                        }

                        // Fallback: use raw response
                        await MainActor.run {
                            call.resolve([
                                "success": true,
                                "itemName": responseText,
                                "amount": 0,
                                "category": "other",
                                "isInvoice": false,
                                "description": responseText,
                                "engine": "MDaily AI (AFM)"
                            ])
                        }
                        return
                    } catch {
                        // Fall through to local analysis
                    }
                }
                return
            }
        }
        #endif

        // Fallback: local analysis from OCR text only
        DispatchQueue.main.async {
            if let text = ocrText, !text.isEmpty {
                let amount = self.extractAmountFromOCR(text)
                let itemName = self.extractItemNameFromOCR(text)
                call.resolve([
                    "success": true,
                    "itemName": itemName,
                    "amount": amount,
                    "category": self.guessCategory(from: text),
                    "isInvoice": true,
                    "description": String(text.prefix(100)),
                    "engine": "Vision OCR (Local)"
                ])
            } else {
                call.resolve([
                    "success": true,
                    "itemName": "Đồ vật",
                    "amount": 0,
                    "category": "shopping",
                    "isInvoice": false,
                    "description": "Ảnh đồ vật (không có văn bản)",
                    "engine": "Local"
                ])
            }
        }
    }

    // MARK: - OCR Helpers
    private func extractAmountFromOCR(_ text: String) -> Double {
        // Match patterns like: 50.000, 50,000, 1.234.567, TỔNG: 50000
        let patterns = [
            "(?:tổng|total|thanh toán|thành tiền|amount)[:\\s]*([0-9.,]+)",
            "([0-9]{1,3}(?:[.,][0-9]{3})+)\\s*(?:đ|vnd|vnđ|d)",
            "([0-9]{4,})\\s*(?:đ|vnd|vnđ|d)"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, range: range),
                   let numRange = Range(match.range(at: 1), in: text) {
                    let numStr = String(text[numRange])
                        .replacingOccurrences(of: ".", with: "")
                        .replacingOccurrences(of: ",", with: "")
                    if let val = Double(numStr), val > 0 { return val }
                }
            }
        }
        return 0
    }

    private func extractItemNameFromOCR(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        // Return first non-numeric line as item/store name
        for line in lines {
            let stripped = line.replacingOccurrences(of: "[0-9.,:/\\-]+", with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces)
            if stripped.count >= 3 { return stripped }
        }
        return lines.first ?? "Hoá đơn"
    }

    private func guessCategory(from text: String) -> String {
        let t = text.lowercased()
        if t.contains("cafe") || t.contains("cà phê") || t.contains("coffee") || t.contains("trà") || t.contains("bún") || t.contains("phở") || t.contains("cơm") || t.contains("bánh") || t.contains("food") || t.contains("nhà hàng") || t.contains("quán") {
            return "food"
        }
        if t.contains("grab") || t.contains("taxi") || t.contains("xăng") || t.contains("gửi xe") || t.contains("parking") {
            return "transport"
        }
        if t.contains("điện") || t.contains("nước") || t.contains("internet") || t.contains("wifi") || t.contains("thuê") {
            return "bills"
        }
        return "shopping"
    }

    // MARK: - Local Fallback
    private func localFallback(prompt: String, context: String) -> String {
        let p = prompt.lowercased()

        if p.contains("tổng") || p.contains("bao nhiêu") || p.contains("tổng cộng") {
            if context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Mày chưa lưu khoản chi tiêu nào cả! Giữ phong độ quản lý tài chính nhé."
            }
            return "Dữ liệu chi tiêu của mày:\n\n\(context)\n\nHãy chú ý kiểm tra lại các khoản chi lớn để điều chỉnh ngân sách nhé!"
        }

        if p.contains("khuyên") || p.contains("tiết kiệm") || p.contains("lời khuyên") {
            return "Lời khuyên: Đặt hạn mức chi tiêu mỗi ngày, bớt vung tay săn sale và ghi chép đầy đủ vào MDaily ngay khi vừa tiêu tiền."
        }

        if p.contains("ăn") || p.contains("uống") || p.contains("trà sữa") {
            return "Chi cho ăn uống là thiết yếu, nhưng nhớ đừng 'vung tay quá trán' đầu tháng để rồi cuối tháng ăn mì gói nhé!"
        }

        if p.contains("chào") || p.contains("hi") || p.contains("hello") {
            return "Chào mày! Tao là MDaily AI. Hôm nay mày lỡ vung tiền vào cái gì rồi? Khai ra mau!"
        }

        return "MDaily AI đã tiếp nhận yêu cầu: \"\(prompt)\". Dữ liệu tài chính được bảo mật 100% trên thiết bị."
    }
}

extension AFMPlugin: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first, let call = pendingFileCall else { return }
        pendingFileCall = nil
        
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmark, forKey: syncBookmarkKey)
            call.resolve(["configured": true, "name": url.lastPathComponent])
        } catch {
            call.reject("Could not save iCloud file access: \(error.localizedDescription)")
        }
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        pendingFileCall?.reject("File selection cancelled")
        pendingFileCall = nil
    }
}
